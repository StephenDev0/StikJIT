import Foundation

enum SynchronousDDIDownloader {
    static func download(to paths: DDIPaths,
                         progress: @escaping (Double, String) -> Void) throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 600
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }

        let items = DDIDownloadCatalog.items(for: paths)
        let total = Double(items.count)
        for (index, item) in items.enumerated() {
            progress(Double(index) / total, "Downloading \(item.name)...")
            try download(item, session: session)
            progress(Double(index + 1) / total, "\(item.name) ready")
        }
    }

    private static func download(_ item: DDIDownloadItem, session: URLSession) throws {
        let semaphore = DispatchSemaphore(value: 0)
        let result = DownloadResult()
        let task = session.downloadTask(with: item.url) { temporaryURL, response, error in
            defer { semaphore.signal() }
            do {
                if let error { throw error }
                guard let temporaryURL, let httpResponse = response as? HTTPURLResponse else {
                    throw StikJITError.ddiDownload("invalid response for \(item.url.absoluteString)")
                }
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw StikJITError.ddiDownload("HTTP \(httpResponse.statusCode) for \(item.url.absoluteString)")
                }

                let destinationURL = URL(fileURLWithPath: item.destinationPath)
                let fileManager = FileManager.default
                try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: temporaryURL, to: destinationURL)
            } catch {
                result.error = error
            }
        }
        task.resume()
        semaphore.wait()
        if let error = result.error {
            if let stikJITError = error as? StikJITError { throw stikJITError }
            throw StikJITError.ddiDownload(error.localizedDescription)
        }
    }
}

private final class DownloadResult: @unchecked Sendable {
    var error: Error?
}
