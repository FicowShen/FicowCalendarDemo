import UIKit

extension UIColor {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
}

extension UIView {
    func showBorderWithRandomColor() {
        return;
        let rgb = (1...3).map { _ in CGFloat(Int.random(in: 0...255)) }
        let color = UIColor.rgb(red: rgb[0], green: rgb[1], blue: rgb[2])
        showBorder(color: color, width: 1)
    }
    func showBorder(color: UIColor = .darkGray, width: CGFloat = 1) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
}
