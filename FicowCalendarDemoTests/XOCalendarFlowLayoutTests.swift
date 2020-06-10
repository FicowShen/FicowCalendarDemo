import XCTest
@testable import FicowCalendarDemo

class XOCalendarFlowLayoutTests: XCTestCase {

    final class MockXOCalendarLayoutDataSource: NSObject, XOCalendarLayoutDataSource, UICollectionViewDataSource {

        var itemsInSection = [Int]()
        func numberOfItemsInSection(_ section: Int) -> Int {
            return itemsInSection[section]
        }

        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return itemsInSection.count
        }
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return self.numberOfItemsInSection(section)
        }
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
        }
    }

    var dataSource: MockXOCalendarLayoutDataSource!
    var layout: XOCalendarVerticalFlowLayout!

    let screenBounds = UIScreen.main.bounds

    override func setUp() {
        super.setUp()
        dataSource = MockXOCalendarLayoutDataSource()
        dataSource.itemsInSection = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

        layout = XOCalendarVerticalFlowLayout(dataSource: dataSource)
        layout.headerReferenceSize = CGSize(width: screenBounds.width, height: 10)
        layout.itemSize = CGSize(width: screenBounds.width/7, height: 50)
    }

    func testCellLayoutAttributes() throws {
        let collectionView = UICollectionView(frame: screenBounds,
                                    collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
        collectionView.dataSource = dataSource
        for section in 0..<dataSource.itemsInSection.count {
//            for item in 0..<dataSource.itemsInSection[section] {
                var attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: section))
                layout.updateAttributes(attributes,
                                        collectionView: collectionView)
                print(attributes)
//            }
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
