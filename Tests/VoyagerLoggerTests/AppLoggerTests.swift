import Testing
@testable import VoyagerLogger

struct AppLoggerConvenienceTests {
    @Test
    func `verbose() logs at verbose level`() {
        let spy = SpyLogger()
        spy.verbose("test")
        #expect(spy.entries.first?.level == .verbose)
    }

    @Test
    func `debug() logs at debug level`() {
        let spy = SpyLogger()
        spy.debug("test")
        #expect(spy.entries.first?.level == .debug)
    }

    @Test
    func `info() logs at info level`() {
        let spy = SpyLogger()
        spy.info("test")
        #expect(spy.entries.first?.level == .info)
    }

    @Test
    func `warning() logs at warning level`() {
        let spy = SpyLogger()
        spy.warning("test")
        #expect(spy.entries.first?.level == .warning)
    }

    @Test
    func `error() logs at error level`() {
        let spy = SpyLogger()
        spy.error("test")
        #expect(spy.entries.first?.level == .error)
    }
}
