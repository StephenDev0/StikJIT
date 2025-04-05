//
//  ConsoleLogsView.swift
//  StikJIT
//
//  Created by neoarz on 3/29/25.
//

import SwiftUI
import UIKit

struct ConsoleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var logManager = LogManager.shared
    @State private var autoScroll = true
    @State private var scrollView: ScrollViewProxy? = nil
    
    // Alert handling
    @State private var showingCustomAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Use system background color instead of fixed black
                Color(colorScheme == .dark ? .black : .white)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Terminal logs area with theme support
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                // Device Information
                                ForEach(["Version: \(UIDevice.current.systemVersion)",
                                         "Name: \(UIDevice.current.name)",
                                         "Model: \(UIDevice.current.model)",
                                         "StikDebug Version: App Version: 1.0"], id: \.self) { info in
                                    Text("[\(timeString())] ℹ️ \(info)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 4)
                                }
                                
                                Spacer()
                                
                                // Log entries 
                                ForEach(logManager.logs) { logEntry in
                                    Text(AttributedString(createLogAttributedString(logEntry)))
                                        .font(.system(size: 11, design: .monospaced))
                                        .textSelection(.enabled)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 1)
                                        .padding(.horizontal, 4)
                                        .id(logEntry.id)
                                }
                            }
                        }
                        .onAppear {
                            scrollView = proxy
                        }
                        .onChange(of: logManager.logs.count) {
                            if autoScroll, let lastLog = logManager.logs.last {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons section - update to be theme aware
                    VStack(spacing: 16) {
                        // Error count with red theme
                        HStack {
                            Text("\(logManager.errorCount) Errors")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Action buttons with theme-appropriate background
                        VStack(spacing: 1) {
                            // Export button
                            Button(action: {
                                // Create logs content with device information
                                var logsContent = "=== DEVICE INFORMATION ===\n"
                                logsContent += "Version: \(UIDevice.current.systemVersion)\n"
                                logsContent += "Name: \(UIDevice.current.name)\n" 
                                logsContent += "Model: \(UIDevice.current.model)\n"
                                logsContent += "StikDebug Version: App Version: 1.0\n\n"
                                logsContent += "=== LOG ENTRIES ===\n"
                                
                                // Add all log entries with proper formatting
                                logsContent += logManager.logs.map { 
                                    "[\(formatTime(date: $0.timestamp))] [\($0.type.rawValue)] \($0.message)" 
                                }.joined(separator: "\n")
                                
                                // Save to document directory (accessible in Files app)
                                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                                let timestamp = dateFormatter.string(from: Date())
                                let fileURL = documentsDirectory.appendingPathComponent("StikDebug_Logs_\(timestamp).txt")
                                
                                do {
                                    // Write the logs to the file
                                    try logsContent.write(to: fileURL, atomically: true, encoding: .utf8)
                                    
                                    // Set alert variables and show the alert
                                    alertTitle = "Logs Exported"
                                    alertMessage = "Logs have been saved to Files app in StikDebug folder."
                                    isError = false
                                    showingCustomAlert = true
                                } catch {
                                    // Set error alert variables and show the alert
                                    alertTitle = "Export Failed"
                                    alertMessage = "Failed to save logs: \(error.localizedDescription)"
                                    isError = true
                                    showingCustomAlert = true
                                }
                            }) {
                                HStack {
                                    Text("Export Logs")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "square.and.arrow.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .contentShape(Rectangle())
                            }
                            .background(colorScheme == .dark ? 
                                Color(red: 0.1, green: 0.1, blue: 0.1) : 
                                Color(UIColor.secondarySystemBackground))
                            
                            Divider()
                                .background(colorScheme == .dark ? 
                                    Color(red: 0.15, green: 0.15, blue: 0.15) : 
                                    Color(UIColor.separator))
                            
                            // Copy button
                            Button(action: {
                                // Existing code for copying logs
                                var logsContent = "=== DEVICE INFORMATION ===\n"
                                logsContent += "Version: \(UIDevice.current.systemVersion)\n"
                                logsContent += "Name: \(UIDevice.current.name)\n" 
                                logsContent += "Model: \(UIDevice.current.model)\n"
                                logsContent += "StikDebug Version: App Version: 1.0\n\n"
                                logsContent += "=== LOG ENTRIES ===\n"
                                
                                logsContent += logManager.logs.map { 
                                    "[\(formatTime(date: $0.timestamp))] [\($0.type.rawValue)] \($0.message)" 
                                }.joined(separator: "\n")
                                
                                UIPasteboard.general.string = logsContent
                                
                                alertTitle = "Logs Copied"
                                alertMessage = "Logs have been copied to clipboard."
                                isError = false
                                showingCustomAlert = true
                            }) {
                                HStack {
                                    Text("Copy Logs")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .contentShape(Rectangle())
                            }
                            .background(colorScheme == .dark ? 
                                Color(red: 0.1, green: 0.1, blue: 0.1) : 
                                Color(UIColor.secondarySystemBackground))
                        }
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .padding(.bottom, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Console")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 2) {
                            Text("Exit")
                                .fontWeight(.regular)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Settings")
                                    .fontWeight(.regular)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            logManager.clearLogs()
                        }) {
                            Text("Clear")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .overlay(
                Group {
                    if showingCustomAlert {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                            .overlay(
                                CustomErrorView(
                                    title: alertTitle,
                                    message: alertMessage,
                                    onDismiss: {
                                        showingCustomAlert = false
                                    },
                                    showButton: true,
                                    primaryButtonText: "OK",
                                    messageType: isError ? .error : .success
                                )
                            )
                    }
                }
            )
        }
    }
    
    // Update to use theme-aware colors
    private func createLogAttributedString(_ logEntry: LogManager.LogEntry) -> NSAttributedString {
        let fullString = NSMutableAttributedString()
        
        // Timestamp part
        let timestampString = "[\(formatTime(date: logEntry.timestamp))]"
        let timestampAttr = NSAttributedString(
            string: timestampString,
            attributes: [.foregroundColor: colorScheme == .dark ? UIColor.gray : UIColor.darkGray]
        )
        fullString.append(timestampAttr)
        fullString.append(NSAttributedString(string: " "))
        
        // Log type part
        let typeString = "[\(logEntry.type.rawValue)]"
        let typeColor = UIColor(colorForLogType(logEntry.type))
        let typeAttr = NSAttributedString(
            string: typeString,
            attributes: [.foregroundColor: typeColor]
        )
        fullString.append(typeAttr)
        fullString.append(NSAttributedString(string: " "))
        
        // Message part
        let messageAttr = NSAttributedString(
            string: logEntry.message,
            attributes: [.foregroundColor: colorScheme == .dark ? UIColor.white : UIColor.black]
        )
        fullString.append(messageAttr)
        
        return fullString
    }
    
    private func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func colorForLogType(_ type: LogManager.LogEntry.LogType) -> Color {
        switch type {
        case .info:
            return .green
        case .error:
            return .red
        case .debug:
            return .blue
        case .warning:
            return .orange
        }
    }
}

struct ConsoleView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleView()
    }
} 
