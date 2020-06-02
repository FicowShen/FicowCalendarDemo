import UIKit

final class XOCalendarHeaderView: UIView {

    static let fixedHeaderHeight: CGFloat = 52
    static let scrollableHeaderHeight: CGFloat = fixedHeaderHeight/2

    private static func makeLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .rgb(red: 6, green: 25, blue: 41)
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.showBorderWithRandomColor()
        return label
    }

    private let yearLabel = makeLabel()
    private let monthLabel = makeLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup(year: String, month: String) {
        yearLabel.text = year
        monthLabel.text = month
    }

    private func setup() {
        [monthLabel, yearLabel].forEach(addSubview)
        monthLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview()
        }
        yearLabel.snp.makeConstraints {
            $0.leading.equalTo(monthLabel.snp.trailing).offset(8)
            $0.top.bottom.equalToSuperview()
        }
    }
}
