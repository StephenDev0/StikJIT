import Foundation
@_implementationOnly import idevice

enum IdeviceFFI {

    static func consume(_ pointer: UnsafeMutablePointer<IdeviceFfiError>?,
                        fallback: String) -> StikJITError {
        guard let pointer else { return .device(code: -1, subCode: 0, message: fallback) }
        let error = StikJITError.device(
            code: pointer.pointee.code,
            subCode: pointer.pointee.sub_code,
            message: pointer.pointee.message.map { String(cString: $0) } ?? fallback)
        idevice_error_free(pointer)
        return error
    }

    static func check(_ fallback: String,
                      _ call: () -> UnsafeMutablePointer<IdeviceFfiError>?) throws {
        if let error = call() { throw consume(error, fallback: fallback) }
    }
}
