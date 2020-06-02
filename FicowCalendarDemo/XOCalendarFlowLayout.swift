import UIKit

final class XOCalendarFlowLayout: UICollectionViewFlowLayout {

    var showMonthHeader = true

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
        if attributes.representedElementKind != nil {
            return
        }
        guard let collectionView = collectionView else {
            return
        }
        switch scrollDirection {
        case .horizontal:
            let xPageOffset = CGFloat(attributes.indexPath.section) * collectionView.frame.size.width
            let xCellOffset: CGFloat = xPageOffset + (CGFloat(attributes.indexPath.item % 7) * itemSize.width)
            let yCellOffset: CGFloat = CGFloat(attributes.indexPath.item / 7) * itemSize.height // headerReferenceSize.height + (CGFloat(attributes.indexPath.item / 7) * itemSize.height)
            attributes.frame = CGRect(x: xCellOffset,
                                      y: yCellOffset,
                                      width: itemSize.width,
                                      height: itemSize.height)
        case .vertical:
            let yPageOffset = CGFloat(attributes.indexPath.section) * collectionView.frame.size.height
            var yCellOffset: CGFloat = yPageOffset + (CGFloat(attributes.indexPath.item / 7) * itemSize.height)
            yCellOffset += showMonthHeader ? headerReferenceSize.height : 0
            let xCellOffset: CGFloat = CGFloat(attributes.indexPath.item % 7) * itemSize.width
            attributes.frame = CGRect(x: xCellOffset,
                                      y: yCellOffset,
                                      width: itemSize.width,
                                      height: itemSize.height)
        @unknown default:
            fatalError("Unknown scrollDirection")
        }
    }
}
