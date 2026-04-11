//
//  LogMessageFormat.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

public struct LogMessageFormat: Sendable, Equatable {
    // MARK: Lifecycle

    public init(
        components: [Component],
        separator: String = " "
    ) {
        self.components = components
        self.separator = separator
    }

    // MARK: Public

    public enum Component: Sendable, Equatable {
        case timestamp
        case level
        case callSite
        case message
    }

    public static let osLogDefault = Self(components: [.callSite, .message])
    public static let rollingFileDefault = Self(components: [.timestamp, .level, .callSite, .message])

    public let components: [Component]
    public let separator: String

    public func format(
        level: LogLevel,
        message: String,
        file: String,
        function: String,
        line: Int,
        timestamp: String? = nil
    ) -> String {
        self.components
            .map { component in
                switch component {
                case .timestamp:
                    timestamp.map { "[\($0)]" } ?? ""
                case .level:
                    level.label
                case .callSite:
                    "\(file).\(function)():\(line)"
                case .message:
                    message
                }
            }
            .filter { !$0.isEmpty }
            .joined(separator: self.separator)
    }
}
