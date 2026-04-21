//
//  LogMetadataKey.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

/// Type-safe, extensible key for log metadata.
///
/// Define new keys by extending this type:
/// ```swift
/// extension LogMetadataKey {
///     static let retry = LogMetadataKey(rawValue: "retry")
///     static let sentryError = LogMetadataKey(rawValue: "sentryError")
/// }
/// ```
public struct LogMetadataKey: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
    // MARK: Lifecycle

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    // MARK: Public

    public let rawValue: String
}

/// Metadata dictionary passed through to destinations.
/// Destinations inspect keys they care about and ignore the rest.
public typealias LogMetadata = [LogMetadataKey: any Sendable]

/// Optional info dictionary for convenience log methods.
public typealias LogInfo = [String: any Sendable]

// MARK: - Standard metadata keys

public extension LogMetadataKey {
    /// The original `Error` object, wrapped in `SendableError`.
    static let originalError = LogMetadataKey(rawValue: "originalError")
}
