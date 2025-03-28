//
//  InstalledAppsListView.swift
//  StikJIT
//
//  Created by Stossy11 on 28/03/2025.
//

import SwiftUI

struct InstalledAppsListView: View {
    @StateObject private var viewModel = InstalledAppsViewModel()
    @State private var appIcons: [String: UIImage] = [:]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var onSelectApp: (String) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.apps.sorted(by: { $0.key < $1.key }), id: \.key) { bundleID, appName in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                onSelectApp(bundleID)
                            }
                        }) {
                            HStack(spacing: 16) {
                                // App Icon
                                if let image = appIcons[bundleID] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(12)
                                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.gray.opacity(0.2), 
                                                radius: 3, x: 0, y: 1)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemGray5))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "app")
                                                .font(.system(size: 26))
                                                .foregroundColor(.gray)
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        .onAppear {
                                            loadAppIcon(for: bundleID)
                                        }
                                }
                                
                                // App Name and Bundle ID
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color.blue)
                                    
                                    Text(bundleID)
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.gray)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if appName != viewModel.apps.sorted(by: { $0.key < $1.key }).last?.key {
                            Divider()
                                .padding(.leading, 96)
                                .padding(.trailing, 20)
                                .opacity(0.4)
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Installed Apps")
            .navigationBarItems(leading: Button("Done") {
                dismiss()
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(.blue))
        }
    }
    
    // Helper method to load app icon
    private func loadAppIcon(for bundleID: String) {
        AppStoreIconFetcher.getIcon(for: bundleID) { image in
            if let image = image {
                DispatchQueue.main.async {
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.appIcons[bundleID] = image
                    }
                }
            }
        }
    }
}

#Preview {
    InstalledAppsListView { _ in }
}
