import Foundation

/// Input validation utilities for HumeSDK
public enum Validation {
    
    // MARK: - Constants
    
    /// Maximum text length for TTS
    public static let maxTTSTextLength = 5000
    
    /// Maximum text length for expression measurement
    public static let maxExpressionTextLength = 10000
    
    /// Valid speaking rate range
    public static let speakingRateRange = 0.5...2.0
    
    /// Valid pitch range
    public static let pitchRange = 0.5...2.0
    
    /// Valid sample rates
    public static let validSampleRates: Set<Int> = [8000, 16000, 22050, 24000, 44100, 48000]
    
    /// Maximum file size for uploads (10MB)
    public static let maxFileSize = 10 * 1024 * 1024
    
    // MARK: - Validation Methods
    
    /// Validate text length
    public static func validateTextLength(_ text: String, maxLength: Int, fieldName: String) throws {
        guard !text.isEmpty else {
            throw HumeError.validation("\(fieldName) cannot be empty")
        }
        
        guard text.count <= maxLength else {
            throw HumeError.validation("\(fieldName) must be <= \(maxLength) characters, got \(text.count)")
        }
    }
    
    /// Validate and clamp speaking rate
    public static func validateSpeakingRate(_ rate: Double) -> Double {
        return max(speakingRateRange.lowerBound, min(rate, speakingRateRange.upperBound))
    }
    
    /// Validate and clamp pitch
    public static func validatePitch(_ pitch: Double) -> Double {
        return max(pitchRange.lowerBound, min(pitch, pitchRange.upperBound))
    }
    
    /// Validate sample rate
    public static func validateSampleRate(_ rate: Int) throws {
        guard validSampleRates.contains(rate) else {
            throw HumeError.validation("Invalid sample rate \(rate). Valid rates are: \(validSampleRates.sorted())")
        }
    }
    
    /// Validate file size
    public static func validateFileSize(_ size: Int, fieldName: String) throws {
        guard size <= maxFileSize else {
            throw HumeError.validation("\(fieldName) size exceeds maximum of \(maxFileSize) bytes, got \(size) bytes")
        }
    }
    
    /// Validate API key format
    public static func validateAPIKey(_ apiKey: String) throws {
        guard !apiKey.isEmpty else {
            throw HumeError.validation("API key cannot be empty")
        }
        
        guard apiKey != "dummy" else {
            throw HumeError.validation("Invalid API key: 'dummy' is not allowed")
        }
        
        // Basic format check - adjust based on actual Hume API key format
        guard apiKey.count >= 20 else {
            throw HumeError.validation("API key appears to be invalid (too short)")
        }
    }
    
    /// Validate voice name
    public static func validateVoiceName(_ name: String) throws {
        guard !name.isEmpty else {
            throw HumeError.validation("Voice name cannot be empty")
        }
        
        guard name.count <= 100 else {
            throw HumeError.validation("Voice name too long (max 100 characters)")
        }
    }
    
    /// Validate language code (BCP-47)
    public static func validateLanguageCode(_ code: String) throws {
        guard !code.isEmpty else {
            throw HumeError.validation("Language code cannot be empty")
        }
        
        let validCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        guard code.rangeOfCharacter(from: validCharacters.inverted) == nil else {
            throw HumeError.validation("Invalid language code format")
        }
    }
}

// MARK: - Validation Error Extension

extension HumeError {
    /// Create a validation error
    public static func validation(_ message: String) -> HumeError {
        return .custom(message: "Validation error: \(message)")
    }
}

// MARK: - Validated Types

/// A validated text string for TTS
@propertyWrapper
public struct TTSText {
    private var value: String
    
    public init(wrappedValue: String) throws {
        try Validation.validateTextLength(wrappedValue, maxLength: Validation.maxTTSTextLength, fieldName: "TTS text")
        self.value = wrappedValue
    }
    
    public var wrappedValue: String {
        get { value }
        set {
            do {
                try Validation.validateTextLength(newValue, maxLength: Validation.maxTTSTextLength, fieldName: "TTS text")
                value = newValue
            } catch {
                Logger.error("Invalid TTS text length: \(error)")
                // Keep the old value
            }
        }
    }
}

/// A validated speaking rate
@propertyWrapper
public struct SpeakingRate {
    private var value: Double
    
    public init(wrappedValue: Double) {
        self.value = Validation.validateSpeakingRate(wrappedValue)
    }
    
    public var wrappedValue: Double {
        get { value }
        set { value = Validation.validateSpeakingRate(newValue) }
    }
}