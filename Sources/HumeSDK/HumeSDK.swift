// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Hume AI SDK for Swift
/// 
/// The Hume SDK provides Swift developers with easy access to Hume's APIs for:
/// - Text-to-Speech (TTS)
/// - Empathic Voice Interface (EVI)
/// - Expression Measurement
///
/// ## Getting Started
///
/// ```swift
/// import HumeSDK
///
/// // Initialize client with API key
/// let client = try HumeClient(apiKey: "your-api-key")
///
/// // Create API clients
/// let tts = TTSClient(client: client)
/// let evi = EVIClient(client: client)
/// let expression = ExpressionMeasurementClient(client: client)
/// ```

// Re-export all public types
@_exported import Foundation

// Core
public typealias Hume = HumeClient

// API Clients
public extension HumeClient {
    /// Create a TTS client
    var tts: TTSClient {
        return TTSClient(client: self)
    }
    
    /// Create an EVI client
    var evi: EVIClient {
        return EVIClient(client: self)
    }
    
    /// Create an Expression Measurement client
    var expressionMeasurement: ExpressionMeasurementClient {
        return ExpressionMeasurementClient(client: self)
    }
}