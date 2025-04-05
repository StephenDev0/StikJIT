//
//  LogManager.swift
//  StikJIT
//
//  Created by neoarz on 3/29/25.
//

import Foundation

class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published var logs: [LogEntry] = []
    @Published var errorCount: Int = 0
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: LogType
        let message: String
        
        enum LogType: String {
            case info = "INFO"
            case error = "ERROR"
            case debug = "DEBUG"
            case warning = "WARNING"
        }
    }
    
    private init() {
        // Add initial system info logs
        addInfoLog("StikDebug starting up")
        addInfoLog("Initializing environment")
    }
    
    func addLog(message: String, type: LogEntry.LogType) {
        //clean dumb stuff
        var cleanMessage = message
        
        // Clean up common prefixes that match the log type
        let prefixesToRemove = [
            "Info: ", "INFO: ", "Information: ",
            "Error: ", "ERROR: ", "ERR: ",
            "Debug: ", "DEBUG: ", "DBG: ",
            "Warning: ", "WARN: ", "WARNING: "
        ]
        
        for prefix in prefixesToRemove {
            if cleanMessage.hasPrefix(prefix) {
                cleanMessage = String(cleanMessage.dropFirst(prefix.count))
                break
            }
        }
        
        DispatchQueue.main.async {
            self.logs.append(LogEntry(timestamp: Date(), type: type, message: cleanMessage))
            
            if type == .error {
                self.errorCount += 1
            }
            
            // Keep log size manageable
            if self.logs.count > 1000 {
                self.logs.removeFirst(100)
            }
        }
    }
    
    func addInfoLog(_ message: String) {
        addLog(message: message, type: .info)
    }
    
    func addErrorLog(_ message: String) {
        addLog(message: message, type: .error)
    }
    
    func addDebugLog(_ message: String) {
        addLog(message: message, type: .debug)
    }
    
    func addWarningLog(_ message: String) {
        addLog(message: message, type: .warning)
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.errorCount = 0
        }
    }
} 
