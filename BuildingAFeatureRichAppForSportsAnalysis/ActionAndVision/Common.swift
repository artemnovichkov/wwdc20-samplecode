/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This is a collection of common data types, constants and helper functions used in the app.
*/

import UIKit
import Vision

enum ThrowType: String, CaseIterable {
    case overhand = "Overhand"
    case underleg = "Underleg"
    case underhand = "Underhand"
    case none = "None"
}

enum Scoring: Int {
    case zero = 0
    case one = 1
    case three = 3
    case five = 5
    case fifteen = 15
}
struct ThrowMetrics {
    var score = Scoring.zero
    var releaseSpeed = 0.0
    var releaseAngle = 0.0
    var throwType = ThrowType.none
    var finalBagLocation: CGPoint = .zero

    mutating func updateThrowType(_ type: ThrowType) {
        throwType = type
    }

    mutating func updateFinalBagLocation(_ location: CGPoint) {
        finalBagLocation = location
    }

    mutating func updateMetrics(newScore: Scoring, speed: Double, angle: Double) {
        score = newScore
        releaseSpeed = speed
        releaseAngle = angle
    }
}

struct PlayerStats {
    var totalScore = 0
    var throwCount = 0
    var topSpeed = 0.0
    var avgSpeed = 0.0
    var releaseAngle = 0.0
    var avgReleaseAngle = 0.0
    var poseObservations = [VNRecognizedPointsObservation]()
    var throwPaths = [CGPath]()
    
    mutating func reset() {
        topSpeed = 0
        avgSpeed = 0
        totalScore = 0
        throwCount = 0
        releaseAngle = 0
        poseObservations = []
    }

    mutating func resetObservations() {
        poseObservations = []
    }

    mutating func adjustMetrics(score: Scoring, speed: Double, releaseAngle: Double, throwType: ThrowType) {
        throwCount += 1
        totalScore += score.rawValue
        avgSpeed = (avgSpeed * Double(throwCount - 1) + speed) / Double(throwCount)
        avgReleaseAngle = (avgReleaseAngle * Double(throwCount - 1) + releaseAngle) / Double(throwCount)
        if speed > topSpeed {
            topSpeed = speed
        }
    }

    mutating func storePath(_ path: CGPath) {
        throwPaths.append(path)
    }

    mutating func storeObservation(_ observation: VNRecognizedPointsObservation) {
        if poseObservations.count >= GameConstants.maxPoseObservations {
            poseObservations.removeFirst()
        }
        poseObservations.append(observation)
    }

    mutating func getReleaseAngle() -> Double {
        if !poseObservations.isEmpty {
            let observationCount = poseObservations.count
            let postReleaseObservationCount = GameConstants.trajectoryLength + GameConstants.maxTrajectoryInFlightPoseObservations
            let keyFrameForReleaseAngle = observationCount > postReleaseObservationCount ? observationCount - postReleaseObservationCount : 0
            let observation = poseObservations[keyFrameForReleaseAngle]
            let (rightElbow, rightWrist) = armJoints(for: observation)
            // Release angle is computed by measuring the angle forearm (elbow to wrist) makes with the horizontal
            releaseAngle = rightElbow.angleFromHorizontal(to: rightWrist)
        }
        return releaseAngle
    }

    mutating func getLastThrowType() -> ThrowType {
        guard let actionClassifier = try? PlayerActionClassifier(configuration: MLModelConfiguration()),
              let poseMultiArray = prepareInputWithObservations(poseObservations),
              let predictions = try? actionClassifier.prediction(poses: poseMultiArray),
              let throwType = ThrowType(rawValue: predictions.label.capitalized) else {
            return .none
        }
        return throwType
    }
}

struct GameConstants {
    static let maxThrows = 8
    static let newGameTimer = 5
    static let boardLength = 1.22
    static let trajectoryLength = 10
    // minimumObjectSize is calculated as (radius of object to be detected / buffer width)
    static let minimumObjectSize = Float(6.0 / 1920)
    static let maxPoseObservations = 45
    static let noObservationFrameLimit = 20
    static let maxDistanceWithCurrentTrajectory: CGFloat = 250
    static let maxTrajectoryInFlightPoseObservations = 10
}

let jointsOfInterest: [VNRecognizedPointKey] = [
    .bodyLandmarkKeyRightWrist,
    .bodyLandmarkKeyRightElbow,
    .bodyLandmarkKeyRightShoulder,
    .bodyLandmarkKeyRightHip,
    .bodyLandmarkKeyRightKnee,
    .bodyLandmarkKeyRightAnkle
]

func armJoints(for observation: VNRecognizedPointsObservation) -> (CGPoint, CGPoint) {
    var rightElbow = CGPoint(x: 0, y: 0)
    var rightWrist = CGPoint(x: 0, y: 0)

    guard let identifiedPoints = try? observation.recognizedPoints(forGroupKey: .all) else {
        return (rightElbow, rightWrist)
    }
    for (key, point) in identifiedPoints where point.confidence > 0.1 {
        switch key {
        case .bodyLandmarkKeyRightElbow:
            rightElbow = point.location
        case .bodyLandmarkKeyRightWrist:
            rightWrist = point.location
        default:
            break
        }
    }
    return (rightElbow, rightWrist)
}

func getBodyJointsFor(observation: VNRecognizedPointsObservation) -> ([String: CGPoint]) {
    var joints = [String: CGPoint]()
    guard let identifiedPoints = try? observation.recognizedPoints(forGroupKey: .all) else {
        return joints
    }
    for (key, point) in identifiedPoints {
        guard point.confidence > 0.1 else { continue }
        if jointsOfInterest.contains(key) {
            joints[key.rawValue] = point.location
        }
    }
    return joints
}

// MARK: - Pipeline warmup

func warmUpVisionPipeline() {
    // In order to preload the models and all associated resources
    // we perform all Vision requests used in the app on a small image (we use one of the assets bundled with our app).
    // This allows to avoid any model loading/compilation costs later when we run these requests on real time video input.
    guard let image = #imageLiteral(resourceName: "Score1").cgImage,
          let detectorModel = try? GameBoardDetector(configuration: MLModelConfiguration()).model,
          let boardDetectionRequest = try? VNCoreMLRequest(model: VNCoreMLModel(for: detectorModel)) else {
        return
    }
    let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try? handler.perform([bodyPoseRequest, boardDetectionRequest])
}

// MARK: - Activity Classification Helpers

func prepareInputWithObservations(_ observations: [VNRecognizedPointsObservation]) -> MLMultiArray? {
    let numAvailableFrames = observations.count
    let observationsNeeded = 45
    var multiArrayBuffer = [MLMultiArray]()

    for frameIndex in 0 ..< min(numAvailableFrames, observationsNeeded) {
        let pose = observations[frameIndex]
        do {
            let oneFrameMultiArray = try pose.keypointsMultiArray()
            multiArrayBuffer.append(oneFrameMultiArray)
        } catch {
            continue
        }
    }
    
    // If poseWindow does not have enough frames (45) yet, we need to pad 0s
    if numAvailableFrames < observationsNeeded {
        for _ in 0 ..< (observationsNeeded - numAvailableFrames) {
            do {
                let oneFrameMultiArray = try MLMultiArray(shape: [1, 3, 18], dataType: .double)
                try resetMultiArray(oneFrameMultiArray)
                multiArrayBuffer.append(oneFrameMultiArray)
            } catch {
                continue
            }
        }
    }
    return MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float)
}

func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Double = 0.0) throws {
    let pointer = try UnsafeMutableBufferPointer<Double>(predictionWindow)
    pointer.initialize(repeating: value)
}

// MARK: - Helper extensions

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(x - point.x, y - point.y)
    }
    
    func angleFromHorizontal(to point: CGPoint) -> Double {
        let angle = atan2(point.y - y, point.x - x)
        let deg = abs(angle * (180.0 / CGFloat.pi))
        return Double(round(100 * deg) / 100)
    }
}

extension CGAffineTransform {
    static var verticalFlip = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
}

extension UIBezierPath {
    convenience init(cornersOfRect borderRect: CGRect, cornerSize: CGSize, cornerRadius: CGFloat) {
        self.init()
        let cornerSizeH = cornerSize.width
        let cornerSizeV = cornerSize.height
        // top-left
        move(to: CGPoint(x: borderRect.minX, y: borderRect.minY + cornerSizeV + cornerRadius))
        addLine(to: CGPoint(x: borderRect.minX, y: borderRect.minY + cornerRadius))
        addArc(withCenter: CGPoint(x: borderRect.minX + cornerRadius, y: borderRect.minY + cornerRadius),
               radius: cornerRadius,
               startAngle: CGFloat.pi,
               endAngle: -CGFloat.pi / 2,
               clockwise: true)
        addLine(to: CGPoint(x: borderRect.minX + cornerSizeH + cornerRadius, y: borderRect.minY))
        // top-right
        move(to: CGPoint(x: borderRect.maxX - cornerSizeH - cornerRadius, y: borderRect.minY))
        addLine(to: CGPoint(x: borderRect.maxX - cornerRadius, y: borderRect.minY))
        addArc(withCenter: CGPoint(x: borderRect.maxX - cornerRadius, y: borderRect.minY + cornerRadius),
               radius: cornerRadius,
               startAngle: -CGFloat.pi / 2,
               endAngle: 0,
               clockwise: true)
        addLine(to: CGPoint(x: borderRect.maxX, y: borderRect.minY + cornerSizeV + cornerRadius))
        // bottom-right
        move(to: CGPoint(x: borderRect.maxX, y: borderRect.maxY - cornerSizeV - cornerRadius))
        addLine(to: CGPoint(x: borderRect.maxX, y: borderRect.maxY - cornerRadius))
        addArc(withCenter: CGPoint(x: borderRect.maxX - cornerRadius, y: borderRect.maxY - cornerRadius),
               radius: cornerRadius,
               startAngle: 0,
               endAngle: CGFloat.pi / 2,
               clockwise: true)
        addLine(to: CGPoint(x: borderRect.maxX - cornerSizeH - cornerRadius, y: borderRect.maxY))
        // bottom-left
        move(to: CGPoint(x: borderRect.minX + cornerSizeH + cornerRadius, y: borderRect.maxY))
        addLine(to: CGPoint(x: borderRect.minX + cornerRadius, y: borderRect.maxY))
        addArc(withCenter: CGPoint(x: borderRect.minX + cornerRadius,
                                   y: borderRect.maxY - cornerRadius),
               radius: cornerRadius,
               startAngle: CGFloat.pi / 2,
               endAngle: CGFloat.pi,
               clockwise: true)
        addLine(to: CGPoint(x: borderRect.minX, y: borderRect.maxY - cornerSizeV - cornerRadius))
    }
}

// MARK: - Errors

enum AppError: Error {
    case captureSessionSetup(reason: String)
    case createRequestError(reason: String)
    case videoReadingError(reason: String)
    
    static func display(_ error: Error, inViewController viewController: UIViewController) {
        if let appError = error as? AppError {
            appError.displayInViewController(viewController)
        } else {
            print(error)
        }
    }
    
    func displayInViewController(_ viewController: UIViewController) {
        let title: String?
        let message: String?
        switch self {
        case .captureSessionSetup(let reason):
            title = "AVSession Setup Error"
            message = reason
        case .createRequestError(let reason):
            title = "Error Creating Vision Request"
            message = reason
        case .videoReadingError(let reason):
            title = "Error Reading Recorded Video."
            message = reason
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        viewController.present(alert, animated: true)
    }
}
