import UIKit

public protocol XOCalendarViewDataSource {
    func startDate() -> Date?
    func endDate() -> Date?
}

public protocol XOCalendarViewDelegate {
    func calendar(_ calendar: XOCalendarView, canSelectDate date: Date) -> Bool
    func calendar(_ calendar: XOCalendarView, didScrollToMonth date: Date)
    func calendar(_ calendar: XOCalendarView, didSelectDate date: Date)
}

public final class XOCalendarView: UIView {

    enum Layout {
        static let monthHeaderHeight: CGFloat = 44
        static let weekdayHeaderHeight: CGFloat = 22
        static let maxNumberOfRows: CGFloat = 6
        static let numberOfColumns: CGFloat = 7
        static let dayLabelLength: CGFloat = 44
    }

    static let monthHeaderReuseID = String(describing: XOCalendarMonthHeaderView.self)
    static let dayCellReuseID = String(describing: CalendarCell.self)
    static let dateFormatter = DateFormatter()


    let FIRST_DAY_INDEX = 0
    let NUMBER_OF_DAYS_INDEX = 1

    var dataSource: XOCalendarViewDataSource?
    var delegate: XOCalendarViewDelegate?

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
            weekdayLabel.text = day.prefix(2).uppercased()
            weekdayLabel.textColor = .gray
            weekdayLabel.textAlignment = .center
            weekdayLabel.layer.borderColor = UIColor.blue.cgColor
            weekdayLabel.layer.borderWidth = 1
            stack.addArrangedSubview(weekdayLabel)
        }
        return stack
    }()

    private let calendarLayout: XOCalendarFlowLayout = XOCalendarFlowLayout()

    private lazy var calendarView : UICollectionView = {
        calendarLayout.scrollDirection = .horizontal
        calendarLayout.minimumInteritemSpacing = 0
        calendarLayout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: calendarLayout)
        cv.register(CalendarCell.self, forCellWithReuseIdentifier: Self.dayCellReuseID)
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

//    public override var frame: CGRect {
//        didSet {
//            let height = frame.size.height - Layout.monthHeaderHeight
//            let width = frame.size.width
//            monthHeaderView.frame = CGRect(x: 0.0,
//                                      y: 0.0,
//                                      width: frame.size.width,
//                                      height: Layout.monthHeaderHeight)
//            calendarView.frame = CGRect(x: 0.0,
//                                        y: Layout.monthHeaderHeight,
//                                        width: width ,
//                                        height: height)
//            calendarLayout.itemSize = CGSize(width: width / Layout.numberOfColumns,
//                                             height: height / Layout.maxNumberOfRows)
//        }
//    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        monthHeaderView.setup(year: "Year", month: "Month")
        [monthHeaderView, weekdayHeaderView, calendarView].forEach(addSubview)
        monthHeaderView.snp.makeConstraints {
            $0.leading.top.trailing.equalToSuperview()
            $0.height.equalTo(Layout.monthHeaderHeight)
        }
        weekdayHeaderView.snp.makeConstraints {
            $0.top.equalTo(monthHeaderView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Layout.weekdayHeaderHeight)
        }
        calendarView.snp.makeConstraints {
            $0.leading.bottom.trailing.equalToSuperview()
            $0.top.equalTo(weekdayHeaderView.snp.bottom)
            $0.height.equalTo(Layout.dayLabelLength * Layout.maxNumberOfRows)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let height = frame.size.height - Layout.monthHeaderHeight
        let width = frame.size.width
        calendarLayout.itemSize = CGSize(width: width / Layout.numberOfColumns,
                                         height: height / Layout.maxNumberOfRows)
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
                else { fatalError() }
            todayIndexPath = IndexPath(item: day, section: month)
        }

        let differenceComponents = gregorian.components(.month,
                                                        from: startDateCache,
                                                        to: endDateCache,
                                                        options: [])
        guard let month = differenceComponents.month
            else { fatalError() }
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
        let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.dayCellReuseID, for: indexPath) as! CalendarCell

        let currentMonthInfo : [Int] = monthInfo[indexPath.section]! // we are guaranteed an array by the fact that we reached this line (so unwrap)

        let firstDayIndex = currentMonthInfo[FIRST_DAY_INDEX]
        let numberOfDaysInCurrentMonth = currentMonthInfo[NUMBER_OF_DAYS_INDEX]

        let fromStartOfMonthIndexPath = IndexPath(item: indexPath.item - firstDayIndex,
                                                  section: indexPath.section) // if the first is wednesday, add 2

        if indexPath.item >= firstDayIndex &&
            indexPath.item < firstDayIndex + numberOfDaysInCurrentMonth {
            dayCell.textLabel.text = String(fromStartOfMonthIndexPath.item + 1)
            dayCell.isHidden = false

        } else {
            dayCell.textLabel.text = ""
            dayCell.isHidden = true
        }

        dayCell.isSelected = selectedIndexPaths.contains(indexPath)

        if indexPath.section == 0 && indexPath.item == 0 {
//            self.scrollViewDidEndDecelerating(collectionView)
        }

        if let todayIndex = todayIndexPath {
            dayCell.isToday = (todayIndex.section == indexPath.section
                && todayIndex.item + firstDayIndex == indexPath.item)
        }

//        if let eventsForDay = eventsByIndexPath[fromStartOfMonthIndexPath] {
//
//            dayCell.eventsCount = eventsForDay.count
//
//        } else {
//            dayCell.eventsCount = 0
//        }

        return dayCell
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

        let cvbounds = calendarView.bounds

        var page : Int = Int(floor(calendarView.contentOffset.x / cvbounds.size.width))

        page = page > 0 ? page : 0

        var monthsOffsetComponents = DateComponents()
        monthsOffsetComponents.month = page

        guard let yearDate = gregorian.date(byAdding: monthsOffsetComponents, to: startOfMonthCache, options: []) else {
            return
        }

        let month = gregorian.component(.month, from: yearDate) // get month

        let monthName = Self.dateFormatter.monthSymbols[(month-1) % 12] // 0 indexed array

        let year = gregorian.component(.year, from: yearDate)

        monthHeaderView.setup(year: year.description, month: monthName)

        displayDate = yearDate

        delegate?.calendar(self, didScrollToMonth: yearDate)
    }

}
