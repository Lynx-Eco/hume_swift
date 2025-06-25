import Foundation

/// Main client for interacting with Hume AI APIs
public class HumeClient {
    // MARK: - Properties
    
    /// HTTP client for API requests
    public let http: HTTPClient
    
    /// Authentication configuration
    public let auth: AuthenticationConfig
    
    /// Base URL for API requests
    public let baseURL: URL
    
    /// Default timeout for requests
    public let timeout: TimeInterval
    
    /// Default retry policy
    public let retryPolicy: RetryPolicy
    
    /// URL session for requests
    public let session: URLSession
    
    // MARK: - Initialization
    
    /// Initialize with API key
    public convenience init(apiKey: String) throws {
        self.init(auth: AuthenticationConfig(apiKey: apiKey))
    }
    
    /// Initialize with access token
    public convenience init(accessToken: String) throws {
        self.init(auth: AuthenticationConfig(accessToken: accessToken))
    }
    
    /// Initialize with API key and secret key for OAuth2
    public convenience init(apiKey: String, secretKey: String) throws {
        self.init(auth: AuthenticationConfig(apiKey: apiKey, secretKey: secretKey))
    }
    
    /// Initialize with authentication configuration
    public init(
        auth: AuthenticationConfig,
        baseURL: URL? = nil,
        timeout: TimeInterval = 60.0,
        retryPolicy: RetryPolicy = .default,
        session: URLSession? = nil
    ) {
        self.auth = auth
        self.baseURL = baseURL ?? URL(string: "https://api.hume.ai")!
        self.timeout = timeout
        self.retryPolicy = retryPolicy
        self.session = session ?? .shared
        
        self.http = HTTPClient(
            baseURL: self.baseURL,
            authProvider: auth.provider,
            timeout: timeout,
            retryPolicy: retryPolicy,
            session: self.session
        )
    }
    
    // MARK: - Builder Pattern
    
    /// Builder for creating HumeClient instances
    public class Builder {
        private var auth: AuthenticationConfig?
        private var baseURL: URL?
        private var timeout: TimeInterval = 60.0
        private var retryPolicy: RetryPolicy = .default
        private var session: URLSession?
        
        public init() {}
        
        /// Set API key authentication
        @discardableResult
        public func apiKey(_ key: String) -> Builder {
            self.auth = AuthenticationConfig(apiKey: key)
            return self
        }
        
        /// Set access token authentication
        @discardableResult
        public func accessToken(_ token: String) -> Builder {
            self.auth = AuthenticationConfig(accessToken: token)
            return self
        }
        
        /// Set OAuth2 authentication with API key and secret
        @discardableResult
        public func oauth2(apiKey: String, secretKey: String) -> Builder {
            self.auth = AuthenticationConfig(apiKey: apiKey, secretKey: secretKey)
            return self
        }
        
        /// Set custom authentication provider
        @discardableResult
        public func authProvider(_ provider: AuthenticationProvider) -> Builder {
            self.auth = AuthenticationConfig(provider: provider)
            return self
        }
        
        /// Set base URL
        @discardableResult
        public func baseURL(_ url: URL) -> Builder {
            self.baseURL = url
            return self
        }
        
        /// Set base URL from string
        @discardableResult
        public func baseURL(_ urlString: String) throws -> Builder {
            guard let url = URL(string: urlString) else {
                throw HumeError.invalidURL(url: urlString)
            }
            self.baseURL = url
            return self
        }
        
        /// Set request timeout
        @discardableResult
        public func timeout(_ timeout: TimeInterval) -> Builder {
            self.timeout = timeout
            return self
        }
        
        /// Set retry policy
        @discardableResult
        public func retryPolicy(_ policy: RetryPolicy) -> Builder {
            self.retryPolicy = policy
            return self
        }
        
        /// Set URL session
        @discardableResult
        public func session(_ session: URLSession) -> Builder {
            self.session = session
            return self
        }
        
        /// Build the client
        public func build() throws -> HumeClient {
            guard let auth = auth else {
                throw HumeError.missingAPIKey
            }
            
            return HumeClient(
                auth: auth,
                baseURL: baseURL,
                timeout: timeout,
                retryPolicy: retryPolicy,
                session: session
            )
        }
    }
}

// MARK: - Environment Variables Support

public extension HumeClient {
    /// Create client from environment variables
    /// Looks for HUME_API_KEY, HUME_SECRET_KEY, and HUME_BASE_URL
    static func fromEnvironment() throws -> HumeClient {
        let env = ProcessInfo.processInfo.environment
        
        guard let apiKey = env["HUME_API_KEY"] else {
            throw HumeError.missingAPIKey
        }
        
        let builder = Builder().apiKey(apiKey)
        
        // Check for secret key for OAuth2
        if let secretKey = env["HUME_SECRET_KEY"] {
            builder.oauth2(apiKey: apiKey, secretKey: secretKey)
        }
        
        // Check for custom base URL
        if let baseURLString = env["HUME_BASE_URL"] {
            try builder.baseURL(baseURLString)
        }
        
        return try builder.build()
    }
}

// MARK: - Internal Access

extension HumeClient {
    /// Get the base URL (for internal use)
    internal func getBaseURL() -> String {
        return baseURL.absoluteString
    }
    
    /// Get the authentication provider (for internal use)
    internal func getAuthProvider() -> AuthenticationProvider {
        return auth.provider
    }
    
    /// Build a full URL for the given path (for internal use)
    internal func buildURL(path: String) throws -> URL {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw HumeError.invalidURL(url: path)
        }
        return url
    }
}