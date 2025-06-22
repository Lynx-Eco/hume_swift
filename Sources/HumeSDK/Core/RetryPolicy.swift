import Foundation

/// Retry policy configuration
public struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts
    public let maxRetries: Int
    
    /// Initial delay before first retry (in seconds)
    public let initialDelay: TimeInterval
    
    /// Maximum delay between retries (in seconds)
    public let maxDelay: TimeInterval
    
    /// Maximum total elapsed time for all retries (in seconds)
    public let maxElapsedTime: TimeInterval
    
    /// Multiplier for exponential backoff
    public let backoffMultiplier: Double
    
    /// Jitter factor (0.0 to 1.0)
    public let jitterFactor: Double
    
    /// Status codes that should trigger a retry
    public let retryableStatusCodes: Set<Int>
    
    /// Whether to retry on connection errors
    public let retryOnConnectionError: Bool
    
    public init(
        maxRetries: Int = 3,
        initialDelay: TimeInterval = 0.5,
        maxDelay: TimeInterval = 10.0,
        maxElapsedTime: TimeInterval = 60.0,
        backoffMultiplier: Double = 2.0,
        jitterFactor: Double = 0.1,
        retryableStatusCodes: Set<Int> = [408, 409, 429, 500, 502, 503, 504],
        retryOnConnectionError: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.maxElapsedTime = maxElapsedTime
        self.backoffMultiplier = backoffMultiplier
        self.jitterFactor = jitterFactor
        self.retryableStatusCodes = retryableStatusCodes
        self.retryOnConnectionError = retryOnConnectionError
    }
    
    /// Default retry policy matching Python SDK behavior
    public static let `default` = RetryPolicy()
    
    /// No retry policy
    public static let none = RetryPolicy(maxRetries: 0)
    
    /// Calculate delay for a given retry attempt
    public func delay(for attempt: Int) -> TimeInterval {
        // Base delay with exponential backoff
        let baseDelay = initialDelay * pow(backoffMultiplier, Double(attempt - 1))
        
        // Apply max delay cap
        let cappedDelay = min(baseDelay, maxDelay)
        
        // Add jitter
        let jitter = cappedDelay * jitterFactor * Double.random(in: -1...1)
        let delayWithJitter = cappedDelay + jitter
        
        return max(0, delayWithJitter)
    }
    
    /// Check if a status code is retryable
    public func isRetryable(statusCode: Int) -> Bool {
        return retryableStatusCodes.contains(statusCode)
    }
    
    /// Check if an error is retryable
    public func isRetryable(error: Error) -> Bool {
        if let humeError = error as? HumeError {
            return humeError.isRetryable
        }
        
        // Check for common connection errors
        if retryOnConnectionError {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut,
                     NSURLErrorCannotFindHost,
                     NSURLErrorCannotConnectToHost,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorDNSLookupFailed,
                     NSURLErrorNotConnectedToInternet:
                    return true
                default:
                    break
                }
            }
        }
        
        return false
    }
}

/// Retry state tracker
public struct RetryState: Sendable {
    public let attempt: Int
    public let startTime: Date
    public let lastError: Error?
    
    public init(attempt: Int = 0, startTime: Date = Date(), lastError: Error? = nil) {
        self.attempt = attempt
        self.startTime = startTime
        self.lastError = lastError
    }
    
    public var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    public func shouldRetry(with policy: RetryPolicy) -> Bool {
        // Check max retries
        if attempt >= policy.maxRetries {
            return false
        }
        
        // Check max elapsed time
        if elapsedTime >= policy.maxElapsedTime {
            return false
        }
        
        // Check if error is retryable
        if let error = lastError, !policy.isRetryable(error: error) {
            return false
        }
        
        return true
    }
    
    public func nextAttempt(with error: Error) -> RetryState {
        return RetryState(
            attempt: attempt + 1,
            startTime: startTime,
            lastError: error
        )
    }
}

/// Retry-After header parser
public struct RetryAfterParser {
    /// Parse Retry-After header value
    /// Can be either a delay in seconds or an HTTP date
    public static func parse(_ value: String) -> TimeInterval? {
        // Try to parse as seconds first
        if let seconds = Int(value) {
            return TimeInterval(seconds)
        }
        
        // Try to parse as HTTP date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        
        // Try RFC 1123 format
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        if let date = dateFormatter.date(from: value) {
            return max(0, date.timeIntervalSinceNow)
        }
        
        // Try RFC 850 format
        dateFormatter.dateFormat = "EEEE, dd-MMM-yy HH:mm:ss zzz"
        if let date = dateFormatter.date(from: value) {
            return max(0, date.timeIntervalSinceNow)
        }
        
        // Try ANSI C format
        dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        if let date = dateFormatter.date(from: value) {
            return max(0, date.timeIntervalSinceNow)
        }
        
        return nil
    }
}