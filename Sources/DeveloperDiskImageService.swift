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

    var allFilesUsable: Bool {
        let fileManager = FileManager.default
        return allPaths.allSatisfy { path in
            guard fileManager.isReadableFile(atPath: path),
                  let attributes = try? fileManager.attributesOfItem(atPath: path),
                  attributes[.type] as? FileAttributeType == .typeRegular,
                  let size = attributes[.size] as? NSNumber else {
                return false
            }
            return size.int64Value > 0
        }
    }

    var allPaths: [String] {
        [imagePath, trustcachePath, manifestPath]
    }

    func removeCachedFiles() throws {
        let fileManager = FileManager.default
        for path in Set(allPaths) where fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
    }
}

struct DDIDownloadItem {
    let name: String
    let destinationPath: String
    let url: URL
}

enum DDIDownloadCatalog {
    private static let baseURL = URL(string: "https://github.com/doronz88/DeveloperDiskImage/raw/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized")!

    static func items(for paths: DDIPaths) -> [DDIDownloadItem] {
        [
            DDIDownloadItem(name: "BuildManifest.plist", destinationPath: paths.manifestPath, url: baseURL.appendingPathComponent("BuildManifest.plist")),
            DDIDownloadItem(name: "Image.dmg", destinationPath: paths.imagePath, url: baseURL.appendingPathComponent("Image.dmg")),
            DDIDownloadItem(name: "Image.dmg.trustcache", destinationPath: paths.trustcachePath, url: baseURL.appendingPathComponent("Image.dmg.trustcache")),
        ]
    }
}

@available(iOS 17.4, *)
public actor DeveloperDiskImageService {

    private static let sharedInstance = DeveloperDiskImageService()

    public static var shared: DeveloperDiskImageService { sharedInstance }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func downloadIfNeeded(to paths: DDIPaths, progress: @escaping (Double, String) -> Void = { _, _ in }) async throws {
        guard !paths.allFilesUsable else { return }
        try await download(to: paths, progress: progress)
    }

    public func download(to paths: DDIPaths, progress: @escaping (Double, String) -> Void = { _, _ in }) async throws {
        let items = DDIDownloadCatalog.items(for: paths)

        let total = Double(items.count)
        for (index, item) in items.enumerated() {
            progress(Double(index) / total, "Downloading \(item.name)...")
            try await downloadFile(from: item.url, to: URL(fileURLWithPath: item.destinationPath))
            progress(Double(index + 1) / total, "\(item.name) ready")
        }
    }

    private func downloadFile(from url: URL, to destinationURL: URL) async throws {
        let (temporaryURL, response) = try await session.download(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StikJITError.ddiDownload("invalid response for \(url.absoluteString)")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw StikJITError.ddiDownload("HTTP \(httpResponse.statusCode) for \(url.absoluteString)")
        }

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
    }
}
