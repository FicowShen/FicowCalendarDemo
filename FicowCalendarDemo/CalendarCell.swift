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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(textLabel)
        textLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
