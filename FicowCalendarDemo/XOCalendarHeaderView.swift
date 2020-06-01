import UIKit

final class XOCalendarHeaderView: UIView {
    private static func makeLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 18)
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
        #warning("DEL")
        backgroundColor = .lightGray
        clipsToBounds = true

        [monthLabel, yearLabel].forEach(addSubview)
        monthLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().inset(32)
        }
        yearLabel.snp.makeConstraints {
            $0.leading.equalTo(monthLabel.snp.trailing).offset(8)
            $0.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview().inset(32)
        }
    }
}
