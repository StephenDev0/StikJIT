//
//  ContentView.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

struct HomeView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customBackgroundColor") private var customBackgroundColorHex: String = Color.primaryBackground.toHex() ?? "#000000"
    @State private var selectedBackgroundColor: Color = Color(hex: UserDefaults.standard.string(forKey: "customBackgroundColor") ?? "#000000") ?? Color.primaryBackground
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @AppStorage("bundleID") private var bundleID: String = ""
    @State private var isProcessing = false
    @State private var isShowingInstalledApps = false
    @State private var isShowingPairingFilePicker = false

    var body: some View {
        ZStack {
            selectedBackgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                Spacer()
                VStack(spacing: 5) {
                    Text("Welcome to StikJIT \(username)!")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Click enable jit to get started")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Button(action: {
                    if !FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                        isShowingPairingFilePicker = true
                    } else {
                        isShowingInstalledApps = true
                    }
                }) {
                    Label("Enable JIT", systemImage: "list.bullet")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
        }
        .onReceive(timer) { _ in
            refreshBackground()
        }
        .fileImporter(isPresented: $isShowingPairingFilePicker, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, .propertyList]) {result in
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
                        
                        Thread.sleep(forTimeInterval: 5)
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
        .sheet(isPresented: $isShowingInstalledApps) {
            InstalledAppsListView { selectedBundle in
                bundleID = selectedBundle
                isShowingInstalledApps = false
                HapticFeedbackHelper.trigger()
                startJITInBackground(with: selectedBundle)
            }
        }
    }
    
    private func refreshBackground() {
        selectedBackgroundColor = Color(hex: customBackgroundColorHex) ?? Color.primaryBackground
    }
    
    private func startJITInBackground(with bundleID: String) {
        isProcessing = true
        DispatchQueue.global(qos: .background).async {
            guard let cBundleID = strdup(bundleID) else {
                DispatchQueue.main.async { isProcessing = false }
                return
            }
            
            _ = debug_app(cBundleID)
            
            free(cBundleID)
            DispatchQueue.main.async {
                isProcessing = false
            }
        }
    }
}

class InstalledAppsViewModel: ObservableObject {
    @Published var apps: [String: String] = [:]
    
    init() {
        loadApps()
    }
    
    func loadApps() {
        guard let rawPointer = list_installed_apps() else {
            self.apps = [:]
            return
        }
        
        let output = String(cString: rawPointer)
        free(rawPointer)

        guard let jsonData = output.data(using: .utf8) else {
            print("Error: Failed to convert string to data")
            self.apps = [:]
            return
        }
        
        print(output)

        // Decode the JSON into a Swift dictionary
        do {
            let decoder = JSONDecoder()
            let apps = try decoder.decode([String: String].self, from: jsonData)
            if let app = apps.first, app.key == "error" {
                self.apps = [:]
            } else {
                self.apps = apps
            }
            return
        } catch {
            print("Error: Failed to decode JSON - \(error)")
            self.apps = [:]
            return
        }
        
    }
}



#Preview {
    HomeView()
}
