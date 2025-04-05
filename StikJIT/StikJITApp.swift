//
//  StikJITApp.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI
import Foundation
import NetworkExtension
import Network
import UniformTypeIdentifiers

// MARK: - Welcome Sheet View

struct WelcomeSheetView: View {
    // A callback to dismiss the sheet
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome!")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(.primary)
                .padding(.top)

            Text("Thanks for installing the app. This brief introduction will help you get started.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("StikDebug is an on-device debugger designed specifically for self-developed apps. It helps streamline testing and troubleshooting without sending any data to external servers.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("The next step will prompt you to allow VPN permissions. This is necessary for the app to function properly. The VPN configuration allows your device to securely connect to itself — nothing more. Rest assured, no data is collected or sent externally. Everything stays on your device.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                onDismiss?()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(radius: 20)
        )
        .padding()
    }
}

// MARK: - Trimmed VPN Code

class VPNLogger: ObservableObject {
    @Published var logs: [String] = []
    static var shared = VPNLogger()
    private init() {}
    
    func log(_ message: Any, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
        #endif
        logs.append("\(message)")
    }
}

class TunnelManager: ObservableObject {
    @Published var tunnelStatus: TunnelStatus = .disconnected
    static var shared = TunnelManager()
    
    private var vpnManager: NETunnelProviderManager?
    private var tunnelDeviceIp: String {
        UserDefaults.standard.string(forKey: "TunnelDeviceIP") ?? "10.7.0.0"
    }
    private var tunnelFakeIp: String {
        UserDefaults.standard.string(forKey: "TunnelFakeIP") ?? "10.7.0.1"
    }
    private var tunnelSubnetMask: String {
        UserDefaults.standard.string(forKey: "TunnelSubnetMask") ?? "255.255.255.0"
    }
    private var tunnelBundleId: String {
        Bundle.main.bundleIdentifier!.appending(".TunnelProv")
    }
    
    enum TunnelStatus: String {
        case disconnected = "Disconnected"
        case connecting = "Connecting"
        case connected = "Connected"
        case disconnecting = "Disconnecting"
        case error = "Error"
    }
    
    private init() {
        loadTunnelPreferences()
        NotificationCenter.default.addObserver(self, selector: #selector(statusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
    }
    
    private func loadTunnelPreferences() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    VPNLogger.shared.log("Error loading preferences: \(error.localizedDescription)")
                    self.tunnelStatus = .error
                    return
                }
                if let managers = managers, !managers.isEmpty {
                    for manager in managers {
                        if let proto = manager.protocolConfiguration as? NETunnelProviderProtocol,
                           proto.providerBundleIdentifier == self.tunnelBundleId {
                            self.vpnManager = manager
                            self.updateTunnelStatus(from: manager.connection.status)
                            VPNLogger.shared.log("Loaded existing tunnel configuration")
                            break
                        }
                    }
                    if self.vpnManager == nil, let firstManager = managers.first {
                        self.vpnManager = firstManager
                        self.updateTunnelStatus(from: firstManager.connection.status)
                        VPNLogger.shared.log("Using existing tunnel configuration")
                    }
                } else {
                    VPNLogger.shared.log("No existing tunnel configuration found")
                }
            }
        }
    }
    
    @objc private func statusDidChange(_ notification: Notification) {
        if let connection = notification.object as? NEVPNConnection {
            updateTunnelStatus(from: connection.status)
        }
    }
    
    private func updateTunnelStatus(from connectionStatus: NEVPNStatus) {
        DispatchQueue.main.async {
            switch connectionStatus {
            case .invalid, .disconnected:
                self.tunnelStatus = .disconnected
            case .connecting:
                self.tunnelStatus = .connecting
            case .connected:
                self.tunnelStatus = .connected
            case .disconnecting:
                self.tunnelStatus = .disconnecting
            case .reasserting:
                self.tunnelStatus = .connecting
            @unknown default:
                self.tunnelStatus = .error
            }
            VPNLogger.shared.log("VPN status updated: \(self.tunnelStatus.rawValue)")
        }
    }
    
    private func createOrUpdateTunnelConfiguration(completion: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return completion(false) }
            if let error = error {
                VPNLogger.shared.log("Error loading preferences: \(error.localizedDescription)")
                return completion(false)
            }
            
            let manager: NETunnelProviderManager
            if let existingManagers = managers, !existingManagers.isEmpty {
                if let matchingManager = existingManagers.first(where: {
                    ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.tunnelBundleId
                }) {
                    manager = matchingManager
                    VPNLogger.shared.log("Updating existing tunnel configuration")
                } else {
                    manager = existingManagers[0]
                    VPNLogger.shared.log("Using first available tunnel configuration")
                }
            } else {
                manager = NETunnelProviderManager()
                VPNLogger.shared.log("Creating new tunnel configuration")
            }
            
            manager.localizedDescription = "StikDebug"
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = self.tunnelBundleId
            proto.serverAddress = "StikDebug's Local Network Tunnel"
            manager.protocolConfiguration = proto
            manager.isOnDemandEnabled = true
            manager.isEnabled = true
            
            manager.saveToPreferences { [weak self] error in
                guard let self = self else { return completion(false) }
                DispatchQueue.main.async {
                    if let error = error {
                        VPNLogger.shared.log("Error saving tunnel configuration: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    self.vpnManager = manager
                    VPNLogger.shared.log("Tunnel configuration saved successfully")
                    completion(true)
                }
            }
        }
    }
    
    func startVPN() {
        if let manager = vpnManager {
            startExistingVPN(manager: manager)
        } else {
            createOrUpdateTunnelConfiguration { [weak self] success in
                guard let self = self, success else { return }
                self.loadTunnelPreferences()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let manager = self.vpnManager {
                        self.startExistingVPN(manager: manager)
                    }
                }
            }
        }
    }
    
    private func startExistingVPN(manager: NETunnelProviderManager) {
        guard tunnelStatus != .connected else {
            VPNLogger.shared.log("Network tunnel is already connected")
            return
        }
        tunnelStatus = .connecting
        let options: [String: NSObject] = [
            "TunnelDeviceIP": tunnelDeviceIp as NSObject,
            "TunnelFakeIP": tunnelFakeIp as NSObject,
            "TunnelSubnetMask": tunnelSubnetMask as NSObject
        ]
        do {
            try manager.connection.startVPNTunnel(options: options)
            VPNLogger.shared.log("Network tunnel start initiated")
        } catch {
            tunnelStatus = .error
            VPNLogger.shared.log("Failed to start tunnel: \(error.localizedDescription)")
        }
    }
    
    func stopVPN() {
        guard let manager = vpnManager else { return }
        tunnelStatus = .disconnecting
        manager.connection.stopVPNTunnel()
        VPNLogger.shared.log("Network tunnel stop initiated")
    }
}

// MARK: - Rest of the App Code

let fileManager = FileManager.default

func httpGet(_ urlString: String, result: @escaping (String?) -> Void) {
    if let url = URL(string: urlString) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                result(nil)
                return
            }
            if let data = data, let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Response: \(httpResponse.statusCode)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        result(dataString)
                    }
                } else {
                    print("Received non-200 status code: \(httpResponse.statusCode)")
                }
            }
        }
        task.resume()
    }
}

@main
struct HeartbeatApp: App {
    @State private var isLoading = true
    @State private var isPairing = false
    @State private var heartBeat = false
    @State private var error: Int32? = nil
    @State private var show_alert = false
    @State private var alert_string = ""
    @State private var alert_title = ""
    @StateObject private var mount = MountingProgress.shared

    // Only show the welcome sheet on first launch.
    @State private var showWelcomeSheet: Bool = {
        let hasLaunched = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        if !hasLaunched {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            return true
        }
        return false
    }()
    
    let urls: [String] = [
        "https://github.com/doronz88/DeveloperDiskImage/raw/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/BuildManifest.plist",
        "https://github.com/doronz88/DeveloperDiskImage/raw/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/Image.dmg",
        "https://github.com/doronz88/DeveloperDiskImage/raw/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/Image.dmg.trustcache"
    ]
    
    let outputDir: String = "DDI"
    let outputFiles: [String] = [
        "DDI/BuildManifest.plist",
        "DDI/Image.dmg",
        "DDI/Image.dmg.trustcache"
    ]
    
    init() {
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }
    
    // MARK: - VPN Startup Sequence
    //
    // This function encapsulates the startup steps (starting the VPN, proxy,
    // and subsequent checks). It is called either automatically on non–first launch
    // or after the welcome sheet is dismissed.
    func startVPNSequence() {
        TunnelManager.shared.startVPN()
        
        startProxy() { result, error in
            if result {
                checkVPNConnection() { result, vpn_error in
                    if result {
                        if FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                                if pubHeartBeat {
                                    isLoading = false
                                    timer.invalidate()
                                } else {
                                    if let error = error {
                                        if error == InvalidHostID.rawValue {
                                            isPairing = true
                                        } else {
                                            startHeartbeatInBackground()
                                        }
                                        self.error = nil
                                    }
                                }
                            }
                            startHeartbeatInBackground()
                        } else {
                            isLoading = false
                        }
                    } else if let vpn_error = vpn_error {
                        showAlert(title: "Error", message: "EM Proxy failed to connect: \(vpn_error)", showOk: true) { _ in
                            exit(0)
                        }
                    }
                }
            } else if let error = error {
                showAlert(title: "Error", message: "EM Proxy Failed to start \(error)", showOk: true) { _ in }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading {
                    LoadingView()
                        .onAppear {
                            // Only start the VPN automatically if the welcome sheet is not shown.
                            if !showWelcomeSheet {
                                startVPNSequence()
                            }
                        }
                        .fileImporter(isPresented: $isPairing, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, .propertyList]) { result in
                            switch result {
                            case .success(let url):
                                let fileManager = FileManager.default
                                let accessing = url.startAccessingSecurityScopedResource()
                                if fileManager.fileExists(atPath: url.path) {
                                    do {
                                        if fileManager.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                                            try fileManager.removeItem(at: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                                        }
                                        try fileManager.copyItem(at: url, to: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                                        print("File copied successfully!")
                                        startHeartbeatInBackground()
                                    } catch {
                                        print("Error copying file: \(error)")
                                    }
                                } else {
                                    print("Source file does not exist.")
                                }
                                if accessing { url.stopAccessingSecurityScopedResource() }
                            case .failure(_):
                                print("Failed")
                            }
                        }
                } else {
                    MainTabView()
                        .onAppear {
                            let fileManager = FileManager.default
                            for (index, urlString) in urls.enumerated() {
                                let destinationURL = URL.documentsDirectory.appendingPathComponent(outputFiles[index])
                                if !fileManager.fileExists(atPath: destinationURL.path) {
                                    downloadFile(from: urlString, to: destinationURL) { result in
                                        if result != "" {
                                            alert_title = "An Error has Occurred"
                                            alert_string = "[Download DDI Error]: " + result
                                            show_alert = true
                                        }
                                    }
                                }
                            }
                        }
                        .overlay(
                            ZStack {
                                if show_alert {
                                    CustomErrorView(
                                        title: alert_title,
                                        message: alert_string,
                                        onDismiss: { show_alert = false },
                                        showButton: true,
                                        primaryButtonText: "OK"
                                    )
                                }
                            }
                        )
                }
            }
            // Present the welcome sheet on first launch.
            .sheet(isPresented: $showWelcomeSheet) {
                WelcomeSheetView {
                    // When the user taps "Get Started", dismiss the sheet and start the VPN.
                    showWelcomeSheet = false
                    startVPNSequence()
                }
            }
        }
    }
    
    func startProxy(callback: @escaping (Bool, Int?) -> Void) {
        let port = 51820
        let bindAddr = "127.0.0.1:\(port)"
        DispatchQueue.global(qos: .background).async {
            let result = start_emotional_damage(bindAddr)
            DispatchQueue.main.async {
                if result == 0 {
                    print("DEBUG: em_proxy started successfully on port \(port)")
                    callback(true, nil)
                } else {
                    print("DEBUG: Failed to start em_proxy")
                    callback(false, Int(result))
                }
            }
        }
    }
    
    private func checkVPNConnection(callback: @escaping (Bool, String?) -> Void) {
        let host = NWEndpoint.Host("10.7.0.1")
        let port = NWEndpoint.Port(rawValue: 62078)!
        let connection = NWConnection(host: host, port: port, using: .tcp)
        var timeoutWorkItem: DispatchWorkItem?
        
        timeoutWorkItem = DispatchWorkItem { [weak connection] in
            if connection?.state != .ready {
                connection?.cancel()
                DispatchQueue.main.async {
                    if timeoutWorkItem?.isCancelled == false {
                        callback(false, "[TIMEOUT] The loopback VPN is not connected. Try closing this app, turn it off and back on.")
                    }
                }
            }
        }
        
        connection.stateUpdateHandler = { [weak connection] state in
            switch state {
            case .ready:
                timeoutWorkItem?.cancel()
                connection?.cancel()
                DispatchQueue.main.async { callback(true, nil) }
            case .failed(let error):
                timeoutWorkItem?.cancel()
                connection?.cancel()
                DispatchQueue.main.async {
                    if error == NWError.posix(.ETIMEDOUT) {
                        callback(false, "The loopback VPN is not connected. Try closing the app, turn it off and back on.")
                    } else if error == NWError.posix(.ECONNREFUSED) {
                        callback(false, "Wifi is not connected. StikJIT won't work on cellular data.")
                    } else {
                        callback(false, "em proxy check error: \(error.localizedDescription)")
                    }
                }
            default:
                break
            }
        }
        connection.start(queue: .global())
        if let workItem = timeoutWorkItem {
            DispatchQueue.global().asyncAfter(deadline: .now() + 20, execute: workItem)
        }
    }
}

var pubHeartBeat = false

actor FunctionGuard<T> {
    private var runningTask: Task<T, Never>?
    func execute(_ work: @escaping @Sendable () -> T) async -> T {
        if let task = runningTask { return await task.value }
        let task = Task.detached { work() }
        runningTask = task
        let result = await task.value
        runningTask = nil
        return result
    }
}

class MountingProgress: ObservableObject {
    static var shared = MountingProgress()
    @Published var mountProgress: Double = 0.0
    @Published var mountingThread: Thread?
    @Published var coolisMounted: Bool = false
    
    func checkforMounted() {
        DispatchQueue.main.async { self.coolisMounted = isMounted() }
    }
    
    func progressCallback(progress: size_t, total: size_t, context: UnsafeMutableRawPointer?) {
        let percentage = Double(progress) / Double(total) * 100.0
        print("Mounting progress: \(percentage)%")
        DispatchQueue.main.async { self.mountProgress = percentage }
    }
    
    func pubMount() { mount() }
    
    private func mount() {
        self.coolisMounted = isMounted()
        let pairingpath = URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path
        if isPairing(), !isMounted() {
            if let mountingThread { mountingThread.cancel(); self.mountingThread = nil }
            mountingThread = Thread {
                let mountResult = mountPersonalDDI(
                    imagePath: URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg").path,
                    trustcachePath: URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg.trustcache").path,
                    manifestPath: URL.documentsDirectory.appendingPathComponent("DDI/BuildManifest.plist").path,
                    pairingFilePath: pairingpath
                )
                if mountResult != 0 {
                    showAlert(title: "Error", message: "An Error Occured when Mounting the DDI\nError Code: \(mountResult)", showOk: true, showTryAgain: true) { shouldTryAgain in
                        if shouldTryAgain { self.mount() }
                    }
                } else {
                    DispatchQueue.main.async { self.coolisMounted = isMounted() }
                }
            }
            mountingThread!.qualityOfService = .background
            mountingThread!.name = "mounting"
            mountingThread!.start()
        }
    }
}

func isPairing() -> Bool {
    let pairingpath = URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path
    var pairingFile: IdevicePairingFile?
    let err = idevice_pairing_file_read(pairingpath, &pairingFile)
    if err != IdeviceSuccess {
        print("Failed to read pairing file: \(err)")
        return false
    }
    return true
}

func startHeartbeatInBackground() {
    let heartBeat = Thread {
        let completionHandler: @convention(block) (Int32, String?) -> Void = { result, message in
            if result == 0 {
                print("Heartbeat started successfully: \(message ?? "")")
                pubHeartBeat = true
                if FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg.trustcache").path) {
                    MountingProgress.shared.pubMount()
                }
            } else {
                print("Error: \(message ?? "") (Code: \(result))")
                DispatchQueue.main.async {
                    showAlert(title: "Heartbeat Error", message: "Failed to connect to Heartbeat (\(result))", showOk: false, showTryAgain: true) { shouldTryAgain in
                        if shouldTryAgain { startHeartbeatInBackground() }
                    }
                }
            }
        }
        JITEnableContext.shared.startHeartbeat(completionHandler: completionHandler, logger: nil)
    }
    heartBeat.qualityOfService = .background
    heartBeat.name = "Heartbeat"
    heartBeat.start()
}

struct LoadingView: View {
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Use system background color instead of fixed black
            Color(colorScheme == .dark ? .black : .white)
                .ignoresSafeArea()
            VStack {
                ZStack {
                    // Background circle - slightly visible in both themes
                    Circle()
                        .stroke(lineWidth: 8)
                        .foregroundColor(colorScheme == .dark ? 
                            Color.white.opacity(0.3) : 
                            Color.black.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AngularGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.white.opacity(0.8) : Color.blue.opacity(0.8),
                                colorScheme == .dark ? Color.white.opacity(0.3) : Color.blue.opacity(0.3)
                            ]),
                            center: .center
                        ), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(animate ? 360 : 0))
                        .frame(width: 80, height: 80)
                        .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: animate)
                }
                // Shadow adapts to theme
                .shadow(color: colorScheme == .dark ? 
                    .white.opacity(0.5) : 
                    .blue.opacity(0.3), 
                    radius: 10, x: 0, y: 0)
                .onAppear {
                    animate = true
                }
                
                // Text adapts to theme
                Text("Loading...")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? 
                        .white.opacity(0.8) : 
                        .black.opacity(0.8))
                    .padding(.top, 20)
                    .opacity(animate ? 1.0 : 0.5)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}

public func showAlert(title: String, message: String, showOk: Bool, showTryAgain: Bool = false, completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.async {
        let rootViewController = UIApplication.shared.windows.last?.rootViewController
        if showTryAgain {
            let customErrorView = CustomErrorView(
                title: title,
                message: message,
                onDismiss: { completion(false) },
                showButton: true,
                primaryButtonText: "Try Again",
                onPrimaryButtonTap: { completion(true) }
            )
            let hostingController = UIHostingController(rootView: customErrorView)
            hostingController.modalPresentationStyle = .overFullScreen
            hostingController.modalTransitionStyle = .crossDissolve
            hostingController.view.backgroundColor = .clear
            rootViewController?.present(hostingController, animated: true)
        } else if showOk {
            let customErrorView = CustomErrorView(
                title: title,
                message: message,
                onDismiss: { completion(true) },
                showButton: true,
                primaryButtonText: "OK",
                onPrimaryButtonTap: { completion(true) }
            )
            let hostingController = UIHostingController(rootView: customErrorView)
            hostingController.modalPresentationStyle = .overFullScreen
            hostingController.modalTransitionStyle = .crossDissolve
            hostingController.view.backgroundColor = .clear
            rootViewController?.present(hostingController, animated: true)
        } else {
            let customErrorView = CustomErrorView(
                title: title,
                message: message,
                onDismiss: { completion(false) },
                showButton: false
            )
            let hostingController = UIHostingController(rootView: customErrorView)
            hostingController.modalPresentationStyle = .overFullScreen
            hostingController.modalTransitionStyle = .crossDissolve
            hostingController.view.backgroundColor = .clear
            rootViewController?.present(hostingController, animated: true)
        }
    }
}

func downloadFile(from urlString: String, to destinationURL: URL, completion: @escaping (String) -> Void) {
    let fileManager = FileManager.default
    guard let url = URL(string: urlString) else {
        print("Invalid URL: \(urlString)")
        completion("[Internal Invalid URL error]")
        return
    }
    let task = URLSession.shared.downloadTask(with: url) { (tempLocalUrl, response, error) in
        guard let tempLocalUrl = tempLocalUrl, error == nil else {
            print("Error downloading file from \(urlString): \(String(describing: error))")
            completion("Are you connected to the internet? [Download Failed]")
            return
        }
        do {
            try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try fileManager.moveItem(at: tempLocalUrl, to: destinationURL)
            print("Downloaded \(urlString) to \(destinationURL.path)")
        } catch {
            print("Error saving file: \(error)")
        }
    }
    task.resume()
    completion("")
}
