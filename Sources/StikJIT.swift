import Foundation

public enum StikJIT {

    public enum Script: Sendable {

        case universal

        case legacy

        var resourceName: String {
            switch self {
            case .universal: return "universal"
            case .legacy: return "legacy"
            }
        }
    }

    public struct Configuration: Sendable {

        public var deviceAddress: String

        public var rsdPort: UInt16

        public init(deviceAddress: String = "10.7.0.1", rsdPort: UInt16 = 49152) {
            self.deviceAddress = deviceAddress
            self.rsdPort = rsdPort
        }

        public static let `default` = Configuration()
    }

    public static func enableJIT(targetPID: Int32,
                                 pairingFile: URL,
                                 configuration: Configuration = .default,
                                 script: Script = .universal,
                                 progress: @escaping (String) -> Void = { _ in }) throws {
        let session = JITSession(pairingFilePath: pairingFile.path, configuration: configuration)
        try session.enableJIT(targetPID: targetPID, script: script, progress: progress)
    }

    public static func isDDIMounted(pairingFile: URL,
                                    configuration: Configuration = .default) throws -> Bool {
        try DDISession(pairingFilePath: pairingFile.path, configuration: configuration).isMounted()
    }

    @available(iOS 17.4, *)
    public static func downloadDDIIfNeeded(to paths: DDIPaths,
                                           progress: @escaping (Double, String) -> Void = { _, _ in }) async throws {
        try await DeveloperDiskImageService.shared.downloadIfNeeded(to: paths, progress: progress)
    }

    public static func mountDDI(pairingFile: URL,
                                configuration: Configuration = .default,
                                paths: DDIPaths,
                                progress: @escaping (Double) -> Void = { _ in }) throws {
        let session = DDISession(pairingFilePath: pairingFile.path, configuration: configuration)
        try session.mountDDI(imagePath: paths.imagePath,
                              trustcachePath: paths.trustcachePath,
                              manifestPath: paths.manifestPath,
                              progress: progress)
    }
}
