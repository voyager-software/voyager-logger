import Testing
@testable import VoyagerLogger

struct AppLoggerTests {
    @Test
    func `fans out to all destinations`() {
        let spy1 = SpyDestination()
        let spy2 = SpyDestination()
        let composite = AppLogger([spy1, spy2])

        composite.info("hello")

        #expect(spy1.entries.count == 1)
        #expect(spy1.entries[0].message == "hello")
        #expect(spy2.entries.count == 1)
        #expect(spy2.entries[0].message == "hello")
    }

    @Test
    func `works with empty destinations list`() {
        let composite = AppLogger([])
        composite.info("no-op")
    }

    @Test
    func `preserves log level across destinations`() {
        let spy1 = SpyDestination()
        let spy2 = SpyDestination()
        let composite = AppLogger([spy1, spy2])

        composite.error("fail")

        #expect(spy1.entries[0].level == .error)
        #expect(spy2.entries[0].level == .error)
    }
}
