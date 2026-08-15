import Foundation
@_implementationOnly import idevice

final class JITSession {

    struct Tunnel {
        var adapter: OpaquePointer?
        var handshake: OpaquePointer?
        func free() {
            if let handshake { rsd_handshake_free(handshake) }
            if let adapter { adapter_free(adapter) }
        }
    }

    private struct DebugSession {
        var remoteServer: OpaquePointer?
        var debugProxy: OpaquePointer?
        func free() {
            if let debugProxy { debug_proxy_free(debugProxy) }
            if let remoteServer { remote_server_free(remoteServer) }
        }
    }

    private let pairingFilePath: String
    private let configuration: StikJIT.Configuration

    init(pairingFilePath: String, configuration: StikJIT.Configuration) {
        self.pairingFilePath = pairingFilePath
        self.configuration = configuration
    }

    func enableJIT(targetPID: Int32,
                   script: StikJIT.Script,
                   forceScript: Bool,
                   txmPresence: TXMPresence,
                   progress: @escaping (String) -> Void) throws {
        let tunnel = try makeTunnel()
        defer { tunnel.free() }

        let session = try connectDebugSession(over: tunnel)
        defer { session.free() }

        guard let debugProxy = session.debugProxy else { throw StikJITError.debugProxyUnavailable }

        debug_proxy_send_ack(debugProxy)
        _ = try? sendCommand("QStartNoAckMode", over: debugProxy)
        debug_proxy_set_ack_mode(debugProxy, 0)

        switch (forceScript, txmPresence) {
        case (true, _), (false, .present):
            try ScriptRunner(targetPID: targetPID, debugProxy: debugProxy, script: script, progress: progress).run()
        case (false, .absent):
            try attachWithoutScript(targetPID: targetPID, debugProxy: debugProxy, progress: progress)
        case (false, .unknown):
            throw StikJITError.txmDetectionUnavailable
        }
    }

    private func attachWithoutScript(targetPID: Int32, debugProxy: OpaquePointer, progress: (String) -> Void) throws {
        progress("Attaching to pid \(targetPID). TXM is not present, so the attach alone enables JIT and the script is skipped.")
        _ = try sendCommand("vAttach;\(String(targetPID, radix: 16))", over: debugProxy)
        _ = try? sendCommand("D", over: debugProxy)
        progress("JIT enabled (debugger attached and detached).")
    }

    private func openPairingFile() throws -> OpaquePointer {
        guard !pairingFilePath.isEmpty, FileManager.default.fileExists(atPath: pairingFilePath) else {
            throw StikJITError.pairingFile("not found at \(pairingFilePath)")
        }
        var handle: OpaquePointer?
        try IdeviceFFI.check("failed to read pairing file") {
            pairingFilePath.withCString { rp_pairing_file_read($0, &handle) }
        }
        guard let handle else { throw StikJITError.pairingFile("unreadable at \(pairingFilePath)") }
        return handle
    }

    private func makeTunnel() throws -> Tunnel {
        let pairing = try openPairingFile()
        defer { rp_pairing_file_free(pairing) }

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = configuration.rsdPort.bigEndian
        _ = configuration.deviceAddress.withCString { inet_pton(AF_INET, $0, &address.sin_addr) }

        var tunnel = Tunnel()
        try IdeviceFFI.check("failed to create RSD tunnel") {
            "StikJIT".withCString { hostname in
                withUnsafePointer(to: &address) { pointer in
                    pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                        tunnel_create_rppairing(
                            sa, socklen_t(MemoryLayout<sockaddr_in>.stride),
                            hostname, pairing, nil, nil,
                            &tunnel.adapter, &tunnel.handshake)
                    }
                }
            }
        }
        return tunnel
    }

    private func connectDebugSession(over tunnel: Tunnel) throws -> DebugSession {
        var session = DebugSession()
        try IdeviceFFI.check("failed to connect remote server") {
            remote_server_connect_rsd(tunnel.adapter, tunnel.handshake, &session.remoteServer)
        }
        try IdeviceFFI.check("failed to connect debug proxy") {
            debug_proxy_connect_rsd(tunnel.adapter, tunnel.handshake, &session.debugProxy)
        }
        return session
    }

    @discardableResult
    private func sendCommand(_ command: String, over debugProxy: OpaquePointer) throws -> String? {
        guard let handle = command.withCString({ debugserver_command_new($0, nil, 0) }) else { return nil }
        defer { debugserver_command_free(handle) }
        var response: UnsafeMutablePointer<CChar>?
        try IdeviceFFI.check("debugserver command failed") {
            debug_proxy_send_command(debugProxy, handle, &response)
        }
        guard let response else { return nil }
        defer { idevice_string_free(response) }
        return String(cString: response)
    }
}
