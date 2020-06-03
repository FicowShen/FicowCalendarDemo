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
        guard attributes.representedElementCategory == .cell,
            let collectionView = collectionView else {
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
    override func setup() {
        super.setup()
        scrollDirection = .vertical
    }
    override func updateAttributes(_ attributes : UICollectionViewLayoutAttributes,
                                   collectionView: UICollectionView) {
        let yPageOffset = CGFloat(attributes.indexPath.section) * collectionView.frame.size.height
        var yCellOffset: CGFloat = yPageOffset + (CGFloat(attributes.indexPath.item / numberOfDaysInAWeek) * itemSize.height)
//        yCellOffset += showMonthHeaderForVerticalLayout ? headerReferenceSize.height : 0
        yCellOffset += headerReferenceSize.height
        let xCellOffset: CGFloat = CGFloat(attributes.indexPath.item % numberOfDaysInAWeek) * itemSize.width
        attributes.frame = CGRect(x: xCellOffset,
                                  y: yCellOffset,
                                  width: itemSize.width,
                                  height: itemSize.height)
    }
}
