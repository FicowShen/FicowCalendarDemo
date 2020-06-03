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

    var minimumDate = yyyyMMddDateFromString("2019-12-03") ?? Date()
    var maximumDate = yyyyMMddDateFromString("2021-04-10") ?? Date()

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

    private let operationStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.spacing = 8
        return stack
    }()

    private lazy var todayButton: UIButton = Self.makeButton(title: " today ", target: self)
    private lazy var previousButton: UIButton = Self.makeButton(title: " < previous month  ", target: self)
    private lazy var nextButton: UIButton = Self.makeButton(title: "  next month  > ", target: self)

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.calendar = NSCalendar.current
        picker.date = Date()
        picker.minimumDate = Self.yyyyMMddDateFromString("2001-12-03")
        picker.maximumDate = Self.yyyyMMddDateFromString("2031-12-03")
        picker.addTarget(self, action: #selector(pickerValueChanged), for: .valueChanged)
        return picker
    }()

    private var currentMonthDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .lightGray
        view.addSubview(calendarContainerView)
        calendarContainerView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(32)
            $0.width.equalToSuperview().inset(8)
        }
        calendarContainerView.addSubview(calendarView)
        calendarView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview()
        }
        view.addSubview(operationStackView)
        operationStackView.snp.makeConstraints {
            $0.leading.trailing.equalTo(calendarContainerView)
            $0.top.equalTo(calendarContainerView.snp.bottom).offset(16)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .equalSpacing
        buttonStack.spacing = 4
        operationStackView.addArrangedSubview(buttonStack)
        [previousButton, todayButton, nextButton].forEach(buttonStack.addArrangedSubview)

        operationStackView.addArrangedSubview(datePicker)

        calendarView.reloadSections()
//        calendarView.setNeedsLayout()
//        calendar.reloadSections()
    }

    @objc private func buttonPressed(_ sender: UIButton) {
        do {
            switch sender {
            case previousButton:
                try calendarView.scrollToPreviousSection()
                print("previousButton")
            case nextButton:
                try calendarView.scrollToNextSection()
                print("nextButton")
            case todayButton:
                try calendarView.scrollToToday()
                print("todayButton")
            default:
                fatalError("Invalid button pressed")
            }
        } catch {
            print(error)
        }
    }

    @objc private func pickerValueChanged() {
        print("datePicker.date:", datePicker.date)
        do {
            try calendarView.scrollToDate(datePicker.date, animated: true)
        } catch {
            print(error)
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
        print(#function, date)
        currentMonthDate = date
    }
    func calendar(_ calendar: XOCalendarView, didSelectDate date: Date) {
        print(#function, date)
    }
    func calendar(_ calendar: XOCalendarView, didDeselectDate date: Date) {
        print(#function, date)
    }
}
