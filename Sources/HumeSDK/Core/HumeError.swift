import Foundation

/// Comprehensive error types for the Hume SDK
public enum HumeError: LocalizedError, CustomStringConvertible {
    // MARK: - API Errors
    
    /// API error with status code and details
    case api(status: Int, message: String, code: String?, body: String?)
    
    /// Validation error from the API
    case validation(errors: [ValidationError])
    
    /// Rate limit exceeded
    case rateLimit(retryAfter: TimeInterval?)
    
    // MARK: - Network Errors
    
    /// HTTP request failed
    case http(Error)
    
    /// Connection timeout
    case timeout
    
    /// No internet connection
    case noConnection
    
    // MARK: - WebSocket Errors
    
    /// WebSocket connection failed
    case webSocketConnection(Error)
    
    /// WebSocket message send failed
    case webSocketSend(Error)
    
    /// WebSocket unexpectedly disconnected
    case webSocketDisconnected(reason: String?)
    
    /// WebSocket protocol error
    case webSocketProtocol(message: String)
    
    // MARK: - Data Errors
    
    /// JSON encoding failed
    case encodingFailed(Error)
    
    /// JSON decoding failed
    case decodingFailed(Error)
    
    /// Invalid response format
    case invalidResponse(message: String)
    
    /// Base64 decoding failed
    case base64DecodingFailed
    
    // MARK: - Authentication Errors
    
    /// Missing API key
    case missingAPIKey
    
    /// Invalid API key
    case invalidAPIKey
    
    /// Missing access token
    case missingAccessToken
    
    /// Invalid or expired access token
    case invalidAccessToken
    
    /// Authentication failed
    case authenticationFailed(message: String)
    
    // MARK: - Configuration Errors
    
    /// Invalid configuration
    case invalidConfiguration(message: String)
    
    /// Invalid URL
    case invalidURL(url: String)
    
    /// Missing required parameter
    case missingParameter(parameter: String)
    
    /// Invalid parameter value
    case invalidParameter(parameter: String, message: String)
    
    // MARK: - File Errors
    
    /// File not found
    case fileNotFound(path: String)
    
    /// File read error
    case fileReadError(Error)
    
    /// File write error
    case fileWriteError(Error)
    
    // MARK: - Audio Errors
    
    /// Audio format not supported
    case unsupportedAudioFormat(format: String)
    
    /// Audio processing failed
    case audioProcessingFailed(Error)
    
    // MARK: - Other Errors
    
    /// Operation cancelled
    case cancelled
    
    /// Unknown error
    case unknown(Error)
    
    /// Custom error with message
    case custom(message: String)
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        switch self {
        case .api(let status, let message, let code, let body):
            var desc = "API Error (\(status)): \(message)"
            if let code = code {
                desc += " [Code: \(code)]"
            }
            if let body = body {
                desc += "\nBody: \(body)"
            }
            return desc
            
        case .validation(let errors):
            let errorMessages = errors.map { $0.description }.joined(separator: "\n")
            return "Validation Error:\n\(errorMessages)"
            
        case .rateLimit(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Retry after \(retryAfter) seconds"
            }
            return "Rate limit exceeded"
            
        case .http(let error):
            return "HTTP Error: \(error.localizedDescription)"
            
        case .timeout:
            return "Request timed out"
            
        case .noConnection:
            return "No internet connection"
            
        case .webSocketConnection(let error):
            return "WebSocket connection failed: \(error.localizedDescription)"
            
        case .webSocketSend(let error):
            return "WebSocket send failed: \(error.localizedDescription)"
            
        case .webSocketDisconnected(let reason):
            if let reason = reason {
                return "WebSocket disconnected: \(reason)"
            }
            return "WebSocket disconnected unexpectedly"
            
        case .webSocketProtocol(let message):
            return "WebSocket protocol error: \(message)"
            
        case .encodingFailed(let error):
            return "Encoding failed: \(error.localizedDescription)"
            
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
            
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
            
        case .base64DecodingFailed:
            return "Base64 decoding failed"
            
        case .missingAPIKey:
            return "API key is required but not provided"
            
        case .invalidAPIKey:
            return "Invalid API key"
            
        case .missingAccessToken:
            return "Access token is required but not provided"
            
        case .invalidAccessToken:
            return "Invalid or expired access token"
            
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
            
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
            
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
            
        case .missingParameter(let parameter):
            return "Missing required parameter: \(parameter)"
            
        case .invalidParameter(let parameter, let message):
            return "Invalid parameter '\(parameter)': \(message)"
            
        case .fileNotFound(let path):
            return "File not found: \(path)"
            
        case .fileReadError(let error):
            return "File read error: \(error.localizedDescription)"
            
        case .fileWriteError(let error):
            return "File write error: \(error.localizedDescription)"
            
        case .unsupportedAudioFormat(let format):
            return "Unsupported audio format: \(format)"
            
        case .audioProcessingFailed(let error):
            return "Audio processing failed: \(error.localizedDescription)"
            
        case .cancelled:
            return "Operation cancelled"
            
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
            
        case .custom(let message):
            return message
        }
    }
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        return description
    }
    
    // MARK: - Helper Methods
    
    /// Check if error is retryable
    public var isRetryable: Bool {
        switch self {
        case .api(let status, _, _, _):
            return status >= 500 || status == 408 || status == 409 || status == 429
        case .timeout, .noConnection, .webSocketDisconnected:
            return true
        case .rateLimit:
            return true
        default:
            return false
        }
    }
    
    /// Get retry delay if applicable
    public var retryDelay: TimeInterval? {
        switch self {
        case .rateLimit(let retryAfter):
            return retryAfter
        default:
            return nil
        }
    }
    
    /// Check if error is an authentication error
    public var isAuthenticationError: Bool {
        switch self {
        case .missingAPIKey, .invalidAPIKey, .missingAccessToken, .invalidAccessToken, .authenticationFailed:
            return true
        case .api(let status, _, _, _):
            return status == 401 || status == 403
        default:
            return false
        }
    }
}

/// Validation error details
public struct ValidationError: Codable, CustomStringConvertible, Sendable {
    public let field: String?
    public let message: String
    public let code: String?
    
    public var description: String {
        if let field = field {
            return "[\(field)] \(message)"
        }
        return message
    }
}

/// API error response
public struct APIErrorResponse: Codable, Sendable {
    public let message: String?
    public let code: String?
    public let errors: [ValidationError]?
    public let detail: String?
}