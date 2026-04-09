//
//  LogDestination.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-09.
//

public protocol LogDestination: Sendable {
    func log(
        level: LogLevel,
        message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    )
}

public extension LogDestination {
    func verbose(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .verbose, message: msg(), file: file.fileBaseName, function: function, line: line)
    }

    func debug(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .debug, message: msg(), file: file.fileBaseName, function: function, line: line)
    }

    func info(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .info, message: msg(), file: file.fileBaseName, function: function, line: line)
    }

    func warning(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .warning, message: msg(), file: file.fileBaseName, function: function, line: line)
    }

    func error(_ msg: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.log(level: .error, message: msg(), file: file.fileBaseName, function: function, line: line)
    }
}

extension String {
    /// Extracts the bare file name from a `#fileID` string (e.g. `"MyModule/ViewController.swift"` → `"ViewController"`).
    var fileBaseName: String {
        var name = self
        if let slash = name.lastIndex(of: "/") { name = String(name[name.index(after: slash)...]) }
        if let dot = name.lastIndex(of: ".") { name = String(name[..<dot]) }
        return name
    }
}
