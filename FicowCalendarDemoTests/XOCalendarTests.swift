import XCTest
@testable import FicowCalendarDemo

struct CalendarTestHelper {

    private static let dateFormatter = DateFormatter()

    static func yyyyMMddDateFromString(_ s: String) -> Date? {
        Self.dateFormatter.dateFormat = "yyyy-MM-dd"
        return Self.dateFormatter.date(from: s)
    }
}

final class XOCalendarTests: XCTestCase {
    var calendar: XOCalendar!
    var dataSource: MockXOCalendarDataSource!
    let startDate = CalendarTestHelper.yyyyMMddDateFromString("2000-01-01")!
    let endDate = CalendarTestHelper.yyyyMMddDateFromString("2020-01-01")!

    override func setUp() {
        super.setUp()
        calendar = XOCalendar()
        dataSource = MockXOCalendarDataSource(start: startDate,
                                              end: endDate)
        calendar.dataSource = dataSource
        calendar.reloadSections()
    }

    func testDataSource() throws {
        XCTAssertEqual(calendar.numberOfSections, 241)
        for section in 0..<calendar.numberOfSections {
            print(calendar.numberOfItemsInSection(section))
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

struct MockXOCalendarDataSource: XOCalendarDataSource {
    let start: Date
    let end: Date
    func startDate() -> Date? { start }
    func endDate() -> Date? { end }
}
