import UIKit
import SnapKit

final class CalendarCell: UICollectionViewCell {

    let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        #warning("DEL")
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.backgroundColor = .lightGray
        return label
    }()

    let underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.isHidden = true
        return view
    }()

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

    private func setup() {
        [textLabel, underlineView].forEach(contentView.addSubview(_:))
        textLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        underlineView.snp.makeConstraints {
            $0.leading.bottom.trailing.equalToSuperview().inset(2)
            $0.height.equalTo(2)
        }
    }
}
