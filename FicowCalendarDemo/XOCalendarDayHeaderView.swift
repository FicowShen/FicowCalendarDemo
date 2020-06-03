import UIKit

final class XOCalendarDayHeaderView: UIStackView {

    let weekdaySymbols: [String]

    /// Default to Sunday, 1 means Monday and so on
    var firstWeekday: XOCalendarDay = .sunday {
        didSet {
            subviews.forEach { $0.removeFromSuperview() }
            setup()
        }
    }

    init(weekdaySymbols: [String], firstWeekday: XOCalendarDay = .sunday) {
        self.weekdaySymbols = weekdaySymbols
        self.firstWeekday = firstWeekday
        super.init(frame: .zero)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        setup()
    }

    private func setup() {
        distribution = .fillEqually
        axis = .horizontal
        for index in 0..<7 {
            let day = weekdaySymbols[(index + firstWeekday.rawValue) % 7]
            let weekdayLabel = UILabel()
            weekdayLabel.isOpaque = false
            weekdayLabel.backgroundColor = .white
            weekdayLabel.font = .systemFont(ofSize: 12, weight: .bold)
            weekdayLabel.text = day.prefix(2).uppercased()
            weekdayLabel.textColor = .rgb(red: 109, green: 113, blue: 121)
            weekdayLabel.textAlignment = .center
            weekdayLabel.showBorderWithRandomColor()
            addArrangedSubview(weekdayLabel)
        }
    }
}
