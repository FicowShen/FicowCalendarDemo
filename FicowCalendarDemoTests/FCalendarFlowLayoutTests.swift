import XCTest
@testable import FicowCalendarDemo

class FCalendarFlowLayoutTests: XCTestCase {
    var layoutDataSource: MockFCalendarLayoutDataSource!
    var layout: FCalendarVerticalFlowLayout!
    var collectionView: UICollectionView!

    let screenBounds = UIScreen.main.bounds

    override func setUp() {
        super.setUp()
        layoutDataSource = MockFCalendarLayoutDataSource()
        layoutDataSource.setup()

        layout = FCalendarVerticalFlowLayout(dataSource: layoutDataSource)
        layout.headerReferenceSize = CGSize(width: screenBounds.width, height: 10)
        layout.itemSize = CGSize(width: screenBounds.width/7, height: 50)

        collectionView = UICollectionView(frame: screenBounds,
                                    collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
        collectionView.dataSource = layoutDataSource
    }

    func testCellLayoutAttributes() {
        let lastSection = layoutDataSource.numberOfSections(in: collectionView) - 1
        let indexPath = IndexPath(item: 0, section: lastSection)
        guard let attributes = layout.layoutAttributesForItem(at: indexPath)
            else { XCTFail(); fatalError() }
        let rect = CGRect(x: 0, y: 969640,
                          width: 53.57142857142857, height: 50)
        XCTAssertEqual(attributes.frame, rect)
    }

    func testLayoutComputationPerformance() throws {
        self.measure {
            layout.invalidateLayout()
            _ = layout.collectionViewContentSize
        }
    }
}

final class MockFCalendarLayoutDataSource: NSObject, FCalendarLayoutDataSource, UICollectionViewDataSource {

    var startDate = CalendarTestHelper.yyyyMMddDateFromString("1901-01-01")!
    var endDate = CalendarTestHelper.yyyyMMddDateFromString("2200-01-01")!

    var calendar: FCalendar!
    var dataSource: MockFCalendarDataSource!

    func setup() {
        calendar = FCalendar()
        dataSource = MockFCalendarDataSource(start: startDate,
                                              end: endDate)
        calendar.dataSource = dataSource
        calendar.reloadSections()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return calendar.numberOfSections
    }
    func numberOfItemsInSection(_ section: Int) -> Int {
        return calendar.numberOfItemsInSection(section)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsInSection(section)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
    }
}
