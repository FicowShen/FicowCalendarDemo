import UIKit

public protocol XOCalendarDataSource {
    func startDate() -> Date?
    func endDate() -> Date?
}

public enum XOCalendarDay: Int {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

public enum XOCalendarError: Error {
    case dateOutOfRange(String)
}

public final class XOCalendar {

    public struct CalendarSection {
        let indexOfFirstItem: Int
        let numberOfItems: Int
    }

    static let dateFormatter = DateFormatter()

    public var firstWeekday: XOCalendarDay = .sunday {
        didSet {
            gregorian.firstWeekday = firstWeekday.rawValue
            reloadSections()
        }
    }

    var numberOfSections: Int {
        return gregorian.numberOfMonth(from: startDateCache, to: endDateCache)
    }

    var dataSource: XOCalendarDataSource?
    private(set) var todayIndexPath: IndexPath?
    private(set) var sections = [Int: CalendarSection]()

    private let gregorian : NSCalendar = {
        var calendar = NSCalendar(identifier: .gregorian)!
        calendar.timeZone = NSTimeZone.default as TimeZone
        // https://stackoverflow.com/a/16876427
        calendar.firstWeekday = XOCalendarDay.sunday.rawValue
        return calendar
    }()

    private var startDateCache: Date = Date()
    private var endDateCache: Date = Date()
    private var startMonthDateCache: Date = Date()

    private var dateComponentsOfFirstDayInStartMonth: DateComponents {
        var firstDayOfStartMonth = gregorian.components( [.era, .year, .month],
        from: startDateCache)
        firstDayOfStartMonth.day = 1 // round to first day
        return firstDayOfStartMonth
    }

    private var dateOfFirstDayInStartMonth: Date? {
        return gregorian.date(from: dateComponentsOfFirstDayInStartMonth)
    }

    /// Get section info
    /// - Parameter sectionIndex: sectionIndex, it's month index if counting for months
    /// - Returns: section info
    public func getSection(_ sectionIndex: Int) -> CalendarSection {
        if let section = sections[sectionIndex] {
            return section
        }
        let section = generateSection(sectionIndex)
        sections[sectionIndex] = section
        return section
    }

    /// Generate the number of items in a section and cache in `sections`
    /// - Parameter section: section, it's month if counting for a month
    /// - Returns: number of items, it's number of days if counting for a month
    public func numberOfItemsInSection(_ section: Int) -> Int {
        return getSection(section).numberOfItems
    }

    public func reloadSections() {
        guard let startDate = dataSource?.startDate(),
            let endDate = dataSource?.endDate()
            else { return }
        startDateCache = startDate
        endDateCache = endDate
        sections = [:]
        loadAndCacheStartMonth()
        loadAndCacheToday()
    }

    public func yearAndMonthOfDate(_ date: Date) -> (year: String, month: String)? {
        let month = gregorian.component(.month, from: date) // get month
        let monthName = Self.dateFormatter.monthSymbols[(month-1) % 12] // 0 indexed array
        let year = gregorian.component(.year, from: date)
        return (year: year.description, month: monthName)
    }

    public func dateOfFirstDayInSection(_ section: Int) -> Date? {
        return gregorian.offsettedDay(from: startMonthDateCache,
                                      month: section,
                                      day: 1)
    }

    public func dateAtIndexPath(_ indexPath: IndexPath) -> Date? {
        return gregorian.offsettedDay(from: startMonthDateCache,
                                      month: indexPath.section,
                                      day: indexPath.item)
    }

    public func indexPathOfDate(_ date: Date) throws -> IndexPath? {
        guard startMonthDateCache.compare(date) == .orderedAscending &&
            endDateCache.compare(date) == .orderedDescending else {
                throw XOCalendarError.dateOutOfRange(date.description)
        }
        let dateToStartMonth = gregorian.components([.month, .day],
                                                    from: startMonthDateCache,
                                                    to: date,
                                                    options: [])
        guard let day = dateToStartMonth.day,
            let month = dateToStartMonth.month
            else { fatalError("Get indexPathOfDate \(date) failed.") }
        return IndexPath(item: day, section: month)
    }

    private func generateSection(_ sectionIndex: Int) -> CalendarSection {
        var monthOffsetComponents = DateComponents()
        // offset by the number of months
        monthOffsetComponents.month = sectionIndex

        guard let correctMonthForSectionDate = gregorian.date(byAdding: monthOffsetComponents, to: startMonthDateCache, options: []) else {
            fatalError("generateSection for section \(sectionIndex) failed.")
        }
        let numberOfDaysInMonth = gregorian.range(of: .day, in: .month, for: correctMonthForSectionDate).length
        var firstWeekdayOfMonthIndex = gregorian.component(.weekday, from: correctMonthForSectionDate)
        // for the Gregorian 1 is Sunday
        // firstWeekdayOfMonthIndex should be 0-Indexed
        firstWeekdayOfMonthIndex -= 1
        // push it modularly so that it can won't be minus numbers
        firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + 7) % 7

        return CalendarSection(indexOfFirstItem: firstWeekdayOfMonthIndex,
                               numberOfItems: numberOfDaysInMonth)
    }

    private func loadAndCacheStartMonth() {
        guard let dateOfFirstDayInStartMonth = dateOfFirstDayInStartMonth else {
            return
        }
        startMonthDateCache = dateOfFirstDayInStartMonth
    }

    private func loadAndCacheToday() {
        let today = Date()
        todayIndexPath = try? indexPathOfDate(today)
    }
}

private extension NSCalendar {
    func offsettedDay(from date: Date, month: Int, day: Int = 0) -> Date? {
        return offsettedDate(from: date, year: 0, month: month, day: day)
    }

    func offsettedDate(from date: Date,
                       year: Int,
                       month: Int,
                       day: Int,
                       hour: Int = 0,
                       minute: Int = 0,
                       second: Int = 0) -> Date? {
        var offset = DateComponents()
        offset.year = year
        offset.month = month
        offset.day = day
        offset.hour = hour
        offset.minute = minute
        offset.second = second
        return self.date(byAdding: offset,
                         to: date,
                         options: [])
    }

    func numberOfMonth(from: Date, to: Date) -> Int {
        let differenceComponents = components(.month,
                                              from: from,
                                              to: to,
                                              options: [])
        guard let month = differenceComponents.month
            else { fatalError("Get numberOfMonth from: \(from), to: \(to) failed.") }
        return month + 1
    }
}
