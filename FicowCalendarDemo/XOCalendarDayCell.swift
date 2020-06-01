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
    }

    private func setup() {
        [textLabel, underlineView].forEach(contentView.addSubview(_:))
        textLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        underlineView.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(2)
            $0.leading.trailing.equalToSuperview().inset(4)
            $0.height.equalTo(2)
        }
    }
}
