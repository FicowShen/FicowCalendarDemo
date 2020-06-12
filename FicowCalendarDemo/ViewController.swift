import UIKit
import SnapKit

final class ViewController: UIViewController {

    private static func makeButton(title: String, target: AnyObject) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        button.backgroundColor = .white
        button.setTitle(title, for: .normal)
        button.addTarget(target, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        return button
    }

    private static let dateFormatter = DateFormatter()

    private static func yyyyMMddDateFromString(_ s: String) -> Date? {
        Self.dateFormatter.dateFormat = "yyyy-MM-dd"
        return Self.dateFormatter.date(from: s)
    }

    private static var firstDayOfCurrentMonth: Date? {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day = 1
        return calendar.date(from: components)
    }

    var minimumDate = firstDayOfCurrentMonth
//    var minimumDate = yyyyMMddDateFromString("2020-12-03") ?? Date()
    var maximumDate = yyyyMMddDateFromString("2100-12-03") ?? Date()

    private lazy var calendarView: FCalendarView = {
        let calendar = FCalendarView()
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

    private lazy var todayButton: UIButton = Self.makeButton(title: " - today - ", target: self)
    private lazy var previousButton: UIButton = Self.makeButton(title: " < previous month  ", target: self)
    private lazy var nextButton: UIButton = Self.makeButton(title: "  next month  > ", target: self)

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.calendar = NSCalendar.current
        picker.date = Date()
        picker.minimumDate = Self.yyyyMMddDateFromString("1000-12-03")
        picker.maximumDate = Self.yyyyMMddDateFromString("3000-12-03")
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
    }

    @objc private func buttonPressed(_ sender: UIButton) {
        switch sender {
        case previousButton:
            calendarView.scrollToPreviousSection()
            print("previousButton")
        case nextButton:
            calendarView.scrollToNextSection()
            print("nextButton")
        case todayButton:
            calendarView.scrollToToday()
            print("todayButton")
        default:
            fatalError("Invalid button pressed")
        }
    }

    @objc private func pickerValueChanged() {
        print("datePicker.date:", datePicker.date)
        calendarView.scrollToDate(datePicker.date, animated: true)
    }
}

extension ViewController: FCalendarDataSource {
    func startDate() -> Date? { minimumDate }
    func endDate() -> Date? { maximumDate }
}

extension ViewController: FCalendarViewDelegate {
    func calendar(_ calendar: FCalendarView, canSelectDate date: Date) -> Bool {
        true
    }
    func calendar(_ calendar: FCalendarView, didScrollToMonth date: Date) {
        print(#function, date)
        currentMonthDate = date
    }
    func calendar(_ calendar: FCalendarView, didSelectDate date: Date) {
        print(#function, date)
    }
    func calendar(_ calendar: FCalendarView, didDeselectDate date: Date) {
        print(#function, date)
    }
}
