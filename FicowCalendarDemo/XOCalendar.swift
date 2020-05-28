import UIKit

final class XOCalendar {

    private static let dateFormatter = DateFormatter()

    private static func yyyyMMddDateFromString(_ s: String) -> Date? {
        Self.dateFormatter.dateFormat = "yyyy-MM-dd"
        return Self.dateFormatter.date(from: s)
    }

    let gregorian = Calendar(identifier: .gregorian)

    var minimumDate = yyyyMMddDateFromString("2019-02-03") ?? Date()
    var maximumDate = yyyyMMddDateFromString("2021-04-10") ?? Date()

    var numberOfMonths = 1

    func reloadSections() {
        guard let month = gregorian.dateComponents([.month], from: minimumDate, to: maximumDate).month
            else { return }
        numberOfMonths = month + 1
    }

}

extension Calendar {
    func firstDayOfMonth(_ date: Date) -> Date {
        var components = self.dateComponents([.era, .year, .month, .day, .hour], from: date)
        components.day = 1
        return self.date(from: components)
            !? (Date(), "Cannot get firstDayOfMonth of \(date)")
    }
}
