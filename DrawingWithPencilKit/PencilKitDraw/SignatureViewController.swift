/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`SignatureViewController` shows the signature pane.
*/

/// The signature pane is an example of a canvas that may not want a tool palette. By
/// setting itself as first responder, but not associating itself with a tool palette, the
/// signature pane canvas ensures that the palette hides when it becomes first responder.

import UIKit
import PencilKit

class SignatureViewController: UIViewController {
    
    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet weak var colorSegmentedControl: UISegmentedControl!
    
    /// Data model for the drawing displayed by this view controller.
    var dataModelController: DataModelController!
    
    // MARK: View Life Cycle
    
    /// Set up the drawing initially.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            // Both finger and pencil are always allowed on this canvas.
            canvasView.drawingPolicy = .anyInput
        }
        
        // Get the signature drawing from the data model.
        canvasView.drawing = dataModelController.signature
        colorChanged(self)
        
        // Note that no tool picker is associated with the signature canvas.
        // As soon as the canvas view becomes first responder, the tool picker
        // shown by the main drawing canvas will hide.
        canvasView.becomeFirstResponder()
    }
    
    /// When the view is removed, save the modified signature drawing.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataModelController.signature = canvasView.drawing
        dataModelController.saveDataModel()
    }
    
    // MARK: Actions
    
    /// Action method: Set black or blue ink.
    @IBAction func colorChanged(_ sender: Any) {
        let colors: [UIColor] = [.black, .blue]
        let selectedColor = colors[colorSegmentedControl.selectedSegmentIndex]
        canvasView.tool = PKInkingTool(.pen, color: selectedColor, width: 20)
    }
    
    /// Action method: Clear the signature drawing.
    @IBAction func clearSignature(_ sender: Any) {
        canvasView.drawing = PKDrawing()
    }
}
