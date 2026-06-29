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
}
