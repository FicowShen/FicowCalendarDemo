import UIKit
import SnapKit

class ViewController: UIViewController {

    lazy var previousButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.clipsToBounds = true
        button.setTitle(" < previous month ", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        return button
    }()

    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.clipsToBounds = true
        button.setTitle(" next month > ", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        return button
    }()

    lazy var calendarView: XOCalendarView = {
        let calendar = XOCalendarView()
        calendar.dataSource = self
        calendar.delegate = self
        return calendar
    }()

    let calendar = XOCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(calendarView)
        calendarView.snp.makeConstraints {
            $0.center.width.equalToSuperview()
        }
        [previousButton, nextButton].forEach(view.addSubview(_:))
        previousButton.snp.makeConstraints {
            $0.leading.bottom.equalToSuperview().inset(30)
        }
        nextButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(30)
        }
        calendarView.setNeedsLayout()
//        calendar.reloadSections()
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

extension ViewController: XOCalendarViewDataSource {
    func startDate() -> Date? {
        calendar.minimumDate
    }

    func endDate() -> Date? {
        calendar.maximumDate
    }
}

extension ViewController: XOCalendarViewDelegate {
    func calendar(_ calendar: XOCalendarView, canSelectDate date: Date) -> Bool {
        true
    }

    func calendar(_ calendar: XOCalendarView, didScrollToMonth date: Date) {

    }

    func calendar(_ calendar: XOCalendarView, didSelectDate date: Date) {

    }
}
//extension ViewController: UICollectionViewDataSource {
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return calendar.numberOfMonths
//    }
//
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let monthHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: Self.monthHeaderReuseID, withReuseIdentifier: Self.monthHeaderReuseID, for: indexPath) as? XOCalendarMonthHeaderView
//        monthHeaderView?.setup(year: indexPath.section.description, month: indexPath.item.description)
//        return monthHeaderView
//            !? (UICollectionReusableView(), "Cannot dequeue \(Self.monthHeaderReuseID)")
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 42
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CalendarCell.self), for: indexPath) as? CalendarCell else {
//            fatalError("Dequeue CalendarCell failed.")
//        }
//        cell.textLabel.text = indexPath.item.description
//        return cell
//    }
//
//}
//
//extension ViewController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return .init(width: collectionView.frame.width, height: 44)
//    }
//}
//
//extension ViewController: UICollectionViewDelegate {
//
//}
