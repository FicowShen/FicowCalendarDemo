import UIKit

protocol XOCalendarLayoutDataSource: class {
    func numberOfItemsInSection(_ section: Int) -> Int
}

extension XOCalendar: XOCalendarLayoutDataSource {}

class XOCalendarFlowLayout: UICollectionViewFlowLayout {

    let dataSource: XOCalendarLayoutDataSource
    let numberOfDaysInAWeek = 7

    init(dataSource: XOCalendarLayoutDataSource) {
        self.dataSource = dataSource
        super.init()
        setup()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setup() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return super.layoutAttributesForElements(in: rect)?.map {
            attrs in
            let attributes = attrs.copy() as! UICollectionViewLayoutAttributes
            self.applyLayoutAttributes(attributes: attributes)
            return attributes
        }
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return super.layoutAttributesForItem(at: indexPath).map { attrs in
            let attributes = attrs.copy() as! UICollectionViewLayoutAttributes
            self.applyLayoutAttributes(attributes: attributes)
            return attributes
        }
    }
    func applyLayoutAttributes(attributes : UICollectionViewLayoutAttributes) {
        guard let collectionView = collectionView else {
            return
        }
        updateAttributes(attributes, collectionView: collectionView)
    }
    func updateAttributes(_ attributes : UICollectionViewLayoutAttributes,
                          collectionView: UICollectionView) {}
}

final class XOCalendarHorizontalFlowLayout: XOCalendarFlowLayout {
    override func setup() {
        super.setup()
        scrollDirection = .horizontal
    }
    override func updateAttributes(_ attributes : UICollectionViewLayoutAttributes,
                                   collectionView: UICollectionView) {
        guard attributes.representedElementCategory == .cell else { return }
        let xPageOffset = CGFloat(attributes.indexPath.section) * collectionView.frame.size.width
        let xCellOffset: CGFloat = xPageOffset + (CGFloat(attributes.indexPath.item % numberOfDaysInAWeek) * itemSize.width)
        let yCellOffset: CGFloat = CGFloat(attributes.indexPath.item / numberOfDaysInAWeek) * itemSize.height
        attributes.frame = CGRect(x: xCellOffset,
                                  y: yCellOffset,
                                  width: itemSize.width,
                                  height: itemSize.height)
    }
}

final class XOCalendarVerticalFlowLayout: XOCalendarFlowLayout {

    override var itemSize: CGSize {
        didSet {
            invalidateLayout()
        }
    }

    private var sectionVerticalStart = [Int: CGFloat]()
    private let numberOfRows = (min: 5, max: 6)

    override func setup() {
        super.setup()
        scrollDirection = .vertical
    }
    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        _ = verticalStartOfSection(collectionView.numberOfSections + 1)
        let height = sectionVerticalStart[collectionView.numberOfSections] ?? 0
        return CGSize(width: collectionView.bounds.width, height: height)
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.size != collectionView?.bounds.size
    }
    override func invalidateLayout() {
        super.invalidateLayout()
        sectionVerticalStart = [:]
    }
    override func updateAttributes(_ attributes : UICollectionViewLayoutAttributes,
                                   collectionView: UICollectionView) {
        switch attributes.representedElementCategory {
        case .cell:
            updateCellAttributes(attributes, collectionView: collectionView)
        case .supplementaryView:
            updateHeaderAttributes(attributes, collectionView: collectionView)
        default:
            break
        }
    }
    func updateHeaderAttributes(_ attributes : UICollectionViewLayoutAttributes,
                                collectionView: UICollectionView) {
        let section = attributes.indexPath.section
        let sectionStart: CGFloat
        if let start = sectionVerticalStart[section] {
            sectionStart = start
        } else {
            sectionStart = verticalStartOfSection(section)
        }
        attributes.frame = CGRect(x: 0,
                                  y: sectionStart,
                                  width: collectionView.bounds.width,
                                  height: headerReferenceSize.height)
    }
    func updateCellAttributes(_ attributes : UICollectionViewLayoutAttributes,
                              collectionView: UICollectionView) {
        let section = attributes.indexPath.section
        let xCellOffset: CGFloat = CGFloat(attributes.indexPath.item % numberOfDaysInAWeek) * itemSize.width
        let sectionStart: CGFloat
        if let start = sectionVerticalStart[section] {
            sectionStart = start
        } else {
            sectionStart = verticalStartOfSection(section)
        }
        let yPageOffset = sectionStart
        var yCellOffset: CGFloat = yPageOffset + headerReferenceSize.height
        yCellOffset += (CGFloat(attributes.indexPath.item / numberOfDaysInAWeek) * itemSize.height)
        attributes.frame = CGRect(x: xCellOffset,
                                  y: yCellOffset,
                                  width: itemSize.width,
                                  height: itemSize.height)
    }
    private func verticalStartOfSection(_ section: Int) -> CGFloat {
        var caculatedSection = 0
        var left = caculatedSection, right = section
        var mid = right / 2
        while true {
            if sectionVerticalStart[mid] != nil {
                if sectionVerticalStart[mid + 1] != nil {
                    left = mid + 1
                } else {
                    caculatedSection = mid
                    break
                }
            } else {
                right = mid - 1
            }
            mid = (left + right) / 2
            if left >= right {
                caculatedSection = mid
                break
            }
        }
        var verticalStart: CGFloat = 0
        if caculatedSection < section {
            verticalStart = sectionVerticalStart[caculatedSection] ?? 0
        }
        let minItemCountOfMonth = numberOfRows.min * numberOfDaysInAWeek
        while caculatedSection < section - 1 {
            let items = dataSource.numberOfItemsInSection(caculatedSection)
            let numberOfRowsInSection = items > minItemCountOfMonth
                ? numberOfRows.max
                : numberOfRows.min
            verticalStart += CGFloat(numberOfRowsInSection) * itemSize.height + headerReferenceSize.height
            caculatedSection += 1
            sectionVerticalStart[caculatedSection] = verticalStart
        }
        if sectionVerticalStart[section] == nil {
            sectionVerticalStart[section] = verticalStart
        }
        return verticalStart
    }
}
