import Foundation
import Network

enum EndpointProbe {
    private static let queue = DispatchQueue(label: "com.stik.StikJIT.endpoint-probe")

    static func failureReason(address: String, port: UInt16, timeout: TimeInterval) -> String? {
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let endpointPort = NWEndpoint.Port(rawValue: port) else {
            return "The configured device endpoint is invalid."
        }

        let state = ProbeState()
        let semaphore = DispatchSemaphore(value: 0)
        let connection = NWConnection(host: NWEndpoint.Host(address), port: endpointPort, using: .tcp)
        connection.stateUpdateHandler = { connectionState in
            switch connectionState {
            case .ready:
                if state.finish(reason: nil) { semaphore.signal() }
            case .failed(let error):
                if state.finish(reason: error.localizedDescription) { semaphore.signal() }
            default:
                break
            }
        }
        connection.start(queue: queue)

        if semaphore.wait(timeout: .now() + max(timeout, 0.1)) == .timedOut {
            _ = state.finish(reason: "Timed out connecting to \(address):\(port).")
        }
        connection.stateUpdateHandler = nil
        connection.cancel()
        return state.reason
    }
}

private final class ProbeState: @unchecked Sendable {
    private let lock = NSLock()
    private var isFinished = false
    private var storedReason: String?

    var reason: String? {
        lock.lock()
        defer { lock.unlock() }
        return storedReason
    }

    func finish(reason: String?) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else { return false }
        isFinished = true
        storedReason = reason
        return true
    }
}
