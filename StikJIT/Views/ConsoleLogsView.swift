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
                backgroundColor
                VStack(spacing: 0) {
                    logsScrollView
                    Spacer()
                    actionButtons
                        .padding(.bottom, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Center title
                ToolbarItem(placement: .principal) {
                    Text("Console")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                // Leading toolbar items: both Exit and Settings buttons
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button("Exit") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                }
                // Trailing toolbar: Clear logs button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { logManager.clearLogs() }) {
                        Text("Clear")
                            .foregroundColor(.blue)
                    }
                }
            }
            .overlay(customAlert)
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundColor: some View {
        Color(colorScheme == .dark ? .black : .white)
            .edgesIgnoringSafeArea(.all)
    }
    
    private var logsScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    deviceInfoView
                    Spacer()
                    logEntriesView
                }
            }
            .onAppear {
                scrollView = proxy
            }
            .onChange(of: logManager.logs.count) { _ in
                if autoScroll, let lastLog = logManager.logs.last {
                    proxy.scrollTo(lastLog.id, anchor: .bottom)
                }
            }
        }
    }
    
    private var deviceInfoView: some View {
        ForEach([
            "Version: \(UIDevice.current.systemVersion)",
            "Name: \(UIDevice.current.name)",
            "Model: \(UIDevice.current.model)",
            "StikDebug Version: App Version: 1.2"
        ], id: \.self) { info in
            Text("[\(timeString())] ℹ️ \(info)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
        }
    }
    
    private var logEntriesView: some View {
        ForEach(logManager.logs) { logEntry in
            Text(AttributedString(createLogAttributedString(logEntry)))
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 1)
                .padding(.horizontal, 4)
                .id(logEntry.id)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            errorCountView
            buttonsGroup
        }
        .padding(.bottom, 16)
    }
    
    private var errorCountView: some View {
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
    }
    
    private var buttonsGroup: some View {
        VStack(spacing: 1) {
            exportButton
            Divider()
                .background(colorScheme == .dark ?
                            Color(red: 0.15, green: 0.15, blue: 0.15) :
                            Color(UIColor.separator))
            copyButton
        }
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var exportButton: some View {
        Button(action: exportLogs) {
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
    }
    
    private var copyButton: some View {
        Button(action: copyLogs) {
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
    
    private var customAlert: some View {
        Group {
            if showingCustomAlert {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        CustomErrorView(
                            title: alertTitle,
                            message: alertMessage,
                            onDismiss: { showingCustomAlert = false },
                            showButton: true,
                            primaryButtonText: "OK",
                            messageType: isError ? .error : .success
                        )
                    )
            }
        }
    }
    
    // MARK: - Actions
    
    private func exportLogs() {
        var logsContent = "=== DEVICE INFORMATION ===\n"
        logsContent += "Version: \(UIDevice.current.systemVersion)\n"
        logsContent += "Name: \(UIDevice.current.name)\n"
        logsContent += "Model: \(UIDevice.current.model)\n"
        logsContent += "StikDebug Version: App Version: 1.0\n\n"
        logsContent += "=== LOG ENTRIES ===\n"
        logsContent += logManager.logs.map {
            "[\(formatTime(date: $0.timestamp))] [\($0.type.rawValue)] \($0.message)"
        }.joined(separator: "\n")
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let fileURL = documentsDirectory.appendingPathComponent("StikDebug_Logs_\(timestamp).txt")
        
        do {
            try logsContent.write(to: fileURL, atomically: true, encoding: .utf8)
            alertTitle = "Logs Exported"
            alertMessage = "Logs have been saved to Files app in StikDebug folder."
            isError = false
            showingCustomAlert = true
        } catch {
            alertTitle = "Export Failed"
            alertMessage = "Failed to save logs: \(error.localizedDescription)"
            isError = true
            showingCustomAlert = true
        }
    }
    
    private func copyLogs() {
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
    }
    
    // MARK: - Helpers
    
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

