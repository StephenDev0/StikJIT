import Foundation

public enum StikJITError: Error, LocalizedError {

    case pairingFile(String)

    case scriptUnavailable

    case debugProxyUnavailable

    case device(code: Int32, subCode: Int32, message: String)

    case ddiDownload(String)

    case ddiFilesMissing(String)

    case ddiNotMounted

    case deviceNotReady(String)

    case txmDetectionUnavailable

    case customScript(String)

    case scriptExecution(String)

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
        case .ddiNotMounted:
            return "The Developer Disk Image was not mounted after the mount operation completed."
        case .deviceNotReady(let detail):
            return "The device is not ready for JIT: \(detail)"
        case .txmDetectionUnavailable:
            return "Whether TXM is present could not be determined. Enable forced script execution to bypass this check."
        case .customScript(let detail):
            return "Custom JIT script error: \(detail)."
        case .scriptExecution(let detail):
            return "JIT script failed: \(detail)."
        }
    }
}
