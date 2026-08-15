import Foundation
import JavaScriptCore
@_implementationOnly import idevice

final class ScriptRunner {

    private static let jitPageSize: UInt64 = 16384
    private static let jitPageCommandLength = 19
    private static let commandsPerBatch = 128

    private let targetPID: Int32
    private let debugProxy: OpaquePointer
    private let script: StikJIT.Script
    private let progress: (String) -> Void
    private var context: JSContext?
    private var executionError: StikJITError?

    init(targetPID: Int32, debugProxy: OpaquePointer, script: StikJIT.Script, progress: @escaping (String) -> Void) {
        self.targetPID = targetPID
        self.debugProxy = debugProxy
        self.script = script
        self.progress = progress
    }

    func run() throws {
        let source = try BundledScript.source(for: script)

        guard let context = JSContext() else { throw StikJITError.scriptUnavailable }
        self.context = context

        context.exceptionHandler = { [weak self] _, value in
            let detail = value?.toString() ?? "unknown JavaScript exception"
            self?.recordExecutionError(.scriptExecution(detail))
        }

        let getPID: @convention(block) () -> Int = { [targetPID] in Int(targetPID) }
        let send: @convention(block) (String?) -> String = { [weak self] command in
            guard let self, let command else { return "" }
            return self.sendCommand(command) ?? ""
        }
        let prepare: @convention(block) (Double, Double) -> String = { [weak self] address, length in
            guard let self else { return "" }
            return self.prepareMemoryRegion(UInt64(address), length: UInt64(length)) ?? ""
        }
        let log: @convention(block) (JSValue?) -> Void = { [weak self] value in
            self?.progress(value?.toString() ?? "")
        }

        context.setObject(getPID,  forKeyedSubscript: "get_pid" as NSString)
        context.setObject(send,    forKeyedSubscript: "send_command" as NSString)
        context.setObject(prepare, forKeyedSubscript: "prepare_memory_region" as NSString)
        context.setObject(log,     forKeyedSubscript: "log" as NSString)

        progress("Running \(script.name) against pid \(targetPID)…")
        context.evaluateScript(source)
        if let executionError { throw executionError }
        progress("JIT script finished (region blessed, detached).")
    }

    private func sendCommand(_ command: String) -> String? {
        guard let handle = command.withCString({ debugserver_command_new($0, nil, 0) }) else { return nil }
        defer { debugserver_command_free(handle) }
        var response: UnsafeMutablePointer<CChar>?
        if let error = debug_proxy_send_command(debugProxy, handle, &response) {
            recordExecutionError(IdeviceFFI.consume(error, fallback: "send_command"))
            return nil
        }
        guard let response else { return "" }
        defer { idevice_string_free(response) }
        return String(cString: response)
    }

    private func prepareMemoryRegion(_ address: UInt64, length: UInt64) -> String? {
        guard length > 0 else { return "OK" }
        let pageCount = Int((length - 1) / Self.jitPageSize + 1)

        let commandBuffer = Self.makeBlessCommands(startAddress: address, pageCount: pageCount)

        for batchStart in stride(from: 0, to: pageCount, by: Self.commandsPerBatch) {
            let commandsInBatch = min(Self.commandsPerBatch, pageCount - batchStart)
            let byteOffset = batchStart * Self.jitPageCommandLength
            let byteCount = commandsInBatch * Self.jitPageCommandLength

            let sendError = commandBuffer.withUnsafeBytes { rawBuffer -> UnsafeMutablePointer<IdeviceFfiError>? in
                let base = rawBuffer.bindMemory(to: UInt8.self).baseAddress!
                return debug_proxy_send_raw(debugProxy, base.advanced(by: byteOffset), UInt(byteCount))
            }
            if let sendError {
                recordExecutionError(IdeviceFFI.consume(sendError, fallback: "debug_proxy_send_raw"))
                return nil
            }

            for _ in 0..<commandsInBatch {
                var response: UnsafeMutablePointer<CChar>?
                let readError = debug_proxy_read_response(debugProxy, &response)
                if let response {
                    idevice_string_free(response)
                }
                if let readError {
                    recordExecutionError(IdeviceFFI.consume(readError, fallback: "debug_proxy_read_response"))
                    return nil
                }
            }
        }

        progress("Blessed \(pageCount) JIT page(s) at 0x\(String(address, radix: 16))")
        return "OK"
    }

    private func recordExecutionError(_ error: StikJITError) {
        if executionError == nil {
            executionError = error
            progress(error.localizedDescription)
        }
    }

    private static func makeBlessCommands(startAddress: UInt64, pageCount: Int) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: pageCount * jitPageCommandLength)

        for page in 0..<pageCount {
            let pageAddress = startAddress + UInt64(page) * jitPageSize
            let start = page * jitPageCommandLength

            buffer[start + 0] = UInt8(ascii: "$")
            buffer[start + 1] = UInt8(ascii: "M")
            writeHexAddress(pageAddress, into: &buffer, at: start + 2)
            buffer[start + 11] = UInt8(ascii: ",")
            buffer[start + 12] = UInt8(ascii: "1")
            buffer[start + 13] = UInt8(ascii: ":")
            buffer[start + 14] = UInt8(ascii: "6")
            buffer[start + 15] = UInt8(ascii: "9")
            buffer[start + 16] = UInt8(ascii: "#")
            writeChecksum(into: &buffer, bodyStart: start + 1, hashIndex: start + 16)
        }

        return buffer
    }

    private static func writeHexAddress(_ address: UInt64, into buffer: inout [UInt8], at index: Int) {
        for nibble in 0..<9 {
            let shift = UInt64((8 - nibble) * 4)
            buffer[index + nibble] = hexDigit(UInt8((address >> shift) & 0xf))
        }
    }

    private static func writeChecksum(into buffer: inout [UInt8], bodyStart: Int, hashIndex: Int) {
        var checksum: UInt8 = 0
        for index in bodyStart..<hashIndex {
            checksum &+= buffer[index]
        }
        buffer[hashIndex + 1] = hexDigit((checksum & 0xf0) >> 4)
        buffer[hashIndex + 2] = hexDigit(checksum & 0x0f)
    }

    private static func hexDigit(_ value: UInt8) -> UInt8 {
        value < 10 ? value + UInt8(ascii: "0") : value - 10 + UInt8(ascii: "a")
    }
}
