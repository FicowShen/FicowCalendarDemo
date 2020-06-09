import UIKit
import SnapKit

final class XOCalendarDayCell: UICollectionViewCell {

    private static let normalTextColor: UIColor = .rgb(red: 6, green: 25, blue: 41)
    private static let selectedTextColor: UIColor = .white

    private let textLabel: UILabel = {
        let label = UILabel()
        label.layer.masksToBounds = true
        label.layer.borderColor = normalTextColor.cgColor
        label.textColor = normalTextColor
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()

    private let selectView: UIView = {
        let view = UIView()
        view.backgroundColor = .rgb(red: 81, green: 138, blue: 215)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    private let todayView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.isHidden = true
        return view
    }()

    var text = "" {
        didSet {
            textLabel.text = text
        }
    }

    var isToday = false {
        didSet {
            textLabel.layer.borderWidth = isToday ? 1 : 0
        }
    }

    var isDayInCurrentSection = false {
        didSet {
            isHidden = !isDayInCurrentSection
        }
    }

    override var isSelected : Bool {
        didSet {
            selectView.isHidden = !isSelected
            textLabel.textColor = isSelected ? Self.selectedTextColor : Self.normalTextColor
            textLabel.layer.borderColor = textLabel.textColor.cgColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel.text = ""
        todayView.isHidden = true
        selectView.isHidden = true
        isDayInCurrentSection = false
    }

    private func setup() {
        showBorderWithRandomColor()
        [selectView, textLabel, todayView].forEach(contentView.addSubview(_:))
        textLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(6)
        }
        todayView.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(2)
            $0.leading.trailing.equalToSuperview().inset(6)
            $0.height.equalTo(2)
        }
        selectView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(2)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.layoutIfNeeded()
        textLabel.layer.cornerRadius = textLabel.bounds.height / 2
    }
}
