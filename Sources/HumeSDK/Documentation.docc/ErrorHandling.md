# Error Handling

Learn how to handle errors effectively when using the Hume Swift SDK.

## Overview

The Hume SDK uses Swift's error handling mechanism with a comprehensive `HumeError` type that covers all possible error scenarios.

## Error Types

### HumeError

The main error type with the following cases:

```swift
public enum HumeError: Error {
    case invalidURL(String)
    case invalidInput(String)
    case authenticationFailed(String)
    case api(status: Int, message: String, code: String?, body: String?)
    case network(String)
    case decode(String)
    case timeout
    case rateLimit(retryAfter: Int?)
    case websocket(String)
    case unknown(String)
}
```

## Common Error Scenarios

### API Errors

Handle specific API error codes:

```swift
do {
    let response = try await tts.synthesize(request)
} catch let error as HumeError {
    switch error {
    case .api(let status, let message, let code, _):
        switch status {
        case 400:
            print("Bad request: \(message)")
        case 401:
            print("Unauthorized: \(message)")
        case 404:
            print("Not found: \(message)")
        case 422:
            print("Validation error: \(message)")
        default:
            print("API error \(status): \(message)")
        }
    default:
        print("Other error: \(error)")
    }
}
```

### Rate Limiting

Handle rate limit errors with retry logic:

```swift
func synthesizeWithRetry(_ request: TTSRequest) async throws -> TTSResponse {
    do {
        return try await tts.synthesize(request)
    } catch HumeError.rateLimit(let retryAfter) {
        if let retryAfter = retryAfter {
            print("Rate limited. Waiting \(retryAfter) seconds...")
            try await Task.sleep(nanoseconds: UInt64(retryAfter) * 1_000_000_000)
            return try await synthesizeWithRetry(request)
        } else {
            throw HumeError.rateLimit(retryAfter: nil)
        }
    }
}
```

### Network Errors

Handle network-related issues:

```swift
do {
    let voices = try await tts.listVoices()
} catch HumeError.network(let message) {
    print("Network error: \(message)")
    // Implement retry logic or offline fallback
} catch HumeError.timeout {
    print("Request timed out")
    // Consider increasing timeout or retrying
}
```

### WebSocket Errors

Handle WebSocket connection issues:

```swift
do {
    let chat = try await evi.chat().connect()
} catch HumeError.websocket(let message) {
    print("WebSocket error: \(message)")
    // Implement reconnection logic
}
```

## Error Recovery Strategies

### Automatic Retry

The SDK includes automatic retry for transient errors:

```swift
let client = try HumeClient.Builder()
    .apiKey("your-api-key")
    .retryPolicy(RetryPolicy(
        maxRetries: 5,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    ))
    .build()
```

### Manual Retry

Implement custom retry logic:

```swift
func retryOperation<T>(
    maxAttempts: Int = 3,
    delay: TimeInterval = 1.0,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            
            if attempt < maxAttempts {
                print("Attempt \(attempt) failed, retrying...")
                try await Task.sleep(nanoseconds: UInt64(delay * Double(attempt)) * 1_000_000_000)
            }
        }
    }
    
    throw lastError!
}

// Usage
let response = try await retryOperation {
    try await tts.synthesize(request)
}
```

## Error Context

Get detailed error information:

```swift
extension HumeError {
    var isRetryable: Bool {
        switch self {
        case .network, .timeout, .rateLimit:
            return true
        case .api(let status, _, _, _):
            return status >= 500 || status == 429
        default:
            return false
        }
    }
    
    var userMessage: String {
        switch self {
        case .authenticationFailed:
            return "Please check your API credentials"
        case .network:
            return "Please check your internet connection"
        case .timeout:
            return "The request took too long. Please try again"
        case .rateLimit:
            return "Too many requests. Please wait a moment"
        default:
            return "An error occurred. Please try again"
        }
    }
}
```

## Best Practices

1. **Always handle errors** - Don't ignore potential failures
2. **Provide user feedback** - Show meaningful error messages
3. **Log errors** - Keep track of errors for debugging
4. **Implement retry logic** - Handle transient failures gracefully
5. **Fail gracefully** - Provide fallback behavior when possible

## Error Logging

Implement comprehensive error logging:

```swift
import os

let logger = Logger(subsystem: "com.yourapp", category: "HumeSDK")

func logError(_ error: HumeError, context: String) {
    switch error {
    case .api(let status, let message, let code, _):
        logger.error("API error in \(context): status=\(status), code=\(code ?? "none"), message=\(message)")
    case .network(let message):
        logger.error("Network error in \(context): \(message)")
    default:
        logger.error("Error in \(context): \(error)")
    }
}
```

## Testing Error Handling

Write tests for error scenarios:

```swift
func testHandlesRateLimit() async throws {
    // Mock a rate limit response
    let mockClient = MockHumeClient()
    mockClient.mockError = HumeError.rateLimit(retryAfter: 60)
    
    do {
        _ = try await mockClient.tts.synthesize(request)
        XCTFail("Expected rate limit error")
    } catch HumeError.rateLimit(let retryAfter) {
        XCTAssertEqual(retryAfter, 60)
    }
}
```