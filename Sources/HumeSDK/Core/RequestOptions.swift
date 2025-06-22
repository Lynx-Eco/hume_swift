import Foundation

/// Options for customizing API requests
public struct RequestOptions: Sendable {
    /// Custom headers to include in the request
    public var headers: [String: String]?
    
    /// Query parameters to append to the URL
    public var queryParameters: [String: String]?
    
    /// Request timeout interval in seconds
    public var timeout: TimeInterval?
    
    /// Maximum number of retry attempts
    public var maxRetries: Int?
    
    /// Custom retry policy
    public var retryPolicy: RetryPolicy?
    
    public init(
        headers: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        timeout: TimeInterval? = nil,
        maxRetries: Int? = nil,
        retryPolicy: RetryPolicy? = nil
    ) {
        self.headers = headers
        self.queryParameters = queryParameters
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.retryPolicy = retryPolicy
    }
    
    /// Merge with another RequestOptions, with the other taking precedence
    public func merged(with other: RequestOptions?) -> RequestOptions {
        guard let other = other else { return self }
        
        var merged = RequestOptions()
        
        // Merge headers
        if let selfHeaders = self.headers, let otherHeaders = other.headers {
            merged.headers = selfHeaders.merging(otherHeaders) { _, new in new }
        } else {
            merged.headers = other.headers ?? self.headers
        }
        
        // Merge query parameters
        if let selfParams = self.queryParameters, let otherParams = other.queryParameters {
            merged.queryParameters = selfParams.merging(otherParams) { _, new in new }
        } else {
            merged.queryParameters = other.queryParameters ?? self.queryParameters
        }
        
        // Take the other's values if present, otherwise use self
        merged.timeout = other.timeout ?? self.timeout
        merged.maxRetries = other.maxRetries ?? self.maxRetries
        merged.retryPolicy = other.retryPolicy ?? self.retryPolicy
        
        return merged
    }
}