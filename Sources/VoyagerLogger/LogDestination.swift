//
//  LogDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

import Foundation

public protocol LogDestination: Sendable {
    func log(
        level: LogLevel,
        message: @autoclosure () -> String,
        meta: LogMetadata,
        file: String,
        function: String,
        line: Int
    )
}

public extension LogDestination {
    func verbose(
        _ msg: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        self.log(level: .verbose, message: msg(), meta: [:], file: file.fileBaseName, function: function, line: line)
    }

    func debug(
        _ msg: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        self.log(level: .debug, message: msg(), meta: [:], file: file.fileBaseName, function: function, line: line)
    }

    func info(
        _ msg: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        self.log(level: .info, message: msg(), meta: [:], file: file.fileBaseName, function: function, line: line)
    }

    func screenView(
        _ value: String,
        info: LogInfo? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        self.custom(name: "SCREEN VIEW", value: value, info: info, file: file.fileBaseName, function: function, line: line)
    }

    func action(
        _ value: String,
        info: LogInfo? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        self.custom(name: "ACTION", value: value, info: info, file: file.fileBaseName, function: function, line: line)
    }

    private func custom(
        name: String,
        value: String,
        info: LogInfo? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        var msg = "\(name) - \(value)"
        if let info {
            msg += ": " + info.stringValue(separator: "; ")
        }
        self.log(level: .info, message: msg, meta: [:], file: file.fileBaseName, function: function, line: line)
    }

    func warning(
        _ msg: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        self.log(level: .warning, message: msg(), meta: [:], file: file.fileBaseName, function: function, line: line)
    }

    func error(
        _ msg: @autoclosure () -> String,
        info: LogInfo? = nil,
        meta: LogMetadata = [:],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        var msg = msg()
        if let info {
            msg += "\n" + info.stringValue(separator: "\n")
        }
        self.log(level: .error, message: msg, meta: meta, file: file.fileBaseName, function: function, line: line)
    }

    func error(
        _ err: Error,
        info: LogInfo? = nil,
        meta: LogMetadata = [:],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        var msg = err.logMessage
        if let info {
            msg += "\n" + info.stringValue(separator: "\n")
        }
        self.log(level: .error, message: msg, meta: meta, file: file.fileBaseName, function: function, line: line)
    }
}

private extension String {
    /// Extracts the bare file name from a `#fileID` string (e.g. `"MyModule/ViewController.swift"` → `"ViewController"`).
    var fileBaseName: String {
        var name = self
        if let slash = name.lastIndex(of: "/") { name = String(name[name.index(after: slash)...]) }
        if let dot = name.lastIndex(of: ".") { name = String(name[..<dot]) }
        return name
    }
}

private extension LogInfo {
    func stringValue(separator: String) -> String {
        self.sorted { $0.key < $1.key }
            .compactMap { "\($0)=\($1)" }
            .joined(separator: separator)
    }
}

private extension Error {
    var logMessage: String {
        if let error = self as? LocalizedError {
            return error.failureReason ?? error.localizedDescription
        }
        return self.localizedDescription
    }
}
