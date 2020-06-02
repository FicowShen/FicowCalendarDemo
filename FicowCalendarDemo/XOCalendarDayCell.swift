import UIKit
import SnapKit

final class XOCalendarDayCell: UICollectionViewCell {

    private let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .rgb(red: 6, green: 25, blue: 41)
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.showBorderWithRandomColor()
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

    private let underlineView: UIView = {
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
            underlineView.isHidden = !isToday
        }
    }

    var isDayInCurrentSection = false {
        didSet {
            isHidden = !isDayInCurrentSection
//            alpha = isDayInCurrentSection ? 1 : 0.2
//            isUserInteractionEnabled = isDayInCurrentSection
        }
    }

    override var isSelected : Bool {
        didSet {
            selectView.isHidden = !isSelected
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
        underlineView.isHidden = true
        selectView.isHidden = true
        isDayInCurrentSection = false
    }

    private func setup() {
        [selectView, textLabel, underlineView].forEach(contentView.addSubview(_:))
        textLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        underlineView.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(2)
            $0.leading.trailing.equalToSuperview().inset(4)
            $0.height.equalTo(2)
        }
        selectView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(2)
        }
    }
}
