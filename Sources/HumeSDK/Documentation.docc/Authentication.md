# Authentication

Learn about the different authentication methods supported by the Hume Swift SDK.

## Overview

The Hume SDK supports three authentication methods:

1. **API Key** - Simple authentication using your Hume API key
2. **OAuth2** - Automatic token management using API key and secret key
3. **Access Token** - Direct access token usage for advanced scenarios

## API Key Authentication

The simplest way to authenticate is using your API key:

```swift
let client = try HumeClient(apiKey: "your-api-key-here")
```

### Using Environment Variables

For better security, store your API key in an environment variable:

```bash
export HUME_API_KEY="your-api-key-here"
```

Then create the client without parameters:

```swift
let client = try HumeClient()
```

## OAuth2 Authentication

For applications that need long-lived sessions, use OAuth2 authentication:

```swift
// The SDK will automatically manage token refresh
let client = try HumeClient(
    apiKey: "your-api-key",
    secretKey: "your-secret-key"
)
```

The SDK will:
- Automatically fetch access tokens
- Refresh tokens before they expire
- Retry requests with new tokens if needed

### Environment Variables for OAuth2

```bash
export HUME_API_KEY="your-api-key"
export HUME_SECRET_KEY="your-secret-key"
```

## Access Token Authentication

If you're managing tokens yourself, you can provide an access token directly:

```swift
let auth = Auth.accessToken(
    AccessToken(
        accessToken: "your-access-token",
        expiresAt: Date().addingTimeInterval(3600)
    )
)

let client = try HumeClient(auth: auth)
```

## Advanced Authentication

### Custom Authentication

Create a client with custom authentication:

```swift
let client = try HumeClient.Builder()
    .auth(.apiKey("your-api-key"))
    .baseURL("https://custom.api.hume.ai")
    .timeout(30.0)
    .build()
```

### Switching Authentication Methods

You can create multiple clients with different authentication:

```swift
// Client for public operations
let publicClient = try HumeClient(apiKey: "public-api-key")

// Client for admin operations
let adminClient = try HumeClient(
    apiKey: "admin-api-key",
    secretKey: "admin-secret-key"
)
```

## Security Best Practices

1. **Never hardcode credentials** - Use environment variables or secure storage
2. **Use OAuth2 for production** - It provides better security with rotating tokens
3. **Limit API key scope** - Create keys with minimal required permissions
4. **Rotate keys regularly** - Update your API keys periodically
5. **Use HTTPS only** - The SDK enforces HTTPS for all requests

## Error Handling

Authentication errors are returned as `HumeError.authenticationFailed`:

```swift
do {
    let client = try HumeClient(apiKey: "invalid-key")
    let voices = try await client.tts.listVoices()
} catch HumeError.authenticationFailed(let message) {
    print("Authentication failed: \(message)")
} catch {
    print("Other error: \(error)")
}
```

## Token Management

When using OAuth2, the SDK handles token management automatically:

```swift
// Token refresh happens automatically
let client = try HumeClient(apiKey: apiKey, secretKey: secretKey)

// Make requests normally - tokens are managed internally
let response = try await client.tts.synthesize(request)
```

The SDK will:
- Cache tokens in memory
- Refresh tokens 5 minutes before expiry
- Retry failed requests after token refresh
- Handle concurrent token refreshes efficiently