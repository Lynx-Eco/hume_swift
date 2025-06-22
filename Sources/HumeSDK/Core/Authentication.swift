import Foundation

/// Authentication method for Hume API
public enum AuthenticationMethod: Sendable {
    /// API key authentication
    case apiKey(String)
    
    /// OAuth2 access token authentication
    case accessToken(String)
    
    /// Get the authorization header value
    var headerValue: String {
        switch self {
        case .apiKey(let key):
            return key
        case .accessToken(let token):
            return "Bearer \(token)"
        }
    }
    
    /// Get the header field name
    var headerField: String {
        switch self {
        case .apiKey:
            return "X-Hume-Api-Key"
        case .accessToken:
            return "Authorization"
        }
    }
    
    /// Get query parameter for WebSocket authentication
    var queryParameter: URLQueryItem? {
        switch self {
        case .apiKey(let key):
            return URLQueryItem(name: "api_key", value: key)
        case .accessToken(let token):
            return URLQueryItem(name: "access_token", value: token)
        }
    }
}

/// Authentication provider protocol
public protocol AuthenticationProvider: Sendable {
    /// Get the current authentication method
    func getAuthentication() async throws -> AuthenticationMethod
}

/// Simple authentication provider with a static method
public struct StaticAuthenticationProvider: AuthenticationProvider, Sendable {
    private let method: AuthenticationMethod
    
    public init(method: AuthenticationMethod) {
        self.method = method
    }
    
    public func getAuthentication() async throws -> AuthenticationMethod {
        return method
    }
}

/// Access token response from OAuth2 endpoint
public struct AccessTokenResponse: Codable, Sendable {
    public let accessToken: String
    public let expiresIn: Int
    public let tokenType: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

/// OAuth2 authentication provider that can fetch access tokens
public actor OAuth2AuthenticationProvider: AuthenticationProvider {
    private let apiKey: String
    private let secretKey: String
    private let tokenEndpoint: URL
    
    private var currentToken: String?
    private var tokenExpiry: Date?
    
    public init(apiKey: String, secretKey: String, tokenEndpoint: URL? = nil) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.tokenEndpoint = tokenEndpoint ?? URL(string: "https://api.hume.ai/oauth2-cc/token")!
    }
    
    public func getAuthentication() async throws -> AuthenticationMethod {
        // Check if we have a valid token
        if let token = currentToken, let expiry = tokenExpiry, expiry > Date() {
            return .accessToken(token)
        }
        
        // Fetch new token
        let newToken = try await fetchAccessToken()
        return .accessToken(newToken)
    }
    
    private func fetchAccessToken() async throws -> String {
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let parameters = [
            "grant_type": "client_credentials",
            "client_id": apiKey,
            "client_secret": secretKey
        ]
        
        let bodyString = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HumeError.invalidResponse(message: "Invalid response type")
        }
        
        if httpResponse.statusCode != 200 {
            throw HumeError.authenticationFailed(message: "Failed to fetch access token: \(httpResponse.statusCode)")
        }
        
        // Parse response
        let decoder = JSONDecoder()
        let tokenResponse = try decoder.decode(AccessTokenResponse.self, from: data)
        
        // Store token and expiry
        currentToken = tokenResponse.accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60)) // Subtract 60 seconds for safety
        
        return tokenResponse.accessToken
    }
    
    /// Invalidate the current token
    public func invalidateToken() {
        currentToken = nil
        tokenExpiry = nil
    }
}

/// Authentication configuration
public struct AuthenticationConfig: Sendable {
    public let provider: AuthenticationProvider
    
    public init(provider: AuthenticationProvider) {
        self.provider = provider
    }
    
    public init(apiKey: String) {
        self.provider = StaticAuthenticationProvider(method: .apiKey(apiKey))
    }
    
    public init(accessToken: String) {
        self.provider = StaticAuthenticationProvider(method: .accessToken(accessToken))
    }
    
    public init(apiKey: String, secretKey: String) {
        self.provider = OAuth2AuthenticationProvider(apiKey: apiKey, secretKey: secretKey)
    }
}