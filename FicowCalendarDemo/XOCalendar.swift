import UIKit

public protocol XOCalendarDataSource {
    func startDate() -> Date?
    func endDate() -> Date?
}

public final class XOCalendar {

    struct CalendarSection {
        let indexOfFirstItem: Int
        let numberOfItems: Int
    }

    static let dateFormatter = DateFormatter()

    var dataSource: XOCalendarDataSource?
    private(set) var todayIndexPath: IndexPath?
    private(set) var sections = [Int: CalendarSection]()

    private let gregorian : NSCalendar = {
        var calendar = NSCalendar(identifier: .gregorian)!
        calendar.timeZone = NSTimeZone.default as TimeZone
        return calendar
    }()

    private var startDateCache: Date = Date()
    private var endDateCache: Date = Date()
    private var startMonthDateCache: Date = Date()

    var dateComponentsOfFirstDayInStartMonth: DateComponents {
        var firstDayOfStartMonth = gregorian.components( [.era, .year, .month],
        from: startDateCache)
        firstDayOfStartMonth.day = 1 // round to first day
        return firstDayOfStartMonth
    }

    var dateOfFirstDayInStartMonth: Date? {
        return gregorian.date(from: dateComponentsOfFirstDayInStartMonth)
    }


    var numberOfSections: Int {
        return numberOfMonth(from: startDateCache, to: endDateCache)
    }

    func numberOfItemsInSection(_ section: Int) -> Int {
        var monthOffsetComponents = DateComponents()

        // offset by the number of months
        monthOffsetComponents.month = section

        guard let correctMonthForSectionDate = gregorian.date(byAdding: monthOffsetComponents, to: startMonthDateCache, options: []) else {
            return 0
        }

        let numberOfDaysInMonth = gregorian.range(of: .day, in: .month, for: correctMonthForSectionDate).length

        var firstWeekdayOfMonthIndex = gregorian.component(.weekday, from: correctMonthForSectionDate)
        //        firstWeekdayOfMonthIndex = firstWeekdayOfMonthIndex - 1 // firstWeekdayOfMonthIndex should be 0-Indexed
        firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + 6) % 7 // push it modularly so that we take it back one day so that the first day is Monday instead of Sunday which is the default

        //        let maxNumberOfItems = Int(Layout.numberOfColumns * Layout.maxNumberOfRows)
        //        let minNumberOfItems = Int(Layout.numberOfColumns * Layout.minNumberOfRows)
        //
        //        var numberOfItems: Int
        //        if firstWeekdayOfMonthIndex + 1 + numberOfDaysInMonth > minNumberOfItems {
        //            numberOfItems = maxNumberOfItems
        //        } else {
        //            numberOfItems = minNumberOfItems
        //        }
        sections[section] = .init(indexOfFirstItem: firstWeekdayOfMonthIndex,
                                  numberOfItems: numberOfDaysInMonth)
        return numberOfDaysInMonth
    }

    func numberOfMonth(from: Date, to: Date) -> Int {
        let differenceComponents = gregorian.components(.month,
                                                        from: from,
                                                        to: to,
                                                        options: [])
        guard let month = differenceComponents.month
            else { fatalError("Get total month count failed.") }
        return month + 1
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

    func yearAndMonthOfDate(_ date: Date) -> (year: String, month: String)? {
        let month = gregorian.component(.month, from: date) // get month
        let monthName = Self.dateFormatter.monthSymbols[(month-1) % 12] // 0 indexed array
        let year = gregorian.component(.year, from: date)
        return (year: year.description, month: monthName)
    }

    func dateOfSection(_ section: Int) -> Date? {
        var monthsOffsetComponents = DateComponents()
        monthsOffsetComponents.month = section
        return gregorian.date(byAdding: monthsOffsetComponents,
                              to: startMonthDateCache,
                              options: [])
    }

    func dateOfOffsetToStartMonth(_ offset: DateComponents) -> Date? {
        gregorian.date(byAdding: offset, to: startMonthDateCache, options: [])
    }

    private func loadAndCacheStartMonth() {
        guard let dateOfFirstDayInStartMonth = dateOfFirstDayInStartMonth else {
            return
        }
        startMonthDateCache = dateOfFirstDayInStartMonth
    }

    private func loadAndCacheToday() {
        let today = Date()
        if startMonthDateCache.compare(today) == .orderedAscending &&
            endDateCache.compare(today) == .orderedDescending {
            let todayToStartMonth = gregorian.components([.month, .day],
                                                         from: startMonthDateCache,
                                                         to: today,
                                                         options: [])
            guard let day = todayToStartMonth.day,
                let month = todayToStartMonth.month
                else { fatalError("Get day and month from differenceFromTodayComponents failed.") }
            todayIndexPath = IndexPath(item: day, section: month)
        }
    }
}

private extension Calendar {
    func firstDayOfMonth(_ date: Date) -> Date {
        var components = self.dateComponents([.era, .year, .month, .day, .hour], from: date)
        components.day = 1
        return self.date(from: components)
            !? (Date(), "Cannot get firstDayOfMonth of \(date)")
    }
}
