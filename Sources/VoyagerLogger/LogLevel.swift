//
//  LogLevel.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

public enum LogLevel: Int, Sendable, Comparable {
    case verbose, debug, info, warning, error

    // MARK: Public

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // MARK: Internal

    var label: String {
        switch self {
        case .verbose: "VERBOSE"
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warning: "WARNING"
        case .error: "ERROR"
        }
    }
}
