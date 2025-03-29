//
//  StikJITApp.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI
import em_proxy
import UniformTypeIdentifiers

@main
struct HeartbeatApp: App {
    @State private var isLoading = true
    @State private var isPairing = false
    @State private var heartBeat = false
    @State private var error: Int32? = nil
    
    init() {
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }

    var body: some Scene {
        WindowGroup {
            if isLoading {
                LoadingView()
                    .onAppear {
                        startProxy()
                        if FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                                if heartBeat {
                                    isLoading = false
                                    timer.invalidate()
                                } else {
                                    if let error {
                                        if error == InvalidHostID.rawValue {
                                            isPairing = true
                                        } else {
                                            startHeartbeatInBackground()
                                        }
                                        self.error = nil
                                    }
                                }
                            }
                            
                            // Add 15-second timeout timer
                            Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
                                if isLoading {
                                    // Still loading after 15 seconds - show error
                                    showCustomError(
                                        title: "HeartBeat Error", 
                                        message: "Unable to establish connection.\nPlease check your WiFi and VPN connection.",
                                        showButton: false
                                    ) {
                                        self.error = -1 // Using a generic error code
                                    }
                                }
                            }
                            
                            startHeartbeatInBackground()
                        } else {
                            isLoading = false
                        }
                    }
                    .fileImporter(isPresented: $isPairing, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, .propertyList]) {result in
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
            }
        }
    }
    

    func startProxy() {
        let port = 51820
        let bindAddr = "127.0.0.1:\(port)"
        
        DispatchQueue.global(qos: .background).async {
            let result = start_emotional_damage(bindAddr)

            DispatchQueue.main.async {
                if result == 0 {
                    print("DEBUG: em_proxy started successfully on port \(port)")
                } else {
                    print("DEBUG: Failed to start em_proxy")
                }
            }
        }
    }
    
    func startHeartbeatInBackground() {
        let heartBeat = Thread {
            let completionHandler: @convention(block) (Int32, String?) -> Void = { result, message in

                if result == 0 {
                    print("Heartbeat started successfully: \(message ?? "")")
                    
                    self.heartBeat = true
                } else {
                    print("Error: \(result == InvalidHostID.rawValue ? "Invalid host ID, Please Select New Pairing File" : message ?? "") (Code: \(result))")
                    
                    showCustomError(
                        title: "Connection Error", 
                        message: "No WiFi or VPN!\nYou do not appear to be connected to WiFi and/or the WireGuard VPN!",
                        showButton: false
                    ) {
                        self.error = result
                    }
                }
            }
            
            JITEnableContext.shared().startHeartbeat(completionHandler: completionHandler, logger: nil)
        }
        
        heartBeat.qualityOfService = .background
        heartBeat.name = "HeartBeat"
        heartBeat.start()
    }

}


func startHeartbeatInBackground() {
    let heartBeat = Thread {
        let completionHandler: @convention(block) (Int32, String?) -> Void = { result, message in

            if result == 0 {
                print("Heartbeat started successfully: \(message ?? "")")
            } else {
                print("Error: \(message ?? "") (Code: \(result))")
                
                showCustomError(
                    title: "HeartBeat Error",
                    message: "No WiFi or VPN!\nYou do not appear to be connected to WiFi and/or the WireGuard VPN!",
                    showButton: false
                ) {
                    // No need to restart the heartbeat here anymore
                }
            }
        }
        
        JITEnableContext.shared().startHeartbeat(completionHandler: completionHandler, logger: nil)
    }
    
    heartBeat.qualityOfService = .background
    heartBeat.name = "Heartbeat"
    heartBeat.start()
}


struct LoadingView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .foregroundColor(Color.white.opacity(0.3))
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AngularGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.3)]),
                            center: .center
                        ), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(animate ? 360 : 0))
                        .frame(width: 80, height: 80)
                        .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: animate)
                }
                .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
                .onAppear {
                    animate = true
                }

                Text("Loading...")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 20)
                    .opacity(animate ? 1.0 : 0.5)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}

public func showCustomError(title: String, message: String, showButton: Bool = true, completion: @escaping () -> Void = {}) {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {
        
        let hostingController = UIHostingController(
            rootView: CustomErrorView(
                title: title,
                message: message,
                onDismiss: completion,
                showButton: showButton
            )
        )
        hostingController.view.backgroundColor = .clear
        hostingController.modalPresentationStyle = .overFullScreen
        rootViewController.present(hostingController, animated: false)
    }
}
