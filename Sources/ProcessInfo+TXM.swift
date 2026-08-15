import Foundation
@_implementationOnly import StikJITIOKit

enum TXMPresence {
    case present
    case absent
    case unknown

    init(isPresent: Bool?) {
        guard let isPresent else {
            self = .unknown
            return
        }
        self = isPresent ? .present : .absent
    }

    var isPresent: Bool? {
        switch self {
        case .present: return true
        case .absent: return false
        case .unknown: return nil
        }
    }
}

extension ProcessInfo {
    var txmPresence: TXMPresence {
        let memoryMap = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/chosen/memory-map")
        guard memoryMap != 0 else { return .unknown }

        let keysCF = IORegistryEntryCreateCFProperty(
            memoryMap,
            kIORegistryEntryPropertyKeysKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue()
        IOObjectRelease(memoryMap)
        guard let keys = keysCF as? [String] else { return .unknown }

        return keys.contains("TXM") ? .present : .absent
    }
}
