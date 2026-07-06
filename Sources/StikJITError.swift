import Foundation

public enum StikJITError: Error, LocalizedError {

    case pairingFile(String)

    case scriptUnavailable

    case debugProxyUnavailable

    case device(code: Int32, subCode: Int32, message: String)

    case ddiDownload(String)

    case ddiFilesMissing(String)

    public var errorDescription: String? {
        switch self {
        case .pairingFile(let detail):
            return "Pairing file error: \(detail)."
        case .scriptUnavailable:
            return "The bundled JIT script could not be loaded from the StikJIT framework."
        case .debugProxyUnavailable:
            return "Failed to establish a debugserver connection to the target process."
        case .device(let code, let subCode, let message):
            return "\(message) (idevice code \(code)/\(subCode))."
        case .ddiDownload(let detail):
            return "Failed to download Developer Disk Image: \(detail)."
        case .ddiFilesMissing(let detail):
            return "Developer Disk Image files missing: \(detail)."
        }
    }
}
