import Foundation

public struct DDIPaths: Sendable {

    public var imagePath: String

    public var trustcachePath: String

    public var manifestPath: String

    public init(imagePath: String, trustcachePath: String, manifestPath: String) {
        self.imagePath = imagePath
        self.trustcachePath = trustcachePath
        self.manifestPath = manifestPath
    }

    public static func `default`(in directory: URL) -> DDIPaths {
        DDIPaths(
            imagePath: directory.appendingPathComponent("DDI/Image.dmg").path,
            trustcachePath: directory.appendingPathComponent("DDI/Image.dmg.trustcache").path,
            manifestPath: directory.appendingPathComponent("DDI/BuildManifest.plist").path)
    }

    var allFilesExist: Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: imagePath)
            && fileManager.fileExists(atPath: trustcachePath)
            && fileManager.fileExists(atPath: manifestPath)
    }
}

@available(iOS 17.4, *)
public actor DeveloperDiskImageService {

    public static let shared = DeveloperDiskImageService()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private struct DownloadItem {
        let name: String
        let destinationPath: String
        let urlString: String
    }

    private static let baseURL = "https://github.com/doronz88/DeveloperDiskImage/raw/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized"

    public func downloadIfNeeded(to paths: DDIPaths, progress: @escaping (Double, String) -> Void = { _, _ in }) async throws {
        guard !paths.allFilesExist else { return }
        try await download(to: paths, progress: progress)
    }

    public func download(to paths: DDIPaths, progress: @escaping (Double, String) -> Void = { _, _ in }) async throws {
        let items = [
            DownloadItem(name: "BuildManifest.plist", destinationPath: paths.manifestPath, urlString: "\(Self.baseURL)/BuildManifest.plist"),
            DownloadItem(name: "Image.dmg", destinationPath: paths.imagePath, urlString: "\(Self.baseURL)/Image.dmg"),
            DownloadItem(name: "Image.dmg.trustcache", destinationPath: paths.trustcachePath, urlString: "\(Self.baseURL)/Image.dmg.trustcache"),
        ]

        let total = Double(items.count)
        for (index, item) in items.enumerated() {
            progress(Double(index) / total, "Downloading \(item.name)...")
            try await downloadFile(from: item.urlString, to: URL(fileURLWithPath: item.destinationPath))
            progress(Double(index + 1) / total, "\(item.name) ready")
        }
    }

    private func downloadFile(from urlString: String, to destinationURL: URL) async throws {
        guard let url = URL(string: urlString), url.scheme?.lowercased() == "https" else {
            throw StikJITError.ddiDownload("invalid URL \(urlString)")
        }

        let (temporaryURL, response) = try await session.download(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StikJITError.ddiDownload("invalid response for \(urlString)")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw StikJITError.ddiDownload("HTTP \(httpResponse.statusCode) for \(urlString)")
        }

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
    }
}
