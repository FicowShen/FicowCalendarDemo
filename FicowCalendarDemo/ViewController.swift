import UIKit
import SnapKit

final class ViewController: UIViewController {

    private static func makeButton(title: String, target: AnyObject) -> UIButton {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        button.backgroundColor = .white
        button.setTitle(title, for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.addTarget(target, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        return button
    }

    private static let dateFormatter = DateFormatter()

    private static func yyyyMMddDateFromString(_ s: String) -> Date? {
        Self.dateFormatter.dateFormat = "yyyy-MM-dd"
        return Self.dateFormatter.date(from: s)
    }

    var minimumDate = yyyyMMddDateFromString("2019-02-03") ?? Date()
    var maximumDate = yyyyMMddDateFromString("2021-04-10") ?? Date()

    private lazy var previousButton: UIButton = Self.makeButton(title: " < previous month  ", target: self)
    private lazy var nextButton: UIButton = Self.makeButton(title: "  next month  > ", target: self)

    private lazy var calendarView: XOCalendarView = {
        let calendar = XOCalendarView()
        calendar.dataSource = self
        calendar.delegate = self
        calendar.showBorderWithRandomColor()
        return calendar
    }()

    private lazy var calendarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.backgroundColor = .white
        view.showBorderWithRandomColor()
        return view
    }()

    private let calendar = XOCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .lightGray
        view.addSubview(calendarContainerView)
        calendarContainerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalToSuperview().inset(8)
        }
        calendarContainerView.addSubview(calendarView)
        calendarView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview()
        }
        [previousButton, nextButton].forEach(view.addSubview(_:))
        previousButton.snp.makeConstraints {
            $0.leading.bottom.equalToSuperview().inset(30)
        }
        nextButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(30)
        }
        calendarView.reloadSections()
//        calendarView.setNeedsLayout()
//        calendar.reloadSections()
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender {
        case previousButton:
            print("previousButton")
        case nextButton:
            print("nextButton")
        default:
            fatalError("Invalid button pressed")
        }
    }
}

extension ViewController: XOCalendarDataSource {
    func startDate() -> Date? { minimumDate }

    func endDate() -> Date? { maximumDate }
}

extension ViewController: XOCalendarViewDelegate {
    func calendar(_ calendar: XOCalendarView, canSelectDate date: Date) -> Bool {
        true
    }

    func calendar(_ calendar: XOCalendarView, didScrollToMonth date: Date) {

    }

    func calendar(_ calendar: XOCalendarView, didSelectDate date: Date) {

    }
    func calendar(_ calendar: XOCalendarView, didDeselectDate date: Date) {
        
    }
}
