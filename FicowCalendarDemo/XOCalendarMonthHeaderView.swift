import UIKit
import SnapKit

final class XOCalendarMonthHeaderView: UICollectionReusableView {

    private let headerView = XOCalendarHeaderView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup(year: String, month: String) {
        headerView.setup(year: year, month: month)
    }

    private func setup() {
        #warning("DEL")
        backgroundColor = .lightGray
        clipsToBounds = true

        addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
