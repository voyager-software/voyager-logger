import Foundation
import Testing
@testable import VoyagerLogger

extension LogMetadataKey {
    static let retry = LogMetadataKey(rawValue: "retry")
    static let errorCode = LogMetadataKey(rawValue: "errorCode")
}

struct LogDestinationConvenienceTests {
    @Test
    func `verbose() logs at verbose level`() {
        let spy = SpyDestination()
        spy.verbose("test")
        #expect(spy.entries.first?.level == .verbose)
    }

    @Test
    func `debug() logs at debug level`() {
        let spy = SpyDestination()
        spy.debug("test")
        #expect(spy.entries.first?.level == .debug)
    }

    @Test
    func `info() logs at info level`() {
        let spy = SpyDestination()
        spy.info("test")
        #expect(spy.entries.first?.level == .info)
    }

    @Test
    func `warning() logs at warning level`() {
        let spy = SpyDestination()
        spy.warning("test")
        #expect(spy.entries.first?.level == .warning)
    }

    @Test
    func `error() logs at error level`() {
        let spy = SpyDestination()
        spy.error("test")
        #expect(spy.entries.first?.level == .error)
    }

    // MARK: - error overloads

    @Test
    func `error(String) appends info dictionary`() {
        let spy = SpyDestination()
        spy.error("boom", info: ["key": "val"])
        let entry = spy.entries.first
        #expect(entry?.message == "boom\nkey=val")
    }

    @Test
    func `error(String) forwards metadata`() {
        let spy = SpyDestination()
        spy.error("boom", meta: [.retry: true])
        let entry = spy.entries.first
        #expect(entry?.meta[.retry] as? Bool == true)
    }

    @Test
    func `error(Error) logs the error message`() {
        let spy = SpyDestination()
        struct TestError: LocalizedError {
            var failureReason: String? { "something broke" }
        }
        spy.error(TestError())
        let entry = spy.entries.first
        #expect(entry?.level == .error)
        #expect(entry?.message == "something broke")
    }

    @Test
    func `error(Error) falls back to localizedDescription`() {
        let spy = SpyDestination()
        struct SimpleError: Error, LocalizedError {
            var errorDescription: String? { "simple desc" }
        }
        spy.error(SimpleError())
        #expect(spy.entries.first?.message == "simple desc")
    }

    @Test
    func `error(Error) forwards metadata and info`() {
        let spy = SpyDestination()
        struct Err: LocalizedError {
            var failureReason: String? { "fail" }
        }
        spy.error(Err(), info: ["ctx": "test"], meta: [.errorCode: 42])
        let entry = spy.entries.first
        #expect(entry?.message == "fail\nctx=test")
        #expect(entry?.meta[.errorCode] as? Int == 42)
    }

    // MARK: - message content

    @Test
    func `convenience methods pass through the message string`() {
        let spy = SpyDestination()
        spy.verbose("v")
        spy.debug("d")
        spy.info("i")
        spy.warning("w")
        spy.error("e")
        let messages = spy.entries.map(\.message)
        #expect(messages == ["v", "d", "i", "w", "e"])
    }
}
