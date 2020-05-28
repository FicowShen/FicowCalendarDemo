import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: String(describing: CalendarCell.self))
            collectionView.dataSource = self
            collectionView.delegate = self
        }
    }

    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    let calendar = XOCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()

        calendar.reloadSections()
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender {
        case previousButton:
            print("previousButton")
        case nextButton:
            print("nextButton")
        default:
            fatalError()
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return calendar.numberOfMonths
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 42
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CalendarCell.self), for: indexPath) as? CalendarCell else {
            fatalError("Dequeue CalendarCell failed.")
        }
        cell.textLabel.text = indexPath.description
        return cell
    }

}

extension ViewController: UICollectionViewDelegate {

}
