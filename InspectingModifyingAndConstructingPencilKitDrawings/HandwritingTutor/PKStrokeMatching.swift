/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The matching algorithm for PKStrokes.
*/

import PencilKit

extension CGPoint {
    var length: CGFloat { sqrt(x * x + y * y) }
    
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    func distance(to other: CGPoint) -> CGFloat {
        return (self - other).length
    }
}

extension PKStroke {
    func discreteFrechetDistance(to strokeB: PKStroke, maxThreshold: CGFloat) -> CGFloat {
        // Convert both stroke paths into an array of a max of 50 CGPoints.
        let maxPointCount: CGFloat = 50
        let minParametricStep: CGFloat = 0.2
        let stepSizeA = max(CGFloat(path.count) / maxPointCount, minParametricStep)
        let pathA = path.interpolatedPoints(by: .parametricStep(stepSizeA)).map {
            $0.location.applying(transform)
        }
        let stepSizeB = max(CGFloat(strokeB.path.count) / maxPointCount, minParametricStep)
        let pathB = strokeB.path.interpolatedPoints(by: .parametricStep(stepSizeB)).map { $0.location.applying(strokeB.transform) }
        
        // Compute the discrete Fréchet distance.
        let countA = pathA.count
        let countB = pathB.count
        guard countA > 0 && countB > 0 else { return 0 }
        
        // Use a dictionary, since pruning will eliminate most of the space used in a countA x countB array.
        var memoizedDFD: [Int: CGFloat] = [:]
        
        func recursiveDFD(indexA: Int, indexB: Int, maxThreshold: CGFloat) -> CGFloat {
            let memoizedIndex = indexA + countA * indexB
            // Check that the value has not already been solved.
            if let existingResult = memoizedDFD[memoizedIndex] {
                return existingResult
            }
            
            let result: CGFloat
            
            let pointPairDistance = pathA[indexA].distance(to: pathB[indexB])
            if indexA == 0 && indexB == 0 {
                // If just checking the first two points, the cost is the distance between the points.
                result = pointPairDistance
            } else if pointPairDistance > maxThreshold {
                // Exit early if this value will never be used, this prunes the search tree.
                result = pointPairDistance
            } else if indexB == 0 {
                // If at the start of path B, move towards the start of path A.
                result = Swift.max(recursiveDFD(indexA: indexA - 1, indexB: 0, maxThreshold: maxThreshold), pointPairDistance)
            } else if indexA == 0 {
                // If at the start of path A, move towards the start of path B.
                result = Swift.max(recursiveDFD(indexA: 0, indexB: indexB - 1, maxThreshold: maxThreshold), pointPairDistance)
            } else {
                // Return the minimum of moving towards the start of A, B, or A & B.
                let diagonalDFD = recursiveDFD(indexA: indexA - 1, indexB: indexB - 1, maxThreshold: maxThreshold)
                let leftDFD = recursiveDFD(indexA: indexA - 1, indexB: indexB, maxThreshold: Swift.min(maxThreshold, diagonalDFD))
                let downDFD = recursiveDFD(indexA: indexA, indexB: indexB - 1, maxThreshold: Swift.min(maxThreshold, leftDFD, diagonalDFD))
                let minOfRecursion = Swift.min(leftDFD, diagonalDFD, downDFD)
                result = Swift.max(minOfRecursion, pointPairDistance)
            }
            
            memoizedDFD[memoizedIndex] = result
            return result
        }
        
        let frechetDistance = recursiveDFD(indexA: countA - 1, indexB: countB - 1, maxThreshold: maxThreshold)
		return frechetDistance
	}
}
