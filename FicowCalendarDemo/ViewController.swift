import UIKit

class ViewController: UIViewController {

    static let monthHeaderReuseID = String(describing: XOCalendarMonthHeaderView.self)

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: String(describing: CalendarCell.self))
            collectionView.register(XOCalendarMonthHeaderView.self,
                                    forSupplementaryViewOfKind: Self.monthHeaderReuseID,
                                    withReuseIdentifier: Self.monthHeaderReuseID)
            collectionView.dataSource = self
            collectionView.delegate = self
//            collectionView.isPagingEnabled = true
        }
    }

    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    let calendar = XOCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()

        calendar.reloadSections()
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender {
        case previousButton:
            print("previousButton")
        case nextButton:
            print("nextButton")
        default:
            fatalError()
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return calendar.numberOfMonths
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let monthHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: Self.monthHeaderReuseID, withReuseIdentifier: Self.monthHeaderReuseID, for: indexPath) as? XOCalendarMonthHeaderView
        monthHeaderView?.setup(year: indexPath.section.description, month: indexPath.item.description)
        return monthHeaderView
            !? (UICollectionReusableView(), "Cannot dequeue \(Self.monthHeaderReuseID)")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 42
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CalendarCell.self), for: indexPath) as? CalendarCell else {
            fatalError("Dequeue CalendarCell failed.")
        }
        cell.textLabel.text = indexPath.item.description
        return cell
    }

}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: collectionView.frame.width, height: 44)
    }
}

extension ViewController: UICollectionViewDelegate {

}
