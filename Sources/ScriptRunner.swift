import Foundation
import JavaScriptCore
@_implementationOnly import idevice

final class ScriptRunner {

    private static let jitPageSize: UInt64 = 16384

    private let targetPID: Int32
    private let debugProxy: OpaquePointer
    private let progress: (String) -> Void
    private var context: JSContext?

    init(targetPID: Int32, debugProxy: OpaquePointer, progress: @escaping (String) -> Void) {
        self.targetPID = targetPID
        self.debugProxy = debugProxy
        self.progress = progress
    }

    func run() throws {
        let source = try BundledScript.universalJS()

        guard let context = JSContext() else { throw StikJITError.scriptUnavailable }
        self.context = context

        context.exceptionHandler = { [weak self] _, value in
            self?.progress("JS exception: \(value?.toString() ?? "<unknown>")")
        }

        let getPID: @convention(block) () -> Int = { [targetPID] in Int(targetPID) }
        let send: @convention(block) (String?) -> String = { [weak self] command in
            guard let self, let command else { return "" }
            return self.sendCommand(command) ?? ""
        }
        let prepare: @convention(block) (Double, Double) -> String = { [weak self] address, length in
            guard let self else { return "" }
            return self.prepareMemoryRegion(UInt64(address), length: UInt64(length)) ?? "OK"
        }
        let log: @convention(block) (JSValue?) -> Void = { [weak self] value in
            self?.progress(value?.toString() ?? "")
        }

        context.setObject(getPID,  forKeyedSubscript: "get_pid" as NSString)
        context.setObject(send,    forKeyedSubscript: "send_command" as NSString)
        context.setObject(prepare, forKeyedSubscript: "prepare_memory_region" as NSString)
        context.setObject(log,     forKeyedSubscript: "log" as NSString)

        progress("Running universal.js against pid \(targetPID)…")
        context.evaluateScript(source)
        progress("JIT script finished (region blessed, detached).")
    }

    private func sendCommand(_ command: String) -> String? {
        guard let handle = command.withCString({ debugserver_command_new($0, nil, 0) }) else { return nil }
        defer { debugserver_command_free(handle) }
        var response: UnsafeMutablePointer<CChar>?
        if let error = debug_proxy_send_command(debugProxy, handle, &response) {
            progress("send_command error: \(IdeviceFFI.consume(error, fallback: "send_command").localizedDescription)")
            return nil
        }
        guard let response else { return "" }
        defer { idevice_string_free(response) }
        return String(cString: response)
    }

    private func prepareMemoryRegion(_ address: UInt64, length: UInt64) -> String? {
        guard length > 0 else { return "OK" }
        let pageCount = (length - 1) / Self.jitPageSize + 1
        for page in 0..<pageCount {
            let pageAddress = address + page * Self.jitPageSize

            let response = sendCommand("M\(String(pageAddress, radix: 16)),1:69")
            if let response, !(response.hasPrefix("OK") || response.isEmpty) {
                progress("page bless failed @0x\(String(pageAddress, radix: 16)): \(response)")
                return nil
            }
        }
        progress("Blessed \(pageCount) JIT page(s) at 0x\(String(address, radix: 16))")
        return "OK"
    }
}
