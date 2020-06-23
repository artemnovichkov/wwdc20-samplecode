/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that manages a canvas of shapes.
*/

import UIKit

/// - Tag: CanvasViewController
class CanvasViewController: UIViewController, AddShapeViewControllerDelegate {
    var selectedFile: IllustrationFile? {
        didSet { reloadSelectedFile() }
    }
    
    var selectedShapeViews: [ShapeView] = []
    var allShapeViews: [ShapeView] = []
    
    var originalMoveLocation: CGPoint?
    var shapeMoveGestureRecognizer: UILongPressGestureRecognizer?
    
    // For moving shapes using keyboard input.
    enum KeyboardMovementDelta: CGFloat {
        case normal = 1.0
        case significant = 10.0
    }
    
    var shapeMoveTimer: Timer?
    var shapeMovementDirection: UIRectEdge?
    static let shapeMovementInterval = TimeInterval(0.1)
    
    private var addBarButtonItem: UIBarButtonItem?
    
    // Allow this view controller to become the first responder so it can
    // receive keyboard shortcut commands.
    override var canBecomeFirstResponder: Bool {
        return true
    }
        
    override func viewDidLoad() {
        let shapeMoveGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didRecognizeMoveGesture))
        
        // To start recognizing a move immediately, set minimumPressDuration to
        // zero.
        shapeMoveGestureRecognizer.minimumPressDuration = 0
        
        view.addGestureRecognizer(shapeMoveGestureRecognizer)
        self.shapeMoveGestureRecognizer = shapeMoveGestureRecognizer
        
        // Add a button for adding a shape. The button is disabled by default,
        // and gets enabled when the user selects a file.
        let addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didInvokeAddShape))
        addBarButtonItem.isEnabled = false
        self.addBarButtonItem = addBarButtonItem
        navigationItem.rightBarButtonItem = addBarButtonItem
        
        super.viewDidLoad()
    }
    
    private func addShapeView(_ shapeView: ShapeView) {
        view.addSubview(shapeView)
        allShapeViews.append(shapeView)
    }
    
    private func reloadSelectedFile() {
        addBarButtonItem?.isEnabled = selectedFile != nil
        
        guard let selectedFile = selectedFile else { return }
        
        // Update title
        navigationItem.title = selectedFile.name
        
        deselectAllShapes()
        
        for shapeView in allShapeViews {
            shapeView.removeFromSuperview()
        }
        
        allShapeViews.removeAll()
        
        for shape in selectedFile.shapes {
            let shapeView = ShapeView(shape: shape)
            addShapeView(shapeView)
        }
    }
    
    private func shapeViewAtLocation(_ location: CGPoint) -> ShapeView? {
        return view.hitTest(location, with: nil) as? ShapeView
    }
    
    private func getCurrentTranslationForLocation(_ location: CGPoint) -> CGPoint? {
        guard let originalMoveLocation = originalMoveLocation else { return nil }
        return CGPoint(
            x: location.x - originalMoveLocation.x,
            y: location.y - originalMoveLocation.y
        )
    }
    
    private func selectShapeViewAtLocation(_ location: CGPoint) {
        if let hitShape = shapeViewAtLocation(location) {
            hitShape.isSelected = true
            if !selectedShapeViews.contains(hitShape) {
                selectedShapeViews.append(hitShape)
            }
        }
    }
    
    @objc
    private func didInvokeAddShape(_ sender: Any?) {
        let addShapeViewController = AddShapeViewController(nibName: nil, bundle: nil)
        addShapeViewController.delegate = self
        
        let wrapperNavController = UINavigationController(rootViewController: addShapeViewController)
        present(wrapperNavController, animated: true, completion: nil)
    }
    
    @objc
    private func didRecognizeMoveGesture(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: view)

        switch recognizer.state {
        case .began:
            // Take keyboard focus by becoming the first responder when a
            // gesture begins.
            becomeFirstResponder()
            
            // Check if the Shift key is pressed when the gesture begins. If
            // so, allow moving multiple shapes at once.
            if !recognizer.modifierFlags.contains(.shift) {
                deselectAllShapes()
            }
            
            originalMoveLocation = location
            selectShapeViewAtLocation(location)
        case .changed:
            guard let translation = getCurrentTranslationForLocation(location) else { break }
            
            for selectedShape in selectedShapeViews {
                selectedShape.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            }
        case .ended:
            // Commit the shape locations when the gesture ends.
            guard let translation = getCurrentTranslationForLocation(location) else { break }
            for selectedShape in selectedShapeViews {
                selectedShape.transform = .identity
                selectedShape.center = CGPoint(x: selectedShape.center.x + translation.x, y: selectedShape.center.y + translation.y)
                selectedShape.shape?.rect = selectedShape.frame
            }
            
            originalMoveLocation = nil
        default:
            break
        }
    }
    
    private func deselectAllShapes() {
        for shapeView in selectedShapeViews {
            shapeView.isSelected = false
        }
        
        selectedShapeViews.removeAll()
    }
    
    // MARK: UIResponderStandardEditActions
    
    // To support the standard Select All command, you only need to override
    // the selectAll() method. When this controller is the first responder, the
    // system calls this method when the user presses Command-A or chooses
    // Select All from the macOS menu bar.

    /// - Tag: StandardEditActions
    override func selectAll(_ sender: Any?) {
        for shapeView in allShapeViews {
            shapeView.isSelected = true
            selectedShapeViews.append(shapeView)
        }
    }
    
    // MARK: Add Shape Delegate
    func addShapeViewController(_ addShapeController: AddShapeViewController, didSelectShapeStyle style: Shape.Style) {
        addShapeController.dismiss(animated: true, completion: nil)
        
        guard let selectedFile = selectedFile else { return }
        
        let shape = Shape(rect: CGRect(x: 100.0, y: 100.0, width: 100.0, height: 100.0), style: style, color: .red)
        selectedFile.shapes.append(shape)
        
        let shapeView = ShapeView(shape: shape)
        addShapeView(shapeView)
    }
    
    // MARK: Handling raw keyboard events
    
    static let arrowKeys: [UIKeyboardHIDUsage] = [ .keyboardLeftArrow, .keyboardDownArrow, .keyboardUpArrow, .keyboardRightArrow ]
    private func movementDirectionForKeyPresses(_ presses: Set<UIPress>) -> UIRectEdge? {
        guard let key = presses.first?.key else { return nil }
        
        switch key.keyCode {
        case .keyboardLeftArrow:  return .left
        case .keyboardDownArrow:  return .bottom
        case .keyboardUpArrow:    return .top
        case .keyboardRightArrow: return .right
        default:                  return nil
        }
    }
    
    private func startMovingSelectedShapes(inDirection direction: UIRectEdge, delta: KeyboardMovementDelta) {
        let moveShapes = { (timer: Timer) in
            guard let direction = self.shapeMovementDirection else { return }
            
            var movementDelta = CGPoint.zero
            if direction.contains(.left) {
                movementDelta.x -= delta.rawValue
            }
            if direction.contains(.right) {
                movementDelta.x += delta.rawValue
            }
            if direction.contains(.top) {
                movementDelta.y -= delta.rawValue
            }
            if direction.contains(.bottom) {
                movementDelta.y += delta.rawValue
            }
            
            UIView.animate(withDuration: Self.shapeMovementInterval) {
                for shapeView in self.selectedShapeViews {
                    shapeView.center = CGPoint(x: shapeView.center.x + movementDelta.x, y: shapeView.center.y + movementDelta.y)
                }
            }
        }
        
        if let movementDirection = self.shapeMovementDirection {
            self.shapeMovementDirection = movementDirection.union(direction)
        } else {
            self.shapeMovementDirection = direction
        }
        
        if shapeMoveTimer == nil {
            shapeMoveTimer = Timer.scheduledTimer(withTimeInterval: Self.shapeMovementInterval, repeats: true, block: moveShapes)
        }
        
        moveShapes(shapeMoveTimer!)
    }
    
    private func stopMovingSelectedShapes(inDirection direction: UIRectEdge) {
        guard let currentDirection = self.shapeMovementDirection else { return }
        
        let newShapeMovementDirection = currentDirection.subtracting(direction)
        
        if newShapeMovementDirection.isEmpty {
            shapeMoveTimer?.invalidate()
            shapeMoveTimer = nil
        }
        
        self.shapeMovementDirection = newShapeMovementDirection
    }
    
    /// - Tag: PressesBegan
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key, let movementDirection = movementDirectionForKeyPresses(presses) else {
            return super.pressesBegan(presses, with: event)
        }
        
        var movementDelta: KeyboardMovementDelta = .normal
        
        // If the Shift key is pressed while using the arrow keys, move a more
        // significant amount.
        if key.modifierFlags.contains(.shift) {
            movementDelta = .significant
        }
        
        startMovingSelectedShapes(inDirection: movementDirection, delta: movementDelta)
    }
    
    /// - Tag: PressesEnded
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let movementDirection = movementDirectionForKeyPresses(presses) else { return super.pressesBegan(presses, with: event) }
        stopMovingSelectedShapes(inDirection: movementDirection)
    }
}

extension CanvasViewController: GlobalKeyboardShortcutRespondable {
    func createNewItem(_ sender: Any?) {
        didInvokeAddShape(sender)
    }
    
    func deleteSelectedItem(_: Any?) {
        for selectedShapeView in selectedShapeViews {
            selectedShapeView.removeFromSuperview()
        }
        
        allShapeViews.removeAll { selectedShapeViews.contains($0) }
        deselectAllShapes()
    }
    
    // This is an example of using canPerformAction: to ensure a file is
    // selected before allowing the user to create a new shape.
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(createNewItem) {
            return self.selectedFile != nil
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
}
