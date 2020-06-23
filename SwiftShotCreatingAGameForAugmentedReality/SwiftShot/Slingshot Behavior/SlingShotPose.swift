/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Defines the pose of a slingshot rope at a given time.
*/

import simd

// The pose provides positions and tangents along the rope
// as well as upvector information.
// The SlingShotPose further provides methods to interpolate positions,
// tangents or full transforms along the rope.
class SlingShotPose {
    
    var positions: [SIMD3<Float>] = [] // Positions along the rope
    var tangents: [SIMD3<Float>] = [] // Tangents along the rope
    var lengths: [Float] = [] // Accumulated length along the rope [0, lengthFirstSegments, ..., totalLength]
    var upVector = SIMD3<Float>(0, 1, 0) // Vector used to compute orientation of each segment
    
    private var lastIndex: Int = 0

    // returns the total length of the slingshot rope
    var totalLength: Float {
        return lengths[lengths.count - 1]
    }
    
    private func findIndex(_ l: Float) -> Float {
        
        if l <= 0 {
            lastIndex = 0
            return 0
        }
        
        if l >= totalLength {
            lastIndex = lengths.count - 2
            return 1
        }

        while lengths[lastIndex] > l {
            lastIndex -= 1
        }

        while lengths[lastIndex + 1] < l {
            lastIndex += 1
        }

        return (l - lengths[lastIndex]) / (lengths[lastIndex + 1] - lengths[lastIndex])

    }
    
    // returns the interpolated position at a given length (l from 0.0 to totalLength)
    func position(at l: Float) -> SIMD3<Float> {
        let s = findIndex(l)
        return mix(positions[lastIndex], positions[lastIndex + 1], t: SIMD3<Float>(repeating: s))
    }
    
    // returns the position for a given index
    func positionForIndex(_ index: Int) -> SIMD3<Float> {
        return positions[index]
    }
    
    // returns the interpolated tangent at a given length (l from 0.0 to totalLength)
    func tangent(at l: Float) -> SIMD3<Float> {
        let s = findIndex(l)
        return normalize(mix(tangents[lastIndex], tangents[lastIndex + 1], t: SIMD3<Float>(repeating: s)))
    }
    
    // returns the interpolated transform at a given length (l from 0.0 to totalLength)
    func transform(at l: Float) -> float4x4 {

        let p = position(at: l)
        let x = tangent(at: l)
        var y = normalize(upVector)
        let z = normalize(cross(x, y))
        y = normalize(cross(z, x))
        
        let rot = simd_float3x3(x, y, z)
        let q = simd_quatf(rot)
        var m = float4x4(q)
        m.translation = p
        
        return m

    }
    
    // returns the distance to the previous segment for a given index
    func distanceToPrev(_ index: Int) -> Float {
        return lengths[index] - lengths[index - 1]
    }

    // returns the distance to the next segment for a given index
    func distanceToNext(_ index: Int) -> Float {
        return lengths[index + 1] - lengths[index]
    }
}
