//
//  StikJITApp.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI
import Network
import UniformTypeIdentifiers

struct AccentColorKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}

extension EnvironmentValues {
    var accentColor: Color {
        get { self[AccentColorKey.self] }
        set { self[AccentColorKey.self] = newValue }
    }
}

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

func UpdateRetrieval() -> Bool {
    var ver: String {
        let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return marketingVersion
    }
    let urlString = "https://raw.githubusercontent.com/0-Blu/StikJIT/refs/heads/main/version.txt"
    var res = false
    httpGet(urlString) { result in
        if let fc = result {
            if ver != fc {
                res = true
            }
        }
    }
    return res
}

class DNSChecker: ObservableObject {
    @Published var appleIP: String?
    @Published var controlIP: String?
    @Published var dnsError: String?
    
    func checkDNS() {
        checkIfConnectedToWifi { [weak self] wifiConnected in
            guard let self = self else { return }
            if wifiConnected {
                let group = DispatchGroup()
                
                group.enter()
                self.lookupIPAddress(for: "gs.apple.com") { ip in
                    DispatchQueue.main.async {
                        self.appleIP = ip
                    }
                    group.leave()
                }
                
                group.enter()
                self.lookupIPAddress(for: "google.com") { ip in
                    DispatchQueue.main.async {
                        self.controlIP = ip
                    }
                    group.leave()
                }
                
                group.notify(queue: DispatchQueue.main) {
                    if self.controlIP == nil {
                        self.dnsError = "No internet connection."
                        print("Control host lookup failed, so no internet connection.")
                    } else if self.appleIP == nil {
                        self.dnsError = "Apple DNS blocked. Your network might be filtering Apple traffic."
                        print("Control lookup succeeded, but Apple lookup failed: likely blocked.")
                    } else {
                        self.dnsError = nil
                        print("DNS lookups succeeded: Apple -> \(self.appleIP!), Control -> \(self.controlIP!)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.dnsError = nil
                    print("Not connected to WiFi; continuing without DNS check.")
                }
            }
        }
    }
    
    private func checkIfConnectedToWifi(completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                completion(true)
            } else {
                completion(false)
            }
            monitor.cancel()
        }
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
    }
    
    private func lookupIPAddress(for host: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var hints = addrinfo(
                ai_flags: 0,
                ai_family: AF_UNSPEC,
                ai_socktype: SOCK_STREAM,
                ai_protocol: 0,
                ai_addrlen: 0,
                ai_canonname: nil,
                ai_addr: nil,
                ai_next: nil
            )
            var res: UnsafeMutablePointer<addrinfo>?
            let err = getaddrinfo(host, nil, &hints, &res)
            if err != 0 {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var ipAddress: String?
            var ptr = res
            while ptr != nil {
                if let addr = ptr?.pointee.ai_addr {
                    var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addr, ptr!.pointee.ai_addrlen,
                                   &hostBuffer, socklen_t(hostBuffer.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        ipAddress = String(cString: hostBuffer)
                        break
                    }
                }
                ptr = ptr?.pointee.ai_next
            }
            freeaddrinfo(res)
            DispatchQueue.main.async {
                completion(ipAddress)
            }
        }
    }
}

@main
struct HeartbeatApp: App {
    @State private var isLoading2 = true
    @State private var isPairing = false
    @State private var heartBeat = false
    @State private var error: Int32? = nil
    @State private var show_alert = false
    @State private var alert_string = ""
    @State private var alert_title = ""
    @StateObject private var mount = MountingProgress.shared
    @StateObject private var dnsChecker = DNSChecker()  // New DNS check state object
    @AppStorage("appTheme") private var appTheme: String = "system"
    @Environment(\.scenePhase) private var scenePhase   // Observe scene lifecycle
    
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
        newVerCheck()
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            switch appTheme {
            case "dark":
                window.overrideUserInterfaceStyle = .dark
            case "light":
                window.overrideUserInterfaceStyle = .light
            default:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    func newVerCheck() {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let VUA = UserDefaults.standard.object(forKey: "VersionUpdateAlert") as? Date ?? Date.distantPast
        
        if currentDate > Calendar.current.startOfDay(for: VUA) {
            if UpdateRetrieval() {
                alert_title = "Update Avaliable!"
                let urlString = "https://raw.githubusercontent.com/0-Blu/StikJIT/refs/heads/main/version.txt"
                httpGet(urlString) { result in
                    if result == nil { return }
                    alert_string = "Update to: version \(result!)!"
                    show_alert = true
                }
            }
            UserDefaults.standard.set(currentDate, forKey: "VersionUpdateAlert")
        }
    }
    
    private func applyTheme() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            switch appTheme {
            case "dark":
                window.overrideUserInterfaceStyle = .dark
            case "light":
                window.overrideUserInterfaceStyle = .light
            default:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoading2 {
                // Pass bindings to LoadingView for alert handling and version check.
                LoadingView(showAlert: $show_alert, alertTitle: $alert_title, alertMessage: $alert_string)
                    .onAppear {
                        dnsChecker.checkDNS()
                        
                        startProxy() { result, error in
                            if result {
                                checkVPNConnection() { result, vpn_error in
                                    if result {
                                        if FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                                            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                                                if pubHeartBeat {
                                                    isLoading2 = false
                                                    timer.invalidate()
                                                } else {
                                                    if let error {
                                                        if error == -9 {  // InvalidHostID is -9
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
                                            isLoading2 = false
                                        }
                                    } else if let vpn_error {
                                        showAlert(title: "Error", message: "EM Proxy failed to connect: \(vpn_error)", showOk: true) { _ in
                                            exit(0)
                                        }
                                    }
                                }
                            } else if let error {
                                showAlert(title: "Error", message: "EM Proxy Failed to start \(error)", showOk: true) { _ in }
                            }
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
                            
                            if accessing {
                                url.stopAccessingSecurityScopedResource()
                            }
                        case .failure(_):
                            print("Failed")
                        }
                    }
            } else {
                MainTabView()
                    .onAppear {
                        applyTheme()
                        let fileManager = FileManager.default
                        for (index, urlString) in urls.enumerated() {
                            let destinationURL = URL.documentsDirectory.appendingPathComponent(outputFiles[index])
                            if !fileManager.fileExists(atPath: destinationURL.path) {
                                downloadFile(from: urlString, to: destinationURL) { result in
                                    if (result != "") {
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
                                    onDismiss: {
                                        show_alert = false
                                    },
                                    showButton: true,
                                    primaryButtonText: "OK"
                                )
                            }
                        }
                    )
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("App became active – restarting heartbeat")
                startHeartbeatInBackground()
            }
        }
        .onChange(of: dnsChecker.dnsError) { newError in
            if let errorMsg = newError, !errorMsg.contains("Not connected to WiFi") {
                alert_title = "Network Issue"
                alert_string = errorMsg
                show_alert = true
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
                DispatchQueue.main.async {
                    callback(true, nil)
                }
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
        if let task = runningTask {
            return await task.value // Return existing task's result if running
        }
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
        DispatchQueue.main.async {
            self.coolisMounted = isMounted()
        }
    }
    
    func progressCallback(progress: size_t, total: size_t, context: UnsafeMutableRawPointer?) {
        let percentage = Double(progress) / Double(total) * 100.0
        print("Mounting progress: \(percentage)%")
        DispatchQueue.main.async {
            self.mountProgress = percentage
        }
    }
    
    func pubMount() {
        mount()
    }
    
    private func mount() {
        self.coolisMounted = isMounted()
        let fileManager = FileManager.default
        let pairingpath = URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path
        
        if isPairing(), !isMounted() {
            if let mountingThread = mountingThread {
                mountingThread.cancel()
                self.mountingThread = nil
            }
            
            mountingThread = Thread {
                let mountResult = mountPersonalDDI(
                    imagePath: URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg").path,
                    trustcachePath: URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg.trustcache").path,
                    manifestPath: URL.documentsDirectory.appendingPathComponent("DDI/BuildManifest.plist").path,
                    pairingFilePath: pairingpath
                )
                
                if mountResult != 0 {
                    showAlert(title: "Error", message: "An Error Occured when Mounting the DDI\nError Code: \(mountResult)", showOk: true, showTryAgain: true) { shouldTryAgain in
                        if shouldTryAgain {
                            self.mount()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.coolisMounted = isMounted()
                    }
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
        if err.rawValue == -9 {  // InvalidHostID is -9
            return false
        }
        return false
    }
    return true
}

func startHeartbeatInBackground() {
    let heartBeatThread = Thread {
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
                    // Special handling for InvalidHostID error (code -9)
                    if result == -9 {  // InvalidHostID is -9
                        // Delete the invalid pairing file
                        do {
                            try FileManager.default.removeItem(at: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                            print("Removed invalid pairing file")
                        } catch {
                            print("Error removing invalid pairing file: \(error)")
                        }
                        
                        // Show alert with option to select a new pairing file
                        showAlert(
                            title: "Invalid Pairing File",
                            message: "The pairing file is invalid or expired. Please select a new pairing file.",
                            showOk: true,
                            showTryAgain: false,
                            primaryButtonText: "Select New File"
                        ) { _ in
                            // This will be handled by the HomeView's fileImporter
                            NotificationCenter.default.post(name: NSNotification.Name("ShowPairingFilePicker"), object: nil)
                        }
                    } else {
                        // Handle other errors as before
                        showAlert(
                            title: "Heartbeat Error",
                            message: "Failed to connect to Heartbeat (\(result))",
                            showOk: false,
                            showTryAgain: true
                        ) { shouldTryAgain in
                            if shouldTryAgain {
                                startHeartbeatInBackground()
                            }
                        }
                    }
                }
            }
        }
        JITEnableContext.shared.startHeartbeat(completionHandler: completionHandler, logger: nil)
    }
    
    heartBeatThread.qualityOfService = .background
    heartBeatThread.name = "Heartbeat"
    heartBeatThread.start()
}

struct LoadingView: View {
    @Binding var showAlert: Bool
    @Binding var alertTitle: String
    @Binding var alertMessage: String
    
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("customAccentColor") private var customAccentColorHex: String = ""
    @AppStorage("appTheme") private var appTheme: String = "system"
    
    private var accentColor: Color {
        if customAccentColorHex.isEmpty {
            return .blue
        } else {
            return Color(hex: customAccentColorHex) ?? .blue
        }
    }
    
    private var isDarkMode: Bool {
        switch appTheme {
        case "dark":
            return true
        case "light":
            return false
        default:
            return colorScheme == .dark
        }
    }
    
    var body: some View {
        ZStack {
            Color(isDarkMode ? .black : .white)
                .ignoresSafeArea()
            
            VStack {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.3) : Color.black.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AngularGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.8),
                                accentColor.opacity(0.3)
                            ]),
                            center: .center
                        ), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(animate ? 360 : 0))
                        .frame(width: 80, height: 80)
                        .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: animate)
                }
                .shadow(color: accentColor.opacity(0.4), radius: 10, x: 0, y: 0)
                .onAppear {
                    animate = true

                    let os = ProcessInfo.processInfo.operatingSystemVersion
                    if os.majorVersion < 17 || (os.majorVersion == 17 && os.minorVersion < 4) {
                        // Minimum version check
                        alertTitle = "Unsupported OS Version"
                        alertMessage = "StikJIT only supports 17.4 and above except iOS/iPadOS 18.4 beta 1 (22E5200), your device is running iOS/iPadOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion) (\(buildString))"
                        showAlert = true
                    } else if let build = ProcessInfo.processInfo.operatingSystemVersionString
                        .split(separator: ")")
                        .first?
                        .split(separator: "(")
                        .last?
                        .replacingOccurrences(of: "Build ", with: ""),
                        build == "22E5200" {
                        
                        // Specific build check for iOS 18.4 beta 1
                        alertTitle = "Unsupported OS Version"
                        alertMessage = "StikJIT only supports 17.4 and above except iOS/iPadOS 18.4 beta 1 (22E5200), your device is running iOS/iPadOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion) (\(buildString))"
                        showAlert = true
                    }
                }

                Text("Loading...")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(isDarkMode ? .white.opacity(0.8) : .black.opacity(0.8))
                    .padding(.top, 20)
                    .opacity(animate ? 1.0 : 0.5)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}
public func showAlert(title: String, message: String, showOk: Bool, showTryAgain: Bool = false, primaryButtonText: String? = nil, completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.async {
        let rootViewController = UIApplication.shared.windows.last?.rootViewController
        
        if showTryAgain {
            let customErrorView = CustomErrorView(
                title: title,
                message: message,
                onDismiss: {
                    rootViewController?.presentedViewController?.dismiss(animated: true)
                    completion(false)
                },
                showButton: true,
                primaryButtonText: primaryButtonText ?? "Try Again",
                onPrimaryButtonTap: {
                    completion(true)
                }
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
                onDismiss: {
                    rootViewController?.presentedViewController?.dismiss(animated: true)
                    completion(true)
                },
                showButton: true,
                primaryButtonText: primaryButtonText ?? "OK",
                onPrimaryButtonTap: {
                    rootViewController?.presentedViewController?.dismiss(animated: true)
                    completion(true)
                }
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
                onDismiss: {
                    rootViewController?.presentedViewController?.dismiss(animated: true)
                    completion(false)
                },
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
    let documentsDirectory = URL.documentsDirectory
    
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
