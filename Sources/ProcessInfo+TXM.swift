import Foundation

extension ProcessInfo {
    var hasTXM: Bool {
        let hardware = Self.hardwareIdentifier()

        if Self.isIOS27OrNewer {
            return hardware != "iPad8,11" && hardware != "iPad8,12"
        }

        if Self.isIOS26OrNewer {
            return Self.hasTXMSupport(hardwareIdentifier: hardware)
        }

        return false
    }

    private static func hasTXMSupport(hardwareIdentifier: String) -> Bool {
        let firstTXM = 14.2
        let iPadTXM = 14.5
        guard let version = deviceVersion(from: hardwareIdentifier) else {
            return false
        }
        if hardwareIdentifier.hasPrefix("iPad") {
            return version >= iPadTXM
        }
        return version >= firstTXM
    }

    private static func deviceVersion(from identifier: String) -> Double? {
        func version(forPrefix prefix: String) -> Double? {
            guard identifier.hasPrefix(prefix) else { return nil }
            let parts = identifier.dropFirst(prefix.count).split(separator: ",")
            guard parts.count == 2, let major = Int(parts[0]), let minor = Int(parts[1]) else { return nil }
            return Double("\(major).\(minor)")
        }
        return version(forPrefix: "iPhone") ?? version(forPrefix: "iPad")
    }

    private static func hardwareIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        guard size > 0 else { return "" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &buffer, &size, nil, 0)
        return String(cString: buffer)
    }

    private static var isIOS26OrNewer: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    private static var isIOS27OrNewer: Bool {
        if #available(iOS 27.0, *) { return true }
        return false
    }
}
