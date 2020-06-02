import UIKit

public protocol XOCalendarViewDataSource {
    func startDate() -> Date?
    func endDate() -> Date?
}

public protocol XOCalendarViewDelegate {
    func calendar(_ calendar: XOCalendarView, canSelectDate date: Date) -> Bool
    func calendar(_ calendar: XOCalendarView, didScrollToMonth date: Date)
    func calendar(_ calendar: XOCalendarView, didSelectDate date: Date)
    func calendar(_ calendar: XOCalendarView, didDeselectDate date: Date)
}

public final class XOCalendarView: UIView {

    enum Layout {
        static let monthHeaderHeight: CGFloat = XOCalendarHeaderView.fixedHeaderHeight
        static let weekdayHeaderHeight: CGFloat = 40
        static let maxNumberOfRows: CGFloat = 6
        static let numberOfColumns: CGFloat = 7
        static let dayLabelLength: CGFloat = 44
        static let fixedHeaderHorizontalInset: CGFloat = 28
        static let weekdayHeaderHorizontalInset: CGFloat = fixedHeaderHorizontalInset/2
    }

    static let monthHeaderReuseID = String(describing: XOCalendarMonthHeaderView.self)
    static let dayCellReuseID = String(describing: XOCalendarDayCell.self)
    static let dateFormatter = DateFormatter()


    let FIRST_DAY_INDEX = 0
    let NUMBER_OF_DAYS_INDEX = 1

    var dataSource: XOCalendarViewDataSource?
    var delegate: XOCalendarViewDelegate?
    private var dateBeingSelectedByUser : Date?

    private var startDateCache: Date = Date()
    private var endDateCache: Date = Date()
    private var startOfMonthCache: Date = Date()
    private var todayIndexPath: IndexPath?
    private var displayDate: Date?

    private(set) var selectedIndexPaths: [IndexPath] = [IndexPath]()
    private(set) var selectedDates: [Date] = [Date]()

    private let monthHeaderView: XOCalendarHeaderView = XOCalendarHeaderView(frame: .zero)

    private let weekdayHeaderView: UIView = {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        for index in 0..<7 {
            let day = dateFormatter.weekdaySymbols[index % 7]
            let weekdayLabel = UILabel()
            weekdayLabel.isOpaque = false
            weekdayLabel.backgroundColor = .white
            weekdayLabel.font = .systemFont(ofSize: 12, weight: .bold)
            weekdayLabel.text = day.prefix(2).uppercased()
            weekdayLabel.textColor = .rgb(red: 109, green: 113, blue: 121)
            weekdayLabel.textAlignment = .center
            weekdayLabel.showBorderWithRandomColor()
            stack.addArrangedSubview(weekdayLabel)
        }
        return stack
    }()

    private let calendarLayout: XOCalendarFlowLayout = {
        let layout = XOCalendarFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        return layout
    }()

    private lazy var calendarCollectionView : UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: calendarLayout)
        cv.register(XOCalendarDayCell.self, forCellWithReuseIdentifier: Self.dayCellReuseID)
        cv.register(XOCalendarMonthHeaderView.self, forSupplementaryViewOfKind: Self.monthHeaderReuseID, withReuseIdentifier: Self.monthHeaderReuseID)
        cv.dataSource = self
        cv.delegate = self
        cv.isPagingEnabled = true
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.allowsMultipleSelection = true
        return cv
    }()

    private lazy var gregorian : NSCalendar = {
        var calendar = NSCalendar(identifier: .gregorian)!
        calendar.timeZone = NSTimeZone.default as TimeZone
        return calendar
    }()

    private var monthInfo: [Int: [Int]] = [Int: [Int]]()


    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        [monthHeaderView, weekdayHeaderView, calendarCollectionView].reversed().forEach(addSubview)
        monthHeaderView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Layout.fixedHeaderHorizontalInset)
            $0.height.equalTo(Layout.monthHeaderHeight)
        }
        weekdayHeaderView.snp.makeConstraints {
            $0.top.equalTo(monthHeaderView.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(Layout.weekdayHeaderHorizontalInset)
            $0.height.equalTo(Layout.weekdayHeaderHeight)
        }
        calendarCollectionView.snp.makeConstraints {
            $0.leading.trailing.equalTo(weekdayHeaderView)
            $0.bottom.equalToSuperview()
            $0.top.equalTo(weekdayHeaderView.snp.bottom)
                .offset(-XOCalendarHeaderView.scrollableHeaderHeight)
            var height = XOCalendarHeaderView.scrollableHeaderHeight
            height += Layout.dayLabelLength * Layout.maxNumberOfRows
            $0.height.equalTo(height)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let width = calendarCollectionView.frame.size.width
        calendarLayout.headerReferenceSize = CGSize(width: width,
                                                    height: XOCalendarHeaderView.scrollableHeaderHeight)
        calendarLayout.itemSize = CGSize(width: width / Layout.numberOfColumns,
                                         height: Layout.dayLabelLength)
    }

}

extension XOCalendarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let startDate = dataSource?.startDate(),
            let endDate = dataSource?.endDate()
            else { return 0 }

        startDateCache = startDate
        endDateCache = endDate

        var firstDayOfStartMonth = gregorian.components( [.era, .year, .month],
                                                         from: startDateCache)
        firstDayOfStartMonth.day = 1 // round to first day

        guard let dateFromDayOneComponents = gregorian.date(from: firstDayOfStartMonth) else {
            return 0
        }

        startOfMonthCache = dateFromDayOneComponents

        let today = Date()

        if  startOfMonthCache.compare(today) == ComparisonResult.orderedAscending &&
            endDateCache.compare(today) == ComparisonResult.orderedDescending {
            let differenceFromTodayComponents = gregorian.components([.month, .day],
                                                                     from: startOfMonthCache,
                                                                     to: today,
                                                                     options: [])
            guard let day = differenceFromTodayComponents.day,
                let month = differenceFromTodayComponents.month
                else { fatalError("Get day and month from differenceFromTodayComponents failed.") }
            todayIndexPath = IndexPath(item: day, section: month)
        }

        let differenceComponents = gregorian.components(.month,
                                                        from: startDateCache,
                                                        to: endDateCache,
                                                        options: [])
        guard let month = differenceComponents.month
            else { fatalError("Get total month count failed.") }
        return month + 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var monthOffsetComponents = DateComponents()

        // offset by the number of months
        monthOffsetComponents.month = section;

        guard let correctMonthForSectionDate = gregorian.date(byAdding: monthOffsetComponents, to: startOfMonthCache, options: []) else {
            return 0
        }

        let numberOfDaysInMonth = gregorian.range(of: .day, in: .month, for: correctMonthForSectionDate).length

        var firstWeekdayOfMonthIndex = gregorian.component(.weekday, from: correctMonthForSectionDate)
//        firstWeekdayOfMonthIndex = firstWeekdayOfMonthIndex - 1 // firstWeekdayOfMonthIndex should be 0-Indexed
        firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + 6) % 7 // push it modularly so that we take it back one day so that the first day is Monday instead of Sunday which is the default

        monthInfo[section] = [firstWeekdayOfMonthIndex, numberOfDaysInMonth]

        return Int(Layout.numberOfColumns * Layout.maxNumberOfRows) // 7 x 6 = 42
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.dayCellReuseID, for: indexPath) as! XOCalendarDayCell

        let currentMonthInfo : [Int] = monthInfo[indexPath.section]! // we are guaranteed an array by the fact that we reached this line (so unwrap)

        let firstDayIndex = currentMonthInfo[FIRST_DAY_INDEX]
        let numberOfDaysInCurrentMonth = currentMonthInfo[NUMBER_OF_DAYS_INDEX]

        let fromStartOfMonthIndexPath = IndexPath(item: indexPath.item - firstDayIndex,
                                                  section: indexPath.section) // if the first is wednesday, add 2

        if indexPath.item >= firstDayIndex &&
            indexPath.item < firstDayIndex + numberOfDaysInCurrentMonth {
            dayCell.text = String(fromStartOfMonthIndexPath.item + 1)
            dayCell.isHidden = false

        } else {
            dayCell.text = ""
            dayCell.isHidden = true
        }

        dayCell.isSelected = selectedIndexPaths.contains(indexPath)

        if let todayIndex = todayIndexPath {
            dayCell.isToday = (todayIndex.section == indexPath.section
                && todayIndex.item + firstDayIndex == indexPath.item)
        }

//        if let eventsForDay = eventsByIndexPath[fromStartOfMonthIndexPath] {
//            dayCell.eventsCount = eventsForDay.count
//        } else {
//            dayCell.eventsCount = 0
//        }

        return dayCell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width,
                      height: XOCalendarHeaderView.scrollableHeaderHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: Self.monthHeaderReuseID, withReuseIdentifier: Self.monthHeaderReuseID, for: indexPath) as? XOCalendarMonthHeaderView
            else { fatalError("Dequeue \(XOCalendarMonthHeaderView.self) failed.") }
        if let yearDate = dateOfSection(indexPath.section),
            let (year, month) = yearAndMonthOfDate(yearDate) {
            headerView.setup(year: year, month: month)
        }
        return headerView
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let yearDate = dateOfSection(indexPath.section),
            let (year, month) = yearAndMonthOfDate(yearDate) {
            monthHeaderView.setup(year: year, month: month)
        }
    }
}

extension XOCalendarView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let currentMonthInfo : [Int] = monthInfo[indexPath.section]!
        let firstDayInMonth = currentMonthInfo[FIRST_DAY_INDEX]

        var offsetComponents = DateComponents()
        offsetComponents.month = indexPath.section
        offsetComponents.day = indexPath.item - firstDayInMonth

        if let dateUserSelected = gregorian.date(byAdding: offsetComponents, to: startOfMonthCache, options: []) {
            dateBeingSelectedByUser = dateUserSelected
            // Optional protocol method (the delegate can "object")
            if let canSelectFromDelegate = delegate?.calendar(self, canSelectDate: dateUserSelected) {
                return canSelectFromDelegate
            }
            return true // it can select any date by default
        }
        return false // if date is out of scope
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let delegate = self.delegate,
            let index = selectedIndexPaths.firstIndex(of: indexPath),
            let dateSelectedByUser = dateBeingSelectedByUser {
            delegate.calendar(self, didDeselectDate: dateSelectedByUser)
            selectedIndexPaths.remove(at: index)
            selectedDates.remove(at: index)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = self.delegate,
            let dateSelectedByUser = dateBeingSelectedByUser {
            delegate.calendar(self, didSelectDate: dateSelectedByUser)
            selectedIndexPaths.append(indexPath)
            selectedDates.append(dateSelectedByUser)
        }
    }
}

extension XOCalendarView: UIScrollViewDelegate {

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }

    func calculateDateBasedOnScrollViewPosition(scrollView: UIScrollView) {
        var page: Int = 0
        switch calendarLayout.scrollDirection {
        case .horizontal:
            let cvbounds = calendarCollectionView.bounds
            let pageOfOffset: Int = Int(floor(calendarCollectionView.contentOffset.x / cvbounds.size.width))
            page = pageOfOffset > 0 ? pageOfOffset : 0
        case .vertical:
            let cvbounds = calendarCollectionView.bounds
            let pageOfOffset: Int = Int(floor(calendarCollectionView.contentOffset.y / cvbounds.size.height))
            page = pageOfOffset > 0 ? pageOfOffset : 0
        @unknown default:
            fatalError("Unknown scrollDirection")
        }

        guard let yearDate = dateOfSection(page),
            let (year, month) = yearAndMonthOfDate(yearDate)
            else {
                return
        }

        monthHeaderView.setup(year: year, month: month)
        displayDate = yearDate
        delegate?.calendar(self, didScrollToMonth: yearDate)
    }

    func dateOfSection(_ section: Int) -> Date? {
        var monthsOffsetComponents = DateComponents()
        monthsOffsetComponents.month = section
        return gregorian.date(byAdding: monthsOffsetComponents, to: startOfMonthCache, options: [])
    }

    func yearAndMonthOfDate(_ date: Date) -> (year: String, month: String)? {
        let month = gregorian.component(.month, from: date) // get month
        let monthName = Self.dateFormatter.monthSymbols[(month-1) % 12] // 0 indexed array
        let year = gregorian.component(.year, from: date)
        return (year: year.description, month: monthName)
    }

}
