import XCTest
@testable import HumeSDK

final class HumeSDKTests: XCTestCase {
    
    // MARK: - Authentication Tests
    
    func testAPIKeyAuthentication() throws {
        let apiKey = "test-api-key"
        let client = try HumeClient(apiKey: apiKey)
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.http)
    }
    
    func testAccessTokenAuthentication() throws {
        let accessToken = "test-access-token"
        let client = try HumeClient(accessToken: accessToken)
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.http)
    }
    
    func testOAuth2Authentication() throws {
        let apiKey = "test-api-key"
        let secretKey = "test-secret-key"
        let client = try HumeClient(apiKey: apiKey, secretKey: secretKey)
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.http)
    }
    
    // MARK: - Builder Tests
    
    func testClientBuilder() throws {
        let client = try HumeClient.Builder()
            .apiKey("test-api-key")
            .timeout(30.0)
            .build()
        
        XCTAssertNotNil(client)
        XCTAssertEqual(client.timeout, 30.0)
    }
    
    func testClientBuilderWithCustomURL() throws {
        let customURL = "https://custom.api.hume.ai"
        let client = try HumeClient.Builder()
            .apiKey("test-api-key")
            .baseURL(customURL)
            .build()
        
        XCTAssertNotNil(client)
        XCTAssertEqual(client.baseURL.absoluteString, customURL)
    }
    
    // MARK: - Error Tests
    
    func testErrorRetryability() {
        let retryableErrors: [HumeError] = [
            .api(status: 500, message: "Server error", code: nil, body: nil),
            .api(status: 503, message: "Service unavailable", code: nil, body: nil),
            .timeout,
            .noConnection,
            .rateLimit(retryAfter: 5.0)
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "\(error) should be retryable")
        }
        
        let nonRetryableErrors: [HumeError] = [
            .api(status: 400, message: "Bad request", code: nil, body: nil),
            .api(status: 401, message: "Unauthorized", code: nil, body: nil),
            .missingAPIKey,
            .invalidAPIKey,
            .encodingFailed(NSError(domain: "test", code: 0))
        ]
        
        for error in nonRetryableErrors {
            XCTAssertFalse(error.isRetryable, "\(error) should not be retryable")
        }
    }
    
    func testErrorAuthenticationCheck() {
        let authErrors: [HumeError] = [
            .missingAPIKey,
            .invalidAPIKey,
            .missingAccessToken,
            .invalidAccessToken,
            .authenticationFailed(message: "Auth failed"),
            .api(status: 401, message: "Unauthorized", code: nil, body: nil),
            .api(status: 403, message: "Forbidden", code: nil, body: nil)
        ]
        
        for error in authErrors {
            XCTAssertTrue(error.isAuthenticationError, "\(error) should be an authentication error")
        }
        
        let nonAuthErrors: [HumeError] = [
            .timeout,
            .noConnection,
            .api(status: 500, message: "Server error", code: nil, body: nil)
        ]
        
        for error in nonAuthErrors {
            XCTAssertFalse(error.isAuthenticationError, "\(error) should not be an authentication error")
        }
    }
    
    // MARK: - Retry Policy Tests
    
    func testRetryPolicyDefaults() {
        let policy = RetryPolicy.default
        
        XCTAssertEqual(policy.maxRetries, 3)
        XCTAssertEqual(policy.initialDelay, 0.5)
        XCTAssertEqual(policy.maxDelay, 10.0)
        XCTAssertEqual(policy.backoffMultiplier, 2.0)
    }
    
    func testRetryPolicyDelayCalculation() {
        let policy = RetryPolicy(
            initialDelay: 1.0,
            backoffMultiplier: 2.0,
            jitterFactor: 0.0 // No jitter for predictable testing
        )
        
        XCTAssertEqual(policy.delay(for: 1), 1.0)
        XCTAssertEqual(policy.delay(for: 2), 2.0)
        XCTAssertEqual(policy.delay(for: 3), 4.0)
        XCTAssertEqual(policy.delay(for: 4), 8.0)
    }
    
    func testRetryPolicyMaxDelay() {
        let policy = RetryPolicy(
            initialDelay: 1.0,
            maxDelay: 5.0,
            backoffMultiplier: 10.0,
            jitterFactor: 0.0
        )
        
        // Should be capped at maxDelay
        XCTAssertEqual(policy.delay(for: 3), 5.0)
        XCTAssertEqual(policy.delay(for: 10), 5.0)
    }
    
    // MARK: - Pagination Tests
    
    func testPagedResponseHelpers() {
        let page1 = PagedResponse(
            pageNumber: 0,
            pageSize: 10,
            totalPages: 3,
            totalItems: 25,
            items: Array(repeating: "item", count: 10)
        )
        
        XCTAssertTrue(page1.hasNextPage)
        XCTAssertFalse(page1.hasPreviousPage)
        XCTAssertEqual(page1.nextPageNumber, 1)
        XCTAssertNil(page1.previousPageNumber)
        
        let page2 = PagedResponse(
            pageNumber: 1,
            pageSize: 10,
            totalPages: 3,
            totalItems: 25,
            items: Array(repeating: "item", count: 10)
        )
        
        XCTAssertTrue(page2.hasNextPage)
        XCTAssertTrue(page2.hasPreviousPage)
        XCTAssertEqual(page2.nextPageNumber, 2)
        XCTAssertEqual(page2.previousPageNumber, 0)
        
        let lastPage = PagedResponse(
            pageNumber: 2,
            pageSize: 10,
            totalPages: 3,
            totalItems: 25,
            items: Array(repeating: "item", count: 5)
        )
        
        XCTAssertFalse(lastPage.hasNextPage)
        XCTAssertTrue(lastPage.hasPreviousPage)
        XCTAssertNil(lastPage.nextPageNumber)
        XCTAssertEqual(lastPage.previousPageNumber, 1)
    }
    
    // MARK: - TTS Model Tests
    
    func testSampleRateConstants() {
        XCTAssertEqual(SampleRate.hz8000.value, 8000)
        XCTAssertEqual(SampleRate.hz16000.value, 16000)
        XCTAssertEqual(SampleRate.hz22050.value, 22050)
        XCTAssertEqual(SampleRate.hz24000.value, 24000)
        XCTAssertEqual(SampleRate.hz44100.value, 44100)
        XCTAssertEqual(SampleRate.hz48000.value, 48000)
    }
    
    func testTTSRequestBuilder() {
        let request = TTSRequestBuilder(text: "Hello, world!")
            .voiceName("Alice")
            .sampleRate(.hz44100)
            .speed(1.2)
            .volume(0.8)
            .build()
        
        XCTAssertEqual(request.text, "Hello, world!")
        XCTAssertEqual(request.sampleRate?.value, 44100)
        XCTAssertEqual(request.speed, 1.2)
        XCTAssertEqual(request.volume, 0.8)
        
        if case .name(let name) = request.voice {
            XCTAssertEqual(name, "Alice")
        } else {
            XCTFail("Expected voice name")
        }
    }
    
    // MARK: - Request Options Tests
    
    func testRequestOptionsMerging() {
        let options1 = RequestOptions(
            headers: ["Header1": "Value1"],
            queryParameters: ["param1": "value1"],
            timeout: 10.0
        )
        
        let options2 = RequestOptions(
            headers: ["Header2": "Value2", "Header1": "OverriddenValue"],
            queryParameters: ["param2": "value2"],
            timeout: 20.0
        )
        
        let merged = options1.merged(with: options2)
        
        XCTAssertEqual(merged.headers?["Header1"], "OverriddenValue")
        XCTAssertEqual(merged.headers?["Header2"], "Value2")
        XCTAssertEqual(merged.queryParameters?["param1"], "value1")
        XCTAssertEqual(merged.queryParameters?["param2"], "value2")
        XCTAssertEqual(merged.timeout, 20.0)
    }
    
    // MARK: - Retry After Parser Tests
    
    func testRetryAfterParserSeconds() {
        XCTAssertEqual(RetryAfterParser.parse("120"), 120.0)
        XCTAssertEqual(RetryAfterParser.parse("0"), 0.0)
        XCTAssertEqual(RetryAfterParser.parse("3600"), 3600.0)
    }
    
    func testRetryAfterParserInvalid() {
        XCTAssertNil(RetryAfterParser.parse("invalid"))
        XCTAssertNil(RetryAfterParser.parse(""))
        XCTAssertNil(RetryAfterParser.parse("12.5"))
    }
}

// MARK: - Mock Authentication Provider

class MockAuthenticationProvider: AuthenticationProvider {
    let method: AuthenticationMethod
    
    init(method: AuthenticationMethod) {
        self.method = method
    }
    
    func getAuthentication() async throws -> AuthenticationMethod {
        return method
    }
}