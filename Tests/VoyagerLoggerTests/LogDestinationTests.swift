import Testing
@testable import VoyagerLogger

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
}
