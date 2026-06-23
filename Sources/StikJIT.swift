import Foundation

public enum StikJIT {

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
                                 progress: @escaping (String) -> Void = { _ in }) throws {
        let session = JITSession(pairingFilePath: pairingFile.path, configuration: configuration)
        try session.enableJIT(targetPID: targetPID, progress: progress)
    }
}
