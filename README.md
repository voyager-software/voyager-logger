# VoyagerLogger

A lightweight, Sendable-safe Swift logging package for Apple platforms.

## Overview

VoyagerLogger provides a small `LogDestination` protocol with convenience APIs for common log levels, and an `AppLogger` composite that fans out messages to multiple destinations.

### Built-in Destinations

| Destination | Purpose |
|---|---|
| `OSLogDestination` | Unified Logging via `os.Logger` |
| `RollingFileDestination` | Size-based rolling file logs |
| `NullDestination` | No-op (silences logging) |
| `SpyDestination` | Captures entries for tests |

### Log File Export

`LogFileExporter` collects `.log` files and exports them as a merged text file or zip archive for sharing and support workflows.

## Usage

```swift
let logger = AppLogger(destinations: [
    OSLogDestination(subsystem: "com.app", category: "ui"),
    RollingFileDestination(directory: logsURL)
])

logger.info("App launched")
logger.warning("Low memory")
logger.error("Something failed", meta: [.retry: true])
```

## Message Formatting

`OSLogDestination` and `RollingFileDestination` accept a shared `LogMessageFormat` so you can choose which parts of the rendered log line appear and in what order.

Available components:

- `.timestamp`
- `.level`
- `.fileLine`
- `.function`
- `.message`

Built-in defaults preserve the current output:

- `LogMessageFormat.osLogDefault` renders `"[File:Line] [function] message"`
- `LogMessageFormat.rollingFileDefault` renders `"[timestamp] LVL [File:Line] [function] message"`

Customize `OSLogDestination` formatting:

```swift
let console = OSLogDestination(
    subsystem: "com.app",
    category: "network",
    format: LogMessageFormat(
        components: [.level, .message, .fileLine],
        separator: " | "
    )
)
```

Customize `RollingFileDestination` formatting:

```swift
let fileLogger = try RollingFileDestination(
    configuration: .init(
        directory: logsURL,
        format: LogMessageFormat(
            components: [.timestamp, .message, .level],
            separator: " "
        )
    )
)
```

## Extensible Metadata Keys

`LogMetadata` uses type-safe, extensible keys instead of raw strings:

```swift
extension LogMetadataKey {
    static let retry = LogMetadataKey(rawValue: "retry")
    static let errorCode = LogMetadataKey(rawValue: "errorCode")
}

logger.error("Network timeout", meta: [.retry: true, .errorCode: 408])
```

## Custom Destinations

Conform to `LogDestination` to create your own:

```swift
struct MyDestination: LogDestination {
    func log(
        level: LogLevel,
        message: @autoclosure () -> any Sendable,
        meta: LogMetadata,
        file: String,
        function: String,
        line: Int
    ) {
        // your logging logic
    }
}
```

## Requirements

- Swift 6.0+
- iOS 16+ / macOS 13+ / tvOS 16+ / Mac Catalyst 16+
