//  SettingsView.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customBackgroundColor") private var customBackgroundColorHex: String = ""
    @AppStorage("selectedAppIcon") private var selectedAppIcon: String = "AppIcon"
    @State private var isShowingPairingFilePicker = false
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedBackgroundColor: Color = .clear
    @State private var showIconPopover = false
    @State private var showPairingFileMessage = false
    @State private var pairingFileIsValid = false
    @State private var isImportingFile = false
    @State private var importProgress: Float = 0.0
    @State private var is_lc = false
    @State private var showColorPickerPopup = false
    
    @StateObject private var mountProg = MountingProgress.shared
    @StateObject private var tunnelManager = TunnelManager.shared

    @State private var mounted = false
    
    @State private var showingConsoleLogsView = false
    
    private var appVersion: String {
        let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return marketingVersion
    }

    // Developer profile image URLs 
    private let developerProfiles: [String: String] = [
        "Stephen": "https://github.com/0-Blu.png",
        "jkcoxson": "https://github.com/jkcoxson.png",
        "Stossy11": "https://github.com/Stossy11.png",
        "Neo": "https://github.com/neoarz.png",
        "Se2crid": "https://github.com/Se2crid.png",
        "Huge_Black": "https://github.com/HugeBlack.png",
        "Wynwxst": "https://github.com/Wynwxst.png"
    ]

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    // App Logo and Username Section
                    VStack(spacing: 16) {
                        VStack {
                            Image("StikJIT")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.top, 16)
                        
                        Text("StikDebug")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Username", text: $username)
                                .padding(14)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                        .opacity(0.6)
                    
                    // Appearance section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            // Theme selector with segmented control style
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Background Color")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Clean segmented style picker
                                Picker("Theme Mode", selection: Binding(
                                    get: { customBackgroundColorHex.isEmpty },
                                    set: { newValue in
                                        if newValue {
                                            // System theme selected
                                            customBackgroundColorHex = ""
                                            selectedBackgroundColor = colorScheme == .dark ? Color.black : Color.white
                                        } else if customBackgroundColorHex.isEmpty {
                                            // Custom color selected - initialize with current theme color
                                            let initialColor = colorScheme == .dark ? Color.black : Color.white
                                            customBackgroundColorHex = initialColor.toHex() ?? "#000000"
                                            selectedBackgroundColor = initialColor
                                            
                                            // Don't open color picker popup automatically anymore
                                            // User will need to press the "Change Color" button
                                        }
                                    }
                                )) {
                                    Text("System").tag(true)
                                    Text("Custom").tag(false)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 4)
                                
                                // Show selection button and color picker inline when in custom mode
                                if !customBackgroundColorHex.isEmpty {
                                    HStack {
                                        // Left side - just text, no color preview
                                        Text("Choose color")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        // Right side - embedded color picker
                                        ColorPicker("", selection: $selectedBackgroundColor, supportsOpacity: false)
                                            .labelsHidden()
                                            .scaleEffect(0.8)
                                            .onChange(of: selectedBackgroundColor) { newColor in
                                                saveCustomBackgroundColor(newColor)
                                            }
                                    }
                                    .padding(.vertical, 8)
                                    .transition(.opacity)
                                }
                                
                                // Help text - only show for system mode
                                if customBackgroundColorHex.isEmpty {
                                    Text("Uses light/dark mode system colors")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .animation(.easeInOut(duration: 0.2), value: customBackgroundColorHex.isEmpty)
                    }
                    
                    // VPN Control section with Stop VPN button
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("VPN")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            Button(action: {
                                if tunnelManager.tunnelStatus == .connected {
                                    tunnelManager.stopVPN()
                                } else if tunnelManager.tunnelStatus == .disconnected {
                                    tunnelManager.startVPN()
                                }
                                // Optionally, you can handle other statuses here as needed.
                            }) {
                                HStack {
                                    Spacer()
                                    Text(tunnelManager.tunnelStatus == .connected ? "Stop VPN" : "Start VPN")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .background(tunnelManager.tunnelStatus == .connected ? Color.red : Color.blue)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                    
                    // Pairing File section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Pairing File")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            Button {
                                isShowingPairingFilePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.system(size: 18))
                                    Text("Import New Pairing File")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            if isImportingFile {
                                VStack(spacing: 10) {
                                    HStack {
                                        Text("Processing pairing file...")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(importProgress * 100))%")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(UIColor.tertiarySystemFill))
                                                .frame(height: 10)
                                            
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.green)
                                                .frame(width: geometry.size.width * CGFloat(importProgress), height: 10)
                                                .animation(.linear(duration: 0.3), value: importProgress)
                                        }
                                    }
                                    .frame(height: 10)
                                }
                                .padding(.top, 6)
                            }
                            
                            if showPairingFileMessage && pairingFileIsValid {
                                HStack {
                                    Spacer()
                                    Text("✓ Pairing file successfully imported")
                                        .font(.system(.callout, design: .rounded))
                                        .foregroundColor(.green)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 18)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(10)
                                    Spacer()
                                }
                                .padding(.top, 6)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.9)
                                            .combined(with: .opacity)
                                            .animation(.spring(response: 0.4, dampingFraction: 0.7)),
                                        removal: .opacity.animation(.easeOut(duration: 0.25))
                                    )
                                )
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                    
                    // Developer Disk Image section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Developer Disk Image")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            // Status indicator with icon
                            HStack(spacing: 12) {
                                Image(systemName: mounted || (mountProg.mountProgress == 100) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(mounted || (mountProg.mountProgress == 100) ? .green : .red)
                                
                                Text(mounted || (mountProg.mountProgress == 100) ? "Successfully Mounted" : "Not Mounted")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(12)
                            
                            // Helper text shown separately below the status indicator
                            if !(mounted || (mountProg.mountProgress == 100)) {
                                Text("Import pairing file and restart the app to mount DDI")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                            }
                            
                            // Only show progress if actively mounting
                            if mountProg.mountProgress > 0 && mountProg.mountProgress < 100 && !mounted {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Mounting in progress...")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(Int(mountProg.mountProgress))%")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(UIColor.tertiarySystemFill))
                                                .frame(height: 8)
                                            
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.green)
                                                .frame(width: geometry.size.width * CGFloat(mountProg.mountProgress / 100.0), height: 8)
                                                .animation(.linear(duration: 0.3), value: mountProg.mountProgress)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                                .padding(.top, 6)
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .onAppear() {
                            self.mounted = isMounted()
                        }
                    }
                    
                    // About section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            // Main Developers
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Creators")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 16) {
                                    // App Creator
                                    VStack(spacing: 8) {
                                        ProfileImage(url: developerProfiles["Stephen"] ?? "")
                                            .frame(width: 60, height: 60)
                                        
                                        Text("Stephen")
                                            .fontWeight(.semibold)
                                        
                                        Text("App Creator")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        if let url = URL(string: "https://github.com/0-Blu") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    
                                    // Library Developer
                                    VStack(spacing: 8) {
                                        ProfileImage(url: developerProfiles["jkcoxson"] ?? "")
                                            .frame(width: 60, height: 60)
                                        
                                        Text("jkcoxson")
                                            .fontWeight(.semibold)
                                        
                                        Text("idevice & em_proxy")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        if let url = URL(string: "https://jkcoxson.com/") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Collaborators in vertical stack
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Developers")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Vertical stack of collaborators
                                VStack(spacing: 12) {
                                    CollaboratorRow(name: "Stossy11", url: "https://github.com/Stossy11", imageUrl: developerProfiles["Stossy11"] ?? "")
                                    CollaboratorRow(name: "Neo", url: "https://neoarz.xyz/", imageUrl: developerProfiles["Neo"] ?? "")
                                    CollaboratorRow(name: "Se2crid", url: "https://github.com/Se2crid", imageUrl: developerProfiles["Se2crid"] ?? "")
                                    CollaboratorRow(name: "Huge_Black", url: "https://github.com/HugeBlack", imageUrl: developerProfiles["Huge_Black"] ?? "")
                                    CollaboratorRow(name: "Wynwxst", url: "https://github.com/Wynwxst", imageUrl: developerProfiles["Wynwxst"] ?? "")
                                }
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 4)

                    // System Logs card
                    SettingsCard {
                        Button(action: {
                            showingConsoleLogsView = true
                        }) {
                            HStack {
                                Image(systemName: "terminal")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                Text("System Logs")
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 4)
                    .sheet(isPresented: $showingConsoleLogsView) {
                        ConsoleView()
                    }
                    
                    // Version info section
                    HStack {
                        Spacer()
                        
                        Text("Version \(appVersion) • iOS \(UIDevice.current.systemVersion)")
                            .font(.footnote)
                            .foregroundColor(.secondary.opacity(0.8))
                        

                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .fileImporter(
            isPresented: $isShowingPairingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, .propertyList],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
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
                            pairingFileIsValid = false
                        }
                        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                            DispatchQueue.main.async {
                                if importProgress < 1.0 {
                                    importProgress += 0.05
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
                        RunLoop.current.add(progressTimer, forMode: .common)
                        startHeartbeatInBackground()
                    } catch {
                        print("Error copying file: \(error)")
                    }
                } else {
                    print("Source file does not exist.")
                }
                if accessing { url.stopAccessingSecurityScopedResource() }
            case .failure(let error):
                print("Failed to import file: \(error)")
            }
        }
        .onAppear {
            loadCustomBackgroundColor()
        }
    }

    private func loadCustomBackgroundColor() {
        if customBackgroundColorHex.isEmpty {
            selectedBackgroundColor = colorScheme == .dark ? Color.black : Color.white
        } else {
            selectedBackgroundColor = Color(hex: customBackgroundColorHex) ?? (colorScheme == .dark ? Color.black : Color.white)
        }
    }

    private func saveCustomBackgroundColor(_ color: Color) {
        // Always save the custom color if we got here (since auto theme mode is disabled)
        customBackgroundColorHex = color.toHex() ?? ""
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
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// Helper components
struct SettingsCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
    }
}

struct InfoRow: View {
    var title: String
    var value: String
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct LinkRow: View {
    var icon: String
    var title: String
    var url: String
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(alignment: .center) {
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 24) // Added fixed width
            }
        }
        .padding(.vertical, 8)
    }
}

struct CollaboratorGridItem: View {
    var name: String
    var url: String
    var imageUrl: String
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(spacing: 8) {
                ProfileImage(url: imageUrl)
                    .frame(width: 50, height: 50)
                Text(name)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                    .font(.subheadline)
            }
            .frame(minWidth: 80)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct ProfileImage: View {
    var url: String
    @State private var image: UIImage?
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(Color(UIColor.systemGray4))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    private func loadImage() {
        guard let imageUrl = URL(string: url) else { return }
        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            if let data = data, let downloadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = downloadedImage
                }
            }
        }.resume()
    }
}

struct CollaboratorRow: View {
    var name: String
    var url: String
    var imageUrl: String
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                ProfileImage(url: imageUrl)
                    .frame(width: 40, height: 40)
                Text(name)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "link")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
        }
    }
}
