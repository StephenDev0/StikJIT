import Foundation
@_implementationOnly import idevice

private func ddiMountProgressCallback(progress: size_t, total: size_t, context: UnsafeMutableRawPointer?) {
    guard let context else { return }
    let progressHandler = Unmanaged<DDIProgressBox>.fromOpaque(context).takeUnretainedValue()
    let fraction = total > 0 ? Double(progress) / Double(total) : 0
    progressHandler.handler(fraction)
}

private final class DDIProgressBox {
    let handler: (Double) -> Void
    init(_ handler: @escaping (Double) -> Void) { self.handler = handler }
}

final class DDISession {

    private struct Tunnel {
        var adapter: OpaquePointer?
        var handshake: OpaquePointer?
        func free() {
            if let handshake { rsd_handshake_free(handshake) }
            if let adapter { adapter_free(adapter) }
        }
    }

    private let pairingFilePath: String
    private let configuration: StikJIT.Configuration

    init(pairingFilePath: String, configuration: StikJIT.Configuration) {
        self.pairingFilePath = pairingFilePath
        self.configuration = configuration
    }

    func isMounted() throws -> Bool {
        let tunnel = try makeTunnel()
        defer { tunnel.free() }

        var client: OpaquePointer?
        try IdeviceFFI.check("failed to connect to image mounter") {
            image_mounter_connect_rsd(tunnel.adapter, tunnel.handshake, &client)
        }
        guard let client else { throw StikJITError.debugProxyUnavailable }
        defer { image_mounter_free(client) }

        var devices: UnsafeMutablePointer<plist_t?>?
        var deviceCount = 0
        try IdeviceFFI.check("failed to fetch mounted devices") {
            image_mounter_copy_devices(client, &devices, &deviceCount)
        }
        if let devices {
            for index in 0..<deviceCount { plist_free(devices[index]) }
            idevice_data_free(
                UnsafeMutableRawPointer(devices).assumingMemoryBound(to: UInt8.self),
                UInt(deviceCount * MemoryLayout<plist_t?>.stride))
        }
        return deviceCount > 0
    }

    func mountDDI(imagePath: String, trustcachePath: String, manifestPath: String, progress: @escaping (Double) -> Void) throws {
        let imageData = try mappedFileData(atPath: imagePath, description: "developer disk image")
        let trustcacheData = try mappedFileData(atPath: trustcachePath, description: "developer disk image trust cache")
        let manifestData = try mappedFileData(atPath: manifestPath, description: "developer disk image manifest")

        let tunnel = try makeTunnel()
        defer { tunnel.free() }

        let uniqueChipID = try fetchUniqueChipID(over: tunnel)

        var client: OpaquePointer?
        try IdeviceFFI.check("failed to connect to image mounter") {
            image_mounter_connect_rsd(tunnel.adapter, tunnel.handshake, &client)
        }
        guard let client else { throw StikJITError.debugProxyUnavailable }
        defer { image_mounter_free(client) }

        let progressBox = DDIProgressBox(progress)
        let context = Unmanaged.passUnretained(progressBox).toOpaque()

        try IdeviceFFI.check("failed to mount personalized developer disk image") {
            imageData.withUnsafeBytes { imageBuffer -> UnsafeMutablePointer<IdeviceFfiError>? in
                trustcacheData.withUnsafeBytes { trustcacheBuffer -> UnsafeMutablePointer<IdeviceFfiError>? in
                    manifestData.withUnsafeBytes { manifestBuffer -> UnsafeMutablePointer<IdeviceFfiError>? in
                        image_mounter_mount_personalized_with_callback_rsd(
                            client,
                            tunnel.adapter,
                            tunnel.handshake,
                            imageBuffer.bindMemory(to: UInt8.self).baseAddress,
                            imageData.count,
                            trustcacheBuffer.bindMemory(to: UInt8.self).baseAddress,
                            trustcacheData.count,
                            manifestBuffer.bindMemory(to: UInt8.self).baseAddress,
                            manifestData.count,
                            nil,
                            uniqueChipID,
                            ddiMountProgressCallback,
                            context)
                    }
                }
            }
        }
    }

    private func mappedFileData(atPath path: String, description: String) throws -> Data {
        guard FileManager.default.fileExists(atPath: path) else {
            throw StikJITError.ddiFilesMissing("\(description) not found at \(path)")
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        guard !data.isEmpty else {
            throw StikJITError.ddiFilesMissing("\(description) is empty at \(path)")
        }
        return data
    }

    private func fetchUniqueChipID(over tunnel: Tunnel) throws -> UInt64 {
        var client: OpaquePointer?
        try IdeviceFFI.check("failed to connect to lockdownd") {
            lockdownd_connect_rsd(tunnel.adapter, tunnel.handshake, &client)
        }
        guard let client else { throw StikJITError.debugProxyUnavailable }
        defer { lockdownd_client_free(client) }

        var uniqueChipIDPlist: plist_t?
        try IdeviceFFI.check("failed to query UniqueChipID") {
            "UniqueChipID".withCString { lockdownd_get_value(client, $0, nil, &uniqueChipIDPlist) }
        }
        guard let uniqueChipIDPlist else {
            throw StikJITError.device(code: -1, subCode: 0, message: "UniqueChipID was not returned by lockdownd")
        }
        defer { plist_free(uniqueChipIDPlist) }

        var value: UInt64 = 0
        plist_get_uint_val(uniqueChipIDPlist, &value)
        return value
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
}
