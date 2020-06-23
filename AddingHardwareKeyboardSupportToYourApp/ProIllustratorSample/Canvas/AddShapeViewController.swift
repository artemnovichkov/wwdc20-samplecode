/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller shown when adding a new shape to the canvas.
*/

import UIKit

protocol AddShapeViewControllerDelegate: class {
    func addShapeViewController(_: AddShapeViewController, didSelectShapeStyle style: Shape.Style)
}

class AddShapeViewController: UITableViewController {
    static let shapeCellReuseIdentifier = "shape.cell"
    
    public weak var delegate: AddShapeViewControllerDelegate?
    private var shapeDataSource: UITableViewDiffableDataSource<Int, Shape.Style>?
    
    // Allow this view controller to become the first responder so it can
    // receive keyboard shortcut commands.
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    /// - Tag: EscapeAccelerator
    fileprivate func addKeyCommands() {
        // Let the Escape key and Command-Period (.) cancel actions.
        addKeyCommand(
            UIKeyCommand(
                title: NSLocalizedString("CANCEL", comment: "Cancel discoverability title"),
                action: #selector(didInvokeCancel),
                input: UIKeyCommand.inputEscape
            )
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("ADD SHAPE", comment: "Title for add shape modal screen")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didInvokeCancel))
        
        addKeyCommands()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.shapeCellReuseIdentifier)
        let shapeDataSource = UITableViewDiffableDataSource<Int, Shape.Style>(tableView: tableView) {
        (tableView, indexPath, style) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.shapeCellReuseIdentifier, for: indexPath)
            switch style {
            case .circle:
                cell.imageView?.image = #imageLiteral(resourceName: "circle_icon")
                cell.textLabel?.text = NSLocalizedString("CIRCLE", comment: "Circle shape")
            case .rectangle:
                cell.imageView?.image = #imageLiteral(resourceName: "square_icon")
                cell.textLabel?.text = NSLocalizedString("RECTANGLE", comment: "Rectangle shape")
            }
            
            return cell
        }
        
        tableView.dataSource = shapeDataSource
        
        var snapshot = shapeDataSource.snapshot()
        snapshot.appendSections([ 0 ])
        snapshot.appendItems([ .circle, .rectangle ])
        shapeDataSource.apply(snapshot)
        
        self.shapeDataSource = shapeDataSource
    }
    
    @objc
    func didInvokeCancel(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let dataSource = shapeDataSource else { return }
        
        if let delegate = self.delegate, let shapeStyle = dataSource.itemIdentifier(for: indexPath) {
            delegate.addShapeViewController(self, didSelectShapeStyle: shapeStyle)
        }
    }
}

