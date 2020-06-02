import UIKit

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
        static let minNumberOfRows: CGFloat = maxNumberOfRows - 1
        static let numberOfColumns: CGFloat = 7
        static let dayLabelLength: CGFloat = 44
        static let fixedHeaderHorizontalInset: CGFloat = 28
        static let weekdayHeaderHorizontalInset: CGFloat = fixedHeaderHorizontalInset/2
    }

    static let monthHeaderReuseID = String(describing: XOCalendarMonthHeaderView.self)
    static let dayCellReuseID = String(describing: XOCalendarDayCell.self)

    var dataSource: XOCalendarDataSource? {
        didSet {
            calendar.dataSource = dataSource
        }
    }

    var delegate: XOCalendarViewDelegate?
    var isPagingEnabled: Bool {
        get { calendarCollectionView.isPagingEnabled }
        set { calendarCollectionView.isPagingEnabled = newValue }
    }
    var scrollDirection: UICollectionView.ScrollDirection {
        get { calendarLayout.scrollDirection }
        set {
            calendarLayout.scrollDirection = newValue
            calendarCollectionView.reloadData()
        }
    }
    var autoScrollToDateAfterInitiation: Date?

    private var dateBeingSelectedByUser : Date?

    private var startDateCache: Date = Date()
    private var endDateCache: Date = Date()
    private var startMonthDateCache: Date = Date()
    private var displayDate: Date?

    private(set) var selectedIndexPaths: [IndexPath] = [IndexPath]()
    private(set) var selectedDates: [Date] = [Date]()

    private let calendarHeaderView: XOCalendarHeaderView = XOCalendarHeaderView(frame: .zero)

    private let dayHeaderView: UIView = {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        for index in 0..<7 {
            let day = XOCalendar.dateFormatter.weekdaySymbols[index % 7]
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
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.allowsMultipleSelection = true
        return cv
    }()

    private let calendar = XOCalendar()

    private var showMonthHeader: Bool {
        return calendarLayout.scrollDirection == .vertical
            && calendarLayout.showMonthHeader
    }

    private var todayIndexPath: IndexPath? {
        guard let todayIndexPath = calendar.todayIndexPath,
            let section = calendar.sections[todayIndexPath.section]
            else { return nil }
        return .init(row: section.indexOfFirstItem + todayIndexPath.item,
                     section: todayIndexPath.section)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func scrollToToday(at scrollPosition: UICollectionView.ScrollPosition = .centeredVertically,
                              animated: Bool = true) {
        guard let todayIndexPath = todayIndexPath else { return }
        calendarCollectionView.scrollToItem(at: todayIndexPath,
                                            at: scrollPosition,
                                            animated: animated)
    }

    public func scrollToDate(_ date: Date) {
        // TODO: <FICOW> scroll to a certain date
    }

    private func setup() {
//        calendarLayout.countMonthHeader = false
        [calendarHeaderView, dayHeaderView, calendarCollectionView].reversed().forEach(addSubview)
        calendarHeaderView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Layout.fixedHeaderHorizontalInset)
            $0.height.equalTo(Layout.monthHeaderHeight)
        }
        dayHeaderView.snp.makeConstraints {
            $0.top.equalTo(calendarHeaderView.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(Layout.weekdayHeaderHorizontalInset)
            $0.height.equalTo(Layout.weekdayHeaderHeight)
        }
        calendarCollectionView.snp.makeConstraints {
            $0.leading.trailing.equalTo(dayHeaderView)
            $0.bottom.equalToSuperview()
            let topOffset = showMonthHeader
                ? -XOCalendarHeaderView.scrollableHeaderHeight
                : 0
            $0.top.equalTo(dayHeaderView.snp.bottom).offset(topOffset)
            var height = Layout.dayLabelLength * Layout.maxNumberOfRows
            if showMonthHeader {
                height += XOCalendarHeaderView.scrollableHeaderHeight
            }
            $0.height.equalTo(height)
        }
    }

    public func reloadSections() {
        calendar.reloadSections()
        calendarCollectionView.reloadData()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let width = calendarCollectionView.frame.size.width
        calendarLayout.itemSize = CGSize(width: width / Layout.numberOfColumns,
                                         height: Layout.dayLabelLength)
        let size: CGSize
        if showMonthHeader {
            size = CGSize(width: width,
                          height: XOCalendarHeaderView.scrollableHeaderHeight)
        } else {
            size = .zero
        }
        calendarLayout.headerReferenceSize = size
    }
}

extension XOCalendarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return calendar.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        #warning("*** Compute the correct column and row number ***")
        _ = calendar.numberOfItemsInSection(section)
        return Int(Layout.numberOfColumns * Layout.maxNumberOfRows) // 7 x 6 = 42
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.dayCellReuseID, for: indexPath) as? XOCalendarDayCell,
            let section = calendar.sections[indexPath.section]
            else { fatalError("Dequeue \(XOCalendarDayCell.self) failed.") }

        let indexOfFirstItem = section.indexOfFirstItem
        let numberOfItems = section.numberOfItems

        let fromStartOfMonthIndexPath = IndexPath(item: indexPath.item - indexOfFirstItem,
                                                  section: indexPath.section) // if the first is wednesday, add 2

        if indexPath.item >= indexOfFirstItem &&
            indexPath.item < indexOfFirstItem + numberOfItems {
            dayCell.text = String(fromStartOfMonthIndexPath.item + 1)
            dayCell.isDayInCurrentSection = true

        } else {
            dayCell.isDayInCurrentSection = false
        }

        dayCell.isSelected = selectedIndexPaths.contains(indexPath)

        if let todayIndex = todayIndexPath {
            dayCell.isToday = todayIndex == indexPath
        }

//        if let eventsForDay = eventsByIndexPath[fromStartOfMonthIndexPath] {
//            dayCell.eventsCount = eventsForDay.count
//        } else {
//            dayCell.eventsCount = 0
//        }

        return dayCell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == 0
            && indexPath.item == 0,
            !calendarHeaderView.didSetText else { return }
        if let date = autoScrollToDateAfterInitiation {
            scrollToDate(date)
        } else if let todayIndexPath = todayIndexPath {
            collectionView.scrollToItem(at: todayIndexPath,
                                        at: .centeredVertically,
                                        animated: false)
            collectionView.layoutIfNeeded()
            scrollViewDidEndDecelerating(collectionView)
        } else {
            scrollViewDidEndDecelerating(collectionView)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: Self.monthHeaderReuseID, withReuseIdentifier: Self.monthHeaderReuseID, for: indexPath) as? XOCalendarMonthHeaderView
            else { fatalError("Dequeue \(XOCalendarMonthHeaderView.self) failed.") }
        if let yearDate = calendar.dateOfSection(indexPath.section),
            let (year, month) = calendar.yearAndMonthOfDate(yearDate) {
            headerView.setup(year: year, month: month)
        }
        return headerView
    }
}

extension XOCalendarView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let section = calendar.sections[indexPath.section]
            else { fatalError("Invalid indexPath \(indexPath) selected.") }
        let indexOfFirstItem = section.indexOfFirstItem

        var offsetComponents = DateComponents()
        offsetComponents.month = indexPath.section
        offsetComponents.day = indexPath.item - indexOfFirstItem

        if let dateUserSelected = calendar.dateOfOffsetToStartMonth(offsetComponents) {
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

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
        }
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
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

        guard let yearDate = calendar.dateOfSection(page),
            let (year, month) = calendar.yearAndMonthOfDate(yearDate)
            else {
                return
        }

        calendarHeaderView.setup(year: year, month: month)
        displayDate = yearDate
        delegate?.calendar(self, didScrollToMonth: yearDate)
    }
}
