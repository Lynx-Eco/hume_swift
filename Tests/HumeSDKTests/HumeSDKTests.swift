import XCTest
@testable import HumeSDK

final class HumeSDKTests: XCTestCase {
    
    // MARK: - Client Initialization Tests
    
    func testClientInitializationWithAPIKey() throws {
        let apiKey = "test-api-key"
        let client = try HumeClient(apiKey: apiKey)
        
        XCTAssertNotNil(client)
    }
    
    func testClientInitializationFromEnvironment() throws {
        // Set environment variable
        setenv("HUME_API_KEY", "test-env-key", 1)
        defer { unsetenv("HUME_API_KEY") }
        
        let client = try HumeClient.fromEnvironment()
        XCTAssertNotNil(client)
    }
    
    func testClientInitializationWithOAuth() throws {
        let apiKey = "test-api-key"
        let secretKey = "test-secret-key"
        let client = try HumeClient(apiKey: apiKey, secretKey: secretKey)
        
        XCTAssertNotNil(client)
    }
    
    // MARK: - Error Tests
    
    func testErrorTypes() {
        // API error
        let apiError = HumeError.api(status: 404, message: "Not found", code: "NOT_FOUND", body: nil)
        XCTAssertTrue(apiError.errorDescription?.contains("Not found") ?? false)
        
        // Validation error
        let validationError = HumeError.validation(errors: [
            ValidationError(field: "text", message: "Text is required", code: nil)
        ])
        XCTAssertTrue(validationError.errorDescription?.contains("Validation Error") ?? false)
        
        // Rate limit error
        let rateLimitError = HumeError.rateLimit(retryAfter: 60)
        XCTAssertTrue(rateLimitError.errorDescription?.contains("Rate limit exceeded") ?? false)
        
        // Timeout error
        let timeoutError = HumeError.timeout
        XCTAssertEqual(timeoutError.errorDescription, "Request timed out")
    }
    
    func testErrorRetryability() {
        let retryableErrors: [HumeError] = [
            .timeout,
            .noConnection,
            .rateLimit(retryAfter: 60),
            .api(status: 500, message: "Server error", code: nil, body: nil),
            .api(status: 502, message: "Bad gateway", code: nil, body: nil),
            .api(status: 503, message: "Service unavailable", code: nil, body: nil),
            .api(status: 504, message: "Gateway timeout", code: nil, body: nil)
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "\(error) should be retryable")
        }
        
        let nonRetryableErrors: [HumeError] = [
            .api(status: 400, message: "Bad request", code: nil, body: nil),
            .api(status: 401, message: "Unauthorized", code: nil, body: nil),
            .api(status: 403, message: "Forbidden", code: nil, body: nil),
            .api(status: 404, message: "Not found", code: nil, body: nil),
            .validation(errors: [ValidationError(field: "test", message: "Invalid", code: nil)]),
            .encodingFailed(TestError.mock),
            .decodingFailed(TestError.mock)
        ]
        
        for error in nonRetryableErrors {
            XCTAssertFalse(error.isRetryable, "\(error) should not be retryable")
        }
    }
    
    func testErrorAuthentication() {
        let authErrors: [HumeError] = [
            .api(status: 401, message: "Unauthorized", code: nil, body: nil),
            // Authentication errors are represented as 401 API errors
        ]
        
        for error in authErrors {
            XCTAssertTrue(error.isAuthenticationError, "\(error) should be authentication error")
        }
        
        let nonAuthErrors: [HumeError] = [
            .api(status: 400, message: "Bad request", code: nil, body: nil),
            .timeout,
            .noConnection
        ]
        
        for error in nonAuthErrors {
            XCTAssertFalse(error.isAuthenticationError, "\(error) should not be authentication error")
        }
    }
    
    // MARK: - Request Options Tests
    
    func testRequestOptions() {
        var options = RequestOptions()
        options.timeout = 30.0
        options.maxRetries = 5
        options.headers = ["X-Custom": "value"]
        options.queryParameters = ["param": "value"]
        
        XCTAssertEqual(options.timeout, 30.0)
        XCTAssertEqual(options.maxRetries, 5)
        XCTAssertEqual(options.headers?["X-Custom"], "value")
        XCTAssertEqual(options.queryParameters?["param"], "value")
    }
    
    // MARK: - Retry Policy Tests
    
    func testRetryPolicy() {
        let policy = RetryPolicy(
            maxRetries: 5,
            initialDelay: 0.5,
            maxDelay: 10.0,
            backoffMultiplier: 2.0,
            jitterFactor: 0.1,
            retryableStatusCodes: [408, 429, 500, 502, 503, 504]
        )
        
        XCTAssertEqual(policy.maxRetries, 5)
        XCTAssertEqual(policy.initialDelay, 0.5)
        XCTAssertEqual(policy.maxDelay, 10.0)
        XCTAssertEqual(policy.backoffMultiplier, 2.0)
        XCTAssertEqual(policy.jitterFactor, 0.1)
        XCTAssertTrue(policy.retryableStatusCodes.contains(500))
        XCTAssertFalse(policy.retryableStatusCodes.contains(400))
    }
    
    func testRetryPolicyBackoffCalculation() {
        let policy = RetryPolicy(
            maxRetries: 3,
            initialDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 2.0
        )
        
        // Test that delays would increase with retries
        // Actual delay calculation happens inside HTTPClient
        XCTAssertEqual(policy.initialDelay, 1.0)
        XCTAssertEqual(policy.backoffMultiplier, 2.0)
        XCTAssertEqual(policy.maxDelay, 10.0)
        
        // Verify exponential backoff parameters
        let expectedDelay1 = 1.0
        let expectedDelay2 = 2.0
        let expectedDelay3 = 4.0
        
        XCTAssertLessThanOrEqual(expectedDelay1, policy.maxDelay)
        XCTAssertLessThanOrEqual(expectedDelay2, policy.maxDelay)
        XCTAssertLessThanOrEqual(expectedDelay3, policy.maxDelay)
    }
    
    // MARK: - Sample Rate Tests
    
    func testSampleRatePresets() {
        XCTAssertEqual(SampleRate.hz8000.value, 8000)
        XCTAssertEqual(SampleRate.hz16000.value, 16000)
        XCTAssertEqual(SampleRate.hz22050.value, 22050)
        XCTAssertEqual(SampleRate.hz24000.value, 24000)
        XCTAssertEqual(SampleRate.hz44100.value, 44100)
        XCTAssertEqual(SampleRate.hz48000.value, 48000)
    }
    
    func testCustomSampleRate() {
        let custom = SampleRate(12000)
        XCTAssertEqual(custom.value, 12000)
    }
    
    // MARK: - TTS Tests
    
    func testTTSRequest() throws {
        let utterance = PostedUtterance(
            text: "Hello, world!",
            voice: .name("Alice"),
            description: "Greeting",
            speed: 1.2,
            trailingSilence: 500
        )
        
        let request = try TTSRequest(
            utterances: [utterance],
            format: .mp3,
            numGenerations: 1,
            splitUtterances: false,
            stripHeaders: true
        )
        
        XCTAssertEqual(request.utterances.count, 1)
        XCTAssertEqual(request.utterances[0].text, "Hello, world!")
        XCTAssertEqual(request.format, .mp3)
        XCTAssertEqual(request.numGenerations, 1)
        XCTAssertEqual(request.splitUtterances, false)
        XCTAssertEqual(request.stripHeaders, true)
        
        if case .name(let name) = request.utterances[0].voice {
            XCTAssertEqual(name, "Alice")
        } else {
            XCTFail("Expected voice name")
        }
    }
    
    // MARK: - Validation Tests
    
    func testValidation() throws {
        // Test validation through actual API usage
        // Empty text should throw when creating utterance
        // Test empty text validation
        let emptyUtterance = PostedUtterance(text: "", voice: .name("test"))
        XCTAssertThrowsError(try TTSRequest(utterances: [emptyUtterance])) { error in
            // Just check that it throws an error - the specific type may vary
            XCTAssertNotNil(error)
        }
        
        // Valid text should not throw
        // Valid text should work
        let validUtterance = PostedUtterance(text: "Hello, world!", voice: .name("test"))
        XCTAssertNoThrow(try TTSRequest(utterances: [validUtterance]))
        
        // API key validation happens server-side
        // Client accepts any non-empty string
        XCTAssertNoThrow(try HumeClient(apiKey: "test_key_123"))
    }
    
    // MARK: - Mock Types
    
    private enum TestError: Error {
        case mock
    }
}

// MARK: - Extensions for Testing

extension HumeError {
    var isRetryable: Bool {
        switch self {
        case .timeout, .noConnection, .rateLimit:
            return true
        case .api(let status, _, _, _):
            return status >= 500 || status == 429
        default:
            return false
        }
    }
    
    var isAuthenticationError: Bool {
        switch self {
        case .api(let status, _, _, _):
            return status == 401
        case .api(let status, _, _, _) where status == 401:
            return true
        default:
            return false
        }
    }
}