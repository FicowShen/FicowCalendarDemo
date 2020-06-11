import UIKit

public protocol FCalendarViewDelegate {
    func calendar(_ calendar: FCalendarView, canSelectDate date: Date) -> Bool
    func calendar(_ calendar: FCalendarView, didScrollToMonth date: Date)
    func calendar(_ calendar: FCalendarView, didSelectDate date: Date)
    func calendar(_ calendar: FCalendarView, didDeselectDate date: Date)
}

public final class FCalendarView: UIView {

    enum Layout {
        static let monthHeaderHeight: CGFloat = FCalendarHeaderView.fixedHeaderHeight
        static let weekdayHeaderHeight: CGFloat = 40
        static let maxNumberOfRows: CGFloat = 6
        static let minNumberOfRows: CGFloat = maxNumberOfRows - 1
        static let numberOfColumns: CGFloat = 7
        static let dayLabelLength: CGFloat = 44
        static let fixedHeaderHorizontalInset: CGFloat = 28
        static let weekdayHeaderHorizontalInset: CGFloat = fixedHeaderHorizontalInset/2
    }

    static let monthHeaderReuseID = String(describing: FCalendarMonthHeaderView.self)
    static let dayCellReuseID = String(describing: FCalendarDayCell.self)

    public var dataSource: FCalendarDataSource? {
        didSet {
            calendar.dataSource = dataSource
        }
    }

    public var delegate: FCalendarViewDelegate?
    public var isPagingEnabled: Bool {
        get { calendarCollectionView.isPagingEnabled }
        set { calendarCollectionView.isPagingEnabled = newValue }
    }

    public var scrollDirection: UICollectionView.ScrollDirection {
        get { calendarLayout is FCalendarVerticalFlowLayout ? .vertical : .horizontal }
        set {
            let layout = newValue == .vertical
                ? FCalendarVerticalFlowLayout(dataSource: calendar)
                : FCalendarHorizontalFlowLayout(dataSource: calendar)
            calendarCollectionView.collectionViewLayout = layout
            calendarCollectionView.reloadData()
        }
    }

    public var updateCalendarHeaderWhileScrolling = true

    private var dateBeingSelectedByUser : Date?

    private var startDateCache: Date = Date()
    private var endDateCache: Date = Date()
    private var startMonthDateCache: Date = Date()

    private var displayingSection: Int?
    private var displayingDate: Date?

    private(set) var selectedIndexPaths: [IndexPath] = [IndexPath]()
    private(set) var selectedDates: [Date] = [Date]()

    private let calendarHeaderView: FCalendarHeaderView = FCalendarHeaderView(frame: .zero)

    private let dayHeaderView = FCalendarDayHeaderView(weekdaySymbols: FCalendar.dateFormatter.weekdaySymbols)

    private lazy var calendarLayout: FCalendarFlowLayout = FCalendarVerticalFlowLayout(dataSource: calendar)

    private lazy var calendarCollectionView : UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: self.calendarLayout)
        cv.register(FCalendarDayCell.self, forCellWithReuseIdentifier: Self.dayCellReuseID)
        cv.register(FCalendarMonthHeaderView.self, forSupplementaryViewOfKind: Self.monthHeaderReuseID, withReuseIdentifier: Self.monthHeaderReuseID)
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.allowsMultipleSelection = true
        return cv
    }()

    private let calendar = FCalendar()

    private var firstWeekday: FCalendarDay = .sunday {
        didSet {
            calendar.firstWeekday = firstWeekday
            dayHeaderView.firstWeekday = firstWeekday
        }
    }

    private var showMonthHeaderForVerticalLayout: Bool {
        return calendarLayout is FCalendarVerticalFlowLayout
    }

    private var todayIndexPath: IndexPath? {
        guard let todayIndexPath = calendar.todayIndexPath
            else { return nil }
        return offsettedIndexPathForCalendarIndexPath(todayIndexPath)
    }

    var headerReferenceSize: CGSize {
        let width = calendarCollectionView.frame.size.width
        let size: CGSize
        if showMonthHeaderForVerticalLayout {
            size = CGSize(width: width,
                          height: FCalendarMonthHeaderView.height)
        } else {
            size = .zero
        }
        return size
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func offsettedIndexPathForCalendarIndexPath(_ indexPath: IndexPath) -> IndexPath {
        let section = calendar.getSection(indexPath.section)
        return IndexPath(row: section.indexOfFirstItem + indexPath.item,
                         section: indexPath.section)
    }

    public func scrollToToday(animated: Bool = true) {
        guard let todayIndexPath = todayIndexPath else { return }
        scrollToSection(todayIndexPath.section, animated: animated)
    }

    public func scrollToPreviousSection(animated: Bool = true) {
        guard var displayingSection = displayingSection else { return }
        displayingSection -= 1
        scrollToSection(displayingSection, animated: animated)
    }

    public func scrollToNextSection(animated: Bool = true) {
        guard var displayingSection = displayingSection else { return }
        displayingSection += 1
        scrollToSection(displayingSection, animated: animated)
    }

    public func scrollToDate(_ date: Date, animated: Bool) {
        guard let indexPath = calendar.indexPathOfDate(date)
            else { return }
        scrollToSection(indexPath.section, animated: animated)
    }

    public func reloadSections() {
        calendar.reloadSections()
        calendarCollectionView.reloadData()
    }

    private func scrollToSection(_ section: Int, animated: Bool = true) {
        guard let date = calendar.dateOfFirstDayInSection(section),
            let indexPath = calendar.indexPathOfDate(date),
            let attr = calendarLayout.layoutAttributesForItem(at: indexPath)
            else { return }
        let rect = CGRect(x: attr.frame.minX, y: attr.frame.minY,
                          width: calendarCollectionView.bounds.width,
                          height: calendarCollectionView.bounds.height)
        calendarCollectionView.scrollRectToVisible(rect, animated: animated)
    }

    private func setup() {
//        firstWeekday = .monday
        calendarHeaderView.backgroundColor = .white
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
            $0.top.equalTo(dayHeaderView.snp.bottom)
            var height = Layout.dayLabelLength * Layout.maxNumberOfRows
            if showMonthHeaderForVerticalLayout {
                height += FCalendarMonthHeaderView.height
            }
            $0.height.equalTo(height)
        }
    }

    func updateHeader(currentIndexPath: IndexPath) {
        let indexPath = currentIndexPath
        if updateCalendarHeaderWhileScrolling
            && indexPath.section == displayingSection {
            return
        }
        displayingSection = indexPath.section
        guard let yearDate = calendar.dateOfFirstDayInSection(indexPath.section),
            let (year, month) = calendar.yearAndMonthOfDate(yearDate)
            else { return }

        calendarHeaderView.setup(year: year, month: month)
        displayingDate = yearDate
        delegate?.calendar(self, didScrollToMonth: yearDate)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let width = calendarCollectionView.frame.size.width
        calendarLayout.itemSize = CGSize(width: width / Layout.numberOfColumns,
                                         height: Layout.dayLabelLength)
        calendarLayout.headerReferenceSize = headerReferenceSize
    }
}

extension FCalendarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return calendar.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendar.numberOfItemsInSection(section)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.dayCellReuseID, for: indexPath) as? FCalendarDayCell
            else { fatalError("Dequeue \(FCalendarDayCell.self) failed.") }

        let section = calendar.getSection(indexPath.section)
        let indexOfFirstItem = section.indexOfFirstItem
        let numberOfItems = section.numberOfItems

        let fromStartOfMonthIndexPath = IndexPath(item: indexPath.item - indexOfFirstItem,
                                                  section: indexPath.section)

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

        return dayCell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == 0
            && indexPath.item == 0,
            !calendarHeaderView.didSetText else { return }
        if let todayIndexPath = todayIndexPath {
            scrollToToday(animated: false)
            updateHeader(currentIndexPath: todayIndexPath)
        } else {
            calculateDateBasedOnScrollViewPosition(scrollView: collectionView)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: Self.monthHeaderReuseID, withReuseIdentifier: Self.monthHeaderReuseID, for: indexPath) as? FCalendarMonthHeaderView
            else { fatalError("Dequeue \(FCalendarMonthHeaderView.self) failed.") }
        if let yearDate = calendar.dateOfFirstDayInSection(indexPath.section),
            let (year, month) = calendar.yearAndMonthOfDate(yearDate) {
            headerView.setup(year: year, month: month)
        }
        return headerView
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return headerReferenceSize
    }
}

extension FCalendarView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let section = calendar.sections[indexPath.section]
            else { fatalError("Invalid indexPath \(indexPath) selected.") }
        let indexOfFirstItem = section.indexOfFirstItem

        let calendarIndexPath = IndexPath(item: indexPath.item - indexOfFirstItem,
                                          section: indexPath.section)
        if let dateUserSelected = calendar.dateAtIndexPath(calendarIndexPath) {
            dateBeingSelectedByUser = dateUserSelected
            if let canSelectDate = delegate?.calendar(self, canSelectDate: dateUserSelected) {
                return canSelectDate
            }
            return true
        }
        return false
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

extension FCalendarView: UIScrollViewDelegate {
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if updateCalendarHeaderWhileScrolling { return }
        if !decelerate {
            calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
        }
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if updateCalendarHeaderWhileScrolling { return }
        calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if updateCalendarHeaderWhileScrolling { return }
        calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !updateCalendarHeaderWhileScrolling { return }
        calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }

    func calculateDateBasedOnScrollViewPosition(scrollView: UIScrollView) {
        let size = CGSize(width: scrollView.bounds.size.width,
                          height: FCalendarMonthHeaderView.height)
        let rect = CGRect(origin: scrollView.contentOffset,
                          size: size)
        guard let firstElement = calendarLayout.layoutAttributesForElements(in: rect)?.first
            else { return }
        updateHeader(currentIndexPath: firstElement.indexPath)
    }
}
