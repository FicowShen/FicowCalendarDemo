import XCTest
@testable import FicowCalendarDemo

struct CalendarTestHelper {

    private static let dateFormatter = DateFormatter()

    static func yyyyMMddDateFromString(_ s: String) -> Date? {
        Self.dateFormatter.dateFormat = "yyyy-MM-dd"
        return Self.dateFormatter.date(from: s)
    }
    static func yyyyMMddStringFromDate(_ date: Date) -> String? {
        Self.dateFormatter.string(from: date)
    }
}

struct CalendarSection: Decodable {
    let indexOfFirstItem: Int
    let numberOfItems: Int
    let date: String
}

final class FCalendarTests: XCTestCase {
    var calendar: FCalendar!
    var dataSource: MockFCalendarDataSource!
    let startDate = CalendarTestHelper.yyyyMMddDateFromString("2000-01-01")!
    let endDate = CalendarTestHelper.yyyyMMddDateFromString("2020-01-01")!

    override func setUp() {
        super.setUp()
        calendar = FCalendar()
        dataSource = MockFCalendarDataSource(start: startDate,
                                              end: endDate)
        calendar.dataSource = dataSource
        calendar.reloadSections()
    }

    func testCalendarSections() throws {
        guard let jsonPath = Bundle(for: type(of: self)).path(forResource: "CalendarSections", ofType: "json"),
            let jsonData = FileManager.default.contents(atPath: jsonPath),
            let calendarSections = try? JSONDecoder().decode([CalendarSection].self, from: jsonData)
            else { return }

        XCTAssertEqual(calendarSections.count, 241)
        XCTAssertEqual(calendar.numberOfSections, 241)
        for i in 0..<calendar.numberOfSections {
            guard let date = calendar.dateOfFirstDayInSection(i),
                let dateString = CalendarTestHelper.yyyyMMddStringFromDate(date)
                else { XCTFail(); fatalError() }
            let section = calendar.getSection(i)
            let expectedSection = calendarSections[i]
            XCTAssertEqual(section.indexOfFirstItem, expectedSection.indexOfFirstItem)
            XCTAssertEqual(section.numberOfItems, expectedSection.numberOfItems)
            XCTAssertEqual(dateString, expectedSection.date)
        }
    }

    func testDateAtIndexPath()  {
        let indexPaths: [IndexPath] = [
            .init(item: 0, section: 0),
            .init(item: 0, section: 12*20)
        ]
        let expectedDates: [Date?] = [
            CalendarTestHelper.yyyyMMddDateFromString("2000-01-01"),
            CalendarTestHelper.yyyyMMddDateFromString("2020-01-01"),
        ]
        for (i, indexPath) in indexPaths.enumerated() {
            XCTAssertEqual(calendar.dateAtIndexPath(indexPath), expectedDates[i])
        }
    }

    func testFirstWeekDay() {
        let last = calendar.numberOfSections - 1
        XCTAssertEqual(calendar.getSection(0).indexOfFirstItem, 6)
        XCTAssertEqual(calendar.getSection(last).indexOfFirstItem, 3)

        calendar.firstWeekday = .monday
        XCTAssertEqual(calendar.getSection(0).indexOfFirstItem, 5)
        XCTAssertEqual(calendar.getSection(last).indexOfFirstItem, 2)

        calendar.firstWeekday = .saturday
        XCTAssertEqual(calendar.getSection(0).indexOfFirstItem, 0)
        XCTAssertEqual(calendar.getSection(last).indexOfFirstItem, 4)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

struct MockFCalendarDataSource: FCalendarDataSource {
    let start: Date
    let end: Date
    func startDate() -> Date? { start }
    func endDate() -> Date? { end }
}
