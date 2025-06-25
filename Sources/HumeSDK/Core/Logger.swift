import Foundation
import os

/// Internal logger for HumeSDK
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
internal struct Logger {
    private static let subsystem = "ai.hume.sdk"
    
    private static let core = os.Logger(subsystem: subsystem, category: "core")
    private static let network = os.Logger(subsystem: subsystem, category: "network")
    private static let websocket = os.Logger(subsystem: subsystem, category: "websocket")
    private static let audio = os.Logger(subsystem: subsystem, category: "audio")
    
    // MARK: - Core Logging
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        core.debug("\(message, privacy: .public) [\(file.split(separator: "/").last ?? ""):\(line)]")
        #endif
    }
    
    static func info(_ message: String) {
        core.info("\(message, privacy: .public)")
    }
    
    static func warning(_ message: String) {
        core.warning("\(message, privacy: .public)")
    }
    
    static func error(_ message: String, error: Error? = nil) {
        if let error = error {
            core.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            core.error("\(message, privacy: .public)")
        }
    }
    
    // MARK: - Network Logging
    
    static func networkRequest(method: String, url: String, headers: [String: String]? = nil) {
        #if DEBUG
        var message = "→ \(method) \(url)"
        if let headers = headers {
            let safeHeaders = headers.mapValues { value in
                // Redact sensitive headers
                if value.count > 20 {
                    return String(value.prefix(10)) + "..." + String(value.suffix(5))
                }
                return value
            }
            message += " Headers: \(safeHeaders)"
        }
        network.debug("\(message, privacy: .public)")
        #endif
    }
    
    static func networkResponse(url: String, statusCode: Int, duration: TimeInterval) {
        #if DEBUG
        network.debug("← \(statusCode) \(url) (\(String(format: "%.2f", duration))s)")
        #endif
    }
    
    static func networkError(url: String, error: Error) {
        network.error("✗ Network error for \(url, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
    
    // MARK: - WebSocket Logging
    
    static func websocketConnecting(url: String) {
        websocket.info("🔌 Connecting to \(url, privacy: .public)")
    }
    
    static func websocketConnected(url: String) {
        websocket.info("✅ Connected to \(url, privacy: .public)")
    }
    
    static func websocketDisconnected(url: String, reason: String? = nil) {
        if let reason = reason {
            websocket.info("🔌 Disconnected from \(url, privacy: .public): \(reason, privacy: .public)")
        } else {
            websocket.info("🔌 Disconnected from \(url, privacy: .public)")
        }
    }
    
    static func websocketMessage(direction: MessageDirection, type: String, size: Int? = nil) {
        #if DEBUG
        var message = "\(direction.rawValue) \(type)"
        if let size = size {
            message += " (\(size) bytes)"
        }
        websocket.debug("\(message, privacy: .public)")
        #endif
    }
    
    static func websocketError(error: Error) {
        websocket.error("WebSocket error: \(error.localizedDescription, privacy: .public)")
    }
    
    // MARK: - Audio Logging
    
    static func audioProcessing(action: String, format: String? = nil, duration: TimeInterval? = nil) {
        #if DEBUG
        var message = "🎵 \(action)"
        if let format = format {
            message += " [\(format)]"
        }
        if let duration = duration {
            message += " (\(String(format: "%.2f", duration))s)"
        }
        audio.debug("\(message, privacy: .public)")
        #endif
    }
    
    // MARK: - Supporting Types
    
    enum MessageDirection: String {
        case sent = "→"
        case received = "←"
    }
}

// MARK: - Fallback for older OS versions

@available(macOS, deprecated: 11.0)
@available(iOS, deprecated: 14.0)
@available(tvOS, deprecated: 14.0)
@available(watchOS, deprecated: 7.0)
internal struct LegacyLogger {
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        print("[DEBUG] \(message) [\(file.split(separator: "/").last ?? ""):\(line)]")
        #endif
    }
    
    static func info(_ message: String) {
        print("[INFO] \(message)")
    }
    
    static func warning(_ message: String) {
        print("[WARNING] \(message)")
    }
    
    static func error(_ message: String, error: Error? = nil) {
        if let error = error {
            print("[ERROR] \(message): \(error.localizedDescription)")
        } else {
            print("[ERROR] \(message)")
        }
    }
}

// MARK: - Convenience wrapper

internal func HumeLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
        Logger.debug(items.map { "\($0)" }.joined(separator: separator))
    } else {
        LegacyLogger.debug(items.map { "\($0)" }.joined(separator: separator))
    }
    #endif
}