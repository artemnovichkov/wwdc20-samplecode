/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller responsible for the setup state of the game.
     The setup consists of the following tasks:
     - board detection
     - board placement check
     - board contours analysis
     - scene stability check
*/

import UIKit
import AVFoundation
import Vision

class SetupViewController: UIViewController {

    @IBOutlet var statusLabel: OverlayLabel!
 
    private let gameManager = GameManager.shared
    private let boardLocationGuide = BoundingBoxView()
    private let boardBoundingBox = BoundingBoxView()

    private var boardDetectionRequest: VNCoreMLRequest!
    private let boardDetectionMinConfidence: VNConfidence = 0.6
    
    enum SceneSetupStage {
        case detectingBoard
        case detectingBoardPlacement
        case detectingSceneStability
        case detectingBoardContours
        case setupComplete
    }

    private var setupStage = SceneSetupStage.detectingBoard
    
    enum SceneStabilityResult {
        case unknown
        case stable
        case unstable
    }
    
    private let sceneStabilityRequestHandler = VNSequenceRequestHandler()
    private let sceneStabilityRequiredHistoryLength = 15
    private var sceneStabilityHistoryPoints = [CGPoint]()
    private var previousSampleBuffer: CMSampleBuffer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        boardLocationGuide.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        boardLocationGuide.borderWidth = 3
        boardLocationGuide.borderCornerRadius = 4
        boardLocationGuide.borderCornerSize = 30
        boardLocationGuide.backgroundOpacity = 0.25
        boardLocationGuide.isHidden = true
        view.addSubview(boardLocationGuide)
        boardBoundingBox.borderColor = #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)
        boardBoundingBox.borderWidth = 2
        boardBoundingBox.borderCornerRadius = 4
        boardBoundingBox.borderCornerSize = 0
        boardBoundingBox.backgroundOpacity = 0.45
        boardBoundingBox.isHidden = true
        view.addSubview(boardBoundingBox)
        updateSetupState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            // Create Vision request based on CoreML model
            let model = try VNCoreMLModel(for: GameBoardDetector(configuration: MLModelConfiguration()).model)
            boardDetectionRequest = VNCoreMLRequest(model: model)
            // Since board is close to the side of a landscape image,
            // we need to set crop and scale option to scaleFit.
            // By default vision request will run on centerCrop.
            boardDetectionRequest.imageCropAndScaleOption = .scaleFit
        } catch {
            let error = AppError.createRequestError(reason: "Could not create Vision request for board detector")
            AppError.display(error, inViewController: self)
        }
    }
    
    func updateBoundingBox(_ boundingBox: BoundingBoxView, withViewRect rect: CGRect?, visionRect: CGRect) {
        DispatchQueue.main.async {
            boundingBox.frame = rect ?? .zero
            boundingBox.visionRect = visionRect
            if rect == nil {
                boundingBox.perform(transition: .fadeOut, duration: 0.1)
            } else {
                boundingBox.perform(transition: .fadeIn, duration: 0.1)
            }
        }
    }
    
    func updateSetupState() {
        let boardBox = boardBoundingBox
        DispatchQueue.main.async {
            switch self.setupStage {
            case .detectingBoard:
                self.statusLabel.text = "Locating Board"
            case .detectingBoardPlacement:
                // Board placement guide is shown only when using camera feed.
                // Otherwise we always assume the board is placed correctly.
                var boxPlacedCorrectly = true
                if !self.boardLocationGuide.isHidden {
                    boxPlacedCorrectly = boardBox.containedInside(self.boardLocationGuide)
                }
                boardBox.borderColor = boxPlacedCorrectly ? #colorLiteral(red: 0.4641711116, green: 1, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 1)
                if boxPlacedCorrectly {
                    self.statusLabel.text = "Keep Device Stationary"
                    self.setupStage = .detectingSceneStability
                } else {
                    self.statusLabel.text = "Place Board into the Box"
                }
            case .detectingSceneStability:
                switch self.sceneStability {
                case .unknown:
                    break
                case .unstable:
                    self.previousSampleBuffer = nil
                    self.sceneStabilityHistoryPoints.removeAll()
                    self.setupStage = .detectingBoardPlacement
                case .stable:
                    self.setupStage = .detectingBoardContours
                }
            default:
                break
            }
        }
    }
    
    func analyzeBoardContours(_ contours: [VNContour]) -> (edgePath: CGPath, holePath: CGPath)? {
        // Simplify contours and ignore resulting contours with less than 3 points.
        let polyContours = contours.compactMap { (contour) -> VNContour? in
            guard let polyContour = try? contour.polygonApproximation(withEpsilon: 0.01),
                  polyContour.pointCount >= 3 else {
                return nil
            }
            return polyContour
        }
        // Board contour is the contour with the largest amount of points.
        guard let boardContour = polyContours.max(by: { $0.pointCount < $1.pointCount }) else {
            return nil
        }
        // First, find the board edge which is the longest diagonal segment of the contour
        // located in the top part of the board's bounding box.
        let contourPoints = boardContour.normalizedPointsArray
        let diagonalThreshold = CGFloat(0.02)
        var largestDiff = CGFloat(0)
        let boardPath = UIBezierPath()
        let countLessOne = contourPoints.count - 1
        // Both points should be in the top 2/3rds of the board's bounding box.
        // Additionally one of them should be in the left half
        // and the other on in the right half of the board's bounding box.
        for (point1, point2) in zip(contourPoints.prefix(countLessOne), contourPoints.suffix(countLessOne)) where
            min(point1.x, point2.x) < 0.5 && max(point1.x, point2.x) > 0.5 && point1.y >= 0.3 && point2.y >= 0.3 {
            let diffX = abs(point1.x - point2.x)
            let diffY = abs(point1.y - point2.y)
            guard diffX > diagonalThreshold && diffY > diagonalThreshold else {
                // This is not a diagonal line, skip this segment.
                continue
            }
            if diffX + diffY > largestDiff {
                largestDiff = diffX + diffY
                boardPath.removeAllPoints()
                boardPath.move(to: point1)
                boardPath.addLine(to: point2)
            }
        }
        guard largestDiff > 0 else {
            return nil
        }
        // Finally, find the hole contorur which should be located in the top right quadrant
        // of the board's bounding box.
        var holePath: CGPath?
        for contour in polyContours where contour != boardContour {
            let normalizedPath = contour.normalizedPath
            let normalizedBox = normalizedPath.boundingBox
            if normalizedBox.minX >= 0.5 && normalizedBox.minY >= 0.5 {
                holePath = normalizedPath
                break
            }
        }
        // Return nil if we failed to find the hole.
        guard let detectedHolePath = holePath else {
            return nil
        }
        
        return (boardPath.cgPath, detectedHolePath)
    }
    
    var sceneStability: SceneStabilityResult {
        // Determine if we have enough evidence of stability.
        guard sceneStabilityHistoryPoints.count > sceneStabilityRequiredHistoryLength else {
            return .unknown
        }
        
        // Calculate the moving average by adding up values of stored points
        // returned by VNTranslationalImageRegistrationRequest for both axis
        var movingAverage = CGPoint.zero
        movingAverage.x = sceneStabilityHistoryPoints.map { $0.x }.reduce(.zero, +)
        movingAverage.y = sceneStabilityHistoryPoints.map { $0.y }.reduce(.zero, +)
        // Get the moving distance by adding absolute moving average values of individual axis
        let distance = abs(movingAverage.x) + abs(movingAverage.y)
        // If the distance is not significant enough to affect the game analysis (less that 10 points),
        // we declare the scene being stable
        return (distance < 10 ? .stable : .unstable)
    }
}

extension SetupViewController: CameraViewControllerOutputDelegate {
    func cameraViewController(_ controller: CameraViewController, didReceiveBuffer buffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        do {
            switch setupStage {
            case .setupComplete:
                // Setup is complete - no reason to run vision requests.
                return
            case .detectingSceneStability:
                try checkSceneStability(controller, buffer, orientation)
            case .detectingBoardContours:
                try detectBoardContours(controller, buffer, orientation)
            case .detectingBoard, .detectingBoardPlacement:
                try detectBoard(controller, buffer, orientation)
            }
            updateSetupState()
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    private func checkSceneStability(_ controller: CameraViewController, _ buffer: CMSampleBuffer, _ orientation: CGImagePropertyOrientation) throws {
        guard let previousBuffer = self.previousSampleBuffer else {
            self.previousSampleBuffer = buffer
            return
        }
        let registrationRequest = VNTranslationalImageRegistrationRequest(targetedCMSampleBuffer: buffer)
        try sceneStabilityRequestHandler.perform([registrationRequest], on: previousBuffer, orientation: orientation)
        self.previousSampleBuffer = buffer
        if let alignmentObservation = registrationRequest.results?.first as? VNImageTranslationAlignmentObservation {
            let transform = alignmentObservation.alignmentTransform
            sceneStabilityHistoryPoints.append(CGPoint(x: transform.tx, y: transform.ty))
        }
    }

    fileprivate func detectBoard(_ controller: CameraViewController, _ buffer: CMSampleBuffer, _ orientation: CGImagePropertyOrientation) throws {
        // This is where we detect the board.
        let visionHandler = VNImageRequestHandler(cmSampleBuffer: buffer, orientation: orientation, options: [:])
        try visionHandler.perform([boardDetectionRequest])
        var rect: CGRect?
        var visionRect = CGRect.null
        if let results = boardDetectionRequest.results as? [VNDetectedObjectObservation] {
            // Filter out classification results with low confidence
            let filteredResults = results.filter { $0.confidence > boardDetectionMinConfidence }
            // Since the model is trained to detect only one object class (game board)
            // there is no need to look at labels. If there is at least one result - we got the board.
            if !filteredResults.isEmpty {
                visionRect = filteredResults[0].boundingBox
                rect = controller.viewRectForVisionRect(visionRect)
            }
        }
        // Show board placement guide only when using camera feed.
        if gameManager.recordedVideoSource == nil {
            let guideVisionRect = CGRect(x: 0.7, y: 0.3, width: 0.28, height: 0.3)
            let guideRect = controller.viewRectForVisionRect(guideVisionRect)
            updateBoundingBox(boardLocationGuide, withViewRect: guideRect, visionRect: guideVisionRect)
        }
        updateBoundingBox(boardBoundingBox, withViewRect: rect, visionRect: visionRect)
        // If rect is nil we need to keep looking for the board, otherwise check the board placement
        self.setupStage = (rect == nil) ? .detectingBoard : .detectingBoardPlacement
    }
    
    private func detectBoardContours(_ controller: CameraViewController, _ buffer: CMSampleBuffer, _ orientation: CGImagePropertyOrientation) throws {
        let visionHandler = VNImageRequestHandler(cmSampleBuffer: buffer, orientation: orientation, options: [:])
        let contoursRequest = VNDetectContoursRequest()
        contoursRequest.regionOfInterest = boardBoundingBox.visionRect
        try visionHandler.perform([contoursRequest])
        if let result = contoursRequest.results?.first as? VNContoursObservation {
            // Perform analysis of the top level contours in order to find board edge path and hole path.
            guard let subpaths = analyzeBoardContours(result.topLevelContours) else {
                return
            }
            DispatchQueue.main.sync {
                // Save board region
                self.gameManager.boardRegion = boardBoundingBox.frame
                // Calculate board length based on the bounding box of the edge.
                let edgeNormalizedBB = subpaths.edgePath.boundingBox
                // Convert normalized bounding box size to points.
                let edgeSize = CGSize(width: edgeNormalizedBB.width * boardBoundingBox.frame.width,
                                      height: edgeNormalizedBB.height * boardBoundingBox.frame.height)
                // Calculate the length of the edge in points.
                let boardLength = hypot(edgeSize.width, edgeSize.height)
                // Divide board length in meters by board length in points.
                self.gameManager.pointToMeterMultiplier = GameConstants.boardLength / Double(boardLength)
                if let imageBuffer = CMSampleBufferGetImageBuffer(buffer) {
                    let imageData = CIImage(cvImageBuffer: imageBuffer).oriented(orientation)
                    self.gameManager.previewImage = UIImage(ciImage: imageData)
                }
                // Get the bounding box of hole in CoreGraphics coordinates
                // and convert it to Vision coordinates by flipping vertically.
                var holeRect = subpaths.holePath.boundingBox
                holeRect.origin.y = 1 - holeRect.origin.y - holeRect.height
                // Because we used region of interest in the request above,
                // the normalized coordinates of the returned contours are relative to that region.
                // Convert hole region to Vision coordinates of entire image
                let boardRect = boardBoundingBox.visionRect
                let normalizedHoleRegion = CGRect(
                        x: boardRect.origin.x + holeRect.origin.x * boardRect.width,
                        y: boardRect.origin.y + holeRect.origin.y * boardRect.height,
                        width: holeRect.width * boardRect.width,
                        height: holeRect.height * boardRect.height)
                // Now convert hole region from normalized Vision coordinates
                // to UIKit coordinates and save it.
                self.gameManager.holeRegion = controller.viewRectForVisionRect(normalizedHoleRegion)
                // Combine board's edge and hole paths to highlight them on the screen.
                let highlightPath = UIBezierPath(cgPath: subpaths.edgePath)
                highlightPath.append(UIBezierPath(cgPath: subpaths.holePath))
                boardBoundingBox.visionPath = highlightPath.cgPath
                boardBoundingBox.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.199807363)
                self.gameManager.stateMachine.enter(GameManager.DetectedBoardState.self)
            }
        }
    }
}

extension SetupViewController: GameStateChangeObserver {
    func gameManagerDidEnter(state: GameManager.State, from previousState: GameManager.State?) {
        switch state {
        case is GameManager.DetectedBoardState:
            setupStage =  .setupComplete
            statusLabel.text = "Board Detected"
            statusLabel.perform(transitions: [.popUp, .popOut], durations: [0.25, 0.12], delayBetween: 1.5) {
                self.gameManager.stateMachine.enter(GameManager.DetectingPlayerState.self)
            }
        default:
            break
        }
    }
}

extension VNContour {
    var normalizedPointsArray: [CGPoint] {
        let pointsBuffer = UnsafeBufferPointer<simd_float2>(start: normalizedPoints, count: Int(pointCount))
        return Array(pointsBuffer).map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
    }
}
