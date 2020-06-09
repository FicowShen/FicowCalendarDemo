import UIKit
import SnapKit

final class XOCalendarMonthHeaderView: UICollectionReusableView {

    static let height: CGFloat = 72

    private let headerView = XOCalendarHeaderView()
    private let horizontalInset = XOCalendarView.Layout.weekdayHeaderHorizontalInset

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
        showBorderWithRandomColor()
        addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(32)
            $0.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
    }
}
