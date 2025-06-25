# ``HumeSDK``

Official Swift SDK for Hume AI APIs - Text-to-Speech, Expression Measurement, and Empathic Voice Interface.

## Overview

The Hume Swift SDK provides a comprehensive, type-safe interface to interact with Hume AI's APIs. Built with modern Swift features including async/await, actors, and strict concurrency, it offers a seamless development experience across all Apple platforms.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Authentication>
- <doc:ErrorHandling>

### API Clients

- ``HumeClient``
- ``TTSClient``
- ``ExpressionMeasurementClient``
- ``EVIClient``

### Text-to-Speech

- ``TTSRequest``
- ``TTSResponse``
- ``Voice``
- ``VoiceSpec``
- ``AudioFormat``
- ``SampleRate``

### Expression Measurement

- ``BatchClient``
- ``StreamClient``
- ``BatchRequest``
- ``StreamRequest``
- ``JobStatus``
- ``ModelType``
- ``PredictionResult``

### Empathic Voice Interface

- ``ChatSession``
- ``ConfigsClient``
- ``PromptsClient``
- ``ToolsClient``
- ``SessionSettings``
- ``ServerMessage``
- ``ClientMessage``

### Core Types

- ``Auth``
- ``HumeError``
- ``RequestOptions``
- ``PagedResponse``