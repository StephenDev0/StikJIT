//
//  SettingsView.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customBackgroundColor") private var customBackgroundColorHex: String = Color.primaryBackground.toHex() ?? "#000000"
    @AppStorage("selectedAppIcon") private var selectedAppIcon: String = "AppIcon"
    @State private var isShowingPairingFilePicker = false

    @State private var selectedBackgroundColor: Color = Color.primaryBackground
    @State private var showIconPopover = false
    @State private var showPairingFileMessage = false
    @State private var pairingFileIsValid = false
    @State private var isImportingFile = false
    @State private var importProgress: Float = 0.0

    var body: some View {
        ZStack {
            selectedBackgroundColor
                .ignoresSafeArea()

            Form {
                Section(header: Text("General").font(.headline).foregroundColor(.primaryText)) {
                    HStack {
                        Label("", systemImage: "person.fill")
                            .foregroundColor(.primaryText)
                        Spacer()
                        TextField("Username", text: $username)
                            .foregroundColor(.primaryText)
                            .padding(10)
                            .background(Color.cardBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedBackgroundColor, lineWidth: 1)
                            )
                    }
                    .listRowBackground(Color.cardBackground)
                }

                Section(header: Text("Appearance").font(.headline).foregroundColor(.primaryText)) {
                    ColorPicker("Background Color", selection: $selectedBackgroundColor)
                        .onChange(of: selectedBackgroundColor) { newColor in
                            saveCustomBackgroundColor(newColor)
                        }
                        .listRowBackground(Color.cardBackground)
                        .foregroundColor(.primaryText)
                }
                
                Section(header: Text("Pairing File").font(.headline).foregroundColor(.primaryText)) {
                    HStack {
                        Button {
                            isShowingPairingFilePicker = true
                        } label: {
                            Text("Import New Pairing File")
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.cardBackground)
                    
                    if isImportingFile {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Processing pairing file...")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondaryText)
                                Spacer()
                                Text("\(Int(importProgress * 100))%")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondaryText)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.cardBackground)
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.green)
                                        .frame(width: geometry.size.width * CGFloat(importProgress), height: 8)
                                        .animation(.linear(duration: 0.3), value: importProgress)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.cardBackground)
                    }
                    
                    if showPairingFileMessage && pairingFileIsValid {
                        HStack {
                            Spacer()
                            Text("✓ Pairing file successfully imported")
                                .font(.system(.callout, design: .rounded))
                                .foregroundColor(.green)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.cardBackground)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.7)),
                                removal: .opacity.animation(.easeOut(duration: 0.25))
                            )
                        )
                    }
                }

                Section(header: Text("About").font(.headline).foregroundColor(.primaryText)) {
                    HStack {
                        Text("Version:")
                            .foregroundColor(.secondaryText)
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.primaryText)
                    }
                    .listRowBackground(Color.cardBackground)
                    
                    HStack {
                        Text("App Creator:")
                            .foregroundColor(.secondaryText)
                        Spacer()
                        Text("Stephen")
                            .foregroundColor(.primaryText)
                    }
                    .listRowBackground(Color.cardBackground)
                    
                    HStack {
                        Text("idevice & em_proxy Creator:")
                            .foregroundColor(.secondaryText)
                        Spacer()
                        Text("jkcoxson")
                            .foregroundColor(.primaryText)
                    }
                    
                    .listRowBackground(Color.cardBackground)
                    HStack {
                        Text("Collaborators:")
                            .foregroundColor(.secondaryText)
                        Spacer()
                        Text("Stossy11")
                            .foregroundColor(.primaryText)
                        Text("Neo")
                            .foregroundColor(.primaryText)
                        Text("Se2crid")
                            .foregroundColor(.primaryText)
                        Text("HugeBlack")
                            .foregroundColor(.primaryText)
                    }
                    .listRowBackground(Color.cardBackground)
                    Button(action: {
                        if let url = URL(string: "https://github.com/0-Blu/StikJIT") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("View Source Code")
                                .foregroundColor(.secondaryText)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.primaryText)
                        }
                    }
                    .listRowBackground(Color.cardBackground)
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/us/app/stiknes/id6737158545") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Like this app? Check out StikNES!")
                                .foregroundColor(.secondaryText)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.primaryText)
                        }
                    }
                    .listRowBackground(Color.cardBackground)
                }
            }
            .background(selectedBackgroundColor)
            .scrollContentBackground(.hidden)
            .navigationBarTitle("Settings")
            .font(.bodyFont)
            .accentColor(.accentColor)
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
                        
                        DispatchQueue.main.async {
                            isImportingFile = true
                            importProgress = 0.0
                        }
                        
                        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                            DispatchQueue.main.async {
                                if importProgress < 1.0 {
                                    importProgress += 0.25
                                } else {
                                    timer.invalidate()
                                    isImportingFile = false
                                    pairingFileIsValid = true
                                    
                                    withAnimation {
                                        showPairingFileMessage = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation {
                                            showPairingFileMessage = false
                                        }
                                    }
                                }
                            }
                        }
                        
                        startHeartbeatInBackground()
                        
                        RunLoop.current.add(progressTimer, forMode: .common)
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
        .onAppear {
            loadCustomBackgroundColor()
        }
    }

    private func loadCustomBackgroundColor() {
        selectedBackgroundColor = Color(hex: customBackgroundColorHex) ?? Color.primaryBackground
    }

    private func saveCustomBackgroundColor(_ color: Color) {
        customBackgroundColorHex = color.toHex() ?? "#000000"
    }

    private func changeAppIcon(to iconName: String) {
        selectedAppIcon = iconName
        UIApplication.shared.setAlternateIconName(iconName == "AppIcon" ? nil : iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            }
        }
    }

    private func iconButton(_ label: String, icon: String) -> some View {
        Button(action: {
            changeAppIcon(to: icon)
            showIconPopover = false
        }) {
            HStack {
                Image(uiImage: UIImage(named: icon) ?? UIImage())
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                Text(label)
                    .foregroundColor(.primaryText)
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}
