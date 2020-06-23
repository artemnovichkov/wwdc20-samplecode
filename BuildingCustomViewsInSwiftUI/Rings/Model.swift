/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data model.
*/

import SwiftUI
import Combine

/// The data model for a single chart ring.
class Ring: ObservableObject {
    /// A single wedge within a chart ring.
    struct Wedge: Equatable {
        /// The wedge's width, as an angle in radians.
        var width: Double
        /// The wedge's cross-axis depth, in range [0,1].
        var depth: Double
        /// The ring's hue.
        var hue: Double

        /// The wedge's start location, as an angle in radians.
        fileprivate(set) var start = 0.0
        /// The wedge's end location, as an angle in radians.
        fileprivate(set) var end = 0.0

        static var random: Wedge {
            return Wedge(
                width: .random(in: 0.5 ... 1),
                depth: .random(in: 0.2 ... 1),
                hue: .random(in: 0 ... 1))
        }
    }

    /// The collection of wedges, tracked by their id.
    var wedges: [Int: Wedge] {
        get {
            if _wedgesNeedUpdate {
                /// Recalculate locations, to pack within circle.
                let total = wedgeIDs.reduce(0.0) { $0 + _wedges[$1]!.width }
                let scale = (.pi * 2) / max(.pi * 2, total)
                var location = 0.0
                for id in wedgeIDs {
                    var wedge = _wedges[id]!
                    wedge.start = location * scale
                    location += wedge.width
                    wedge.end = location * scale
                    _wedges[id] = wedge
                }
                _wedgesNeedUpdate = false
            }
            return _wedges
        }
        set {
            objectWillChange.send()
            _wedges = newValue
            _wedgesNeedUpdate = true
        }
    }

    private var _wedges = [Int: Wedge]()
    private var _wedgesNeedUpdate = false

    /// The display order of the wedges.
    private(set) var wedgeIDs = [Int]() {
        willSet {
            objectWillChange.send()
        }
    }

    /// When true, periodically updates the data with random changes.
    var randomWalk = false { didSet { updateTimer() } }

    /// The next id to allocate.
    private var nextID = 0

    /// Trivial publisher for our changes.
    let objectWillChange = PassthroughSubject<Void, Never>()

    /// Adds a new wedge description to `array`.
    func addWedge(_ value: Wedge) {
        let id = nextID
        nextID += 1
        wedges[id] = value
        wedgeIDs.append(id)
    }

    /// Removes the wedge with `id`.
    func removeWedge(id: Int) {
        if let indexToRemove = wedgeIDs.firstIndex(where: { $0 == id }) {
            wedgeIDs.remove(at: indexToRemove)
            wedges.removeValue(forKey: id)
        }
    }

    /// Clear all data.
    func reset() {
        if !wedgeIDs.isEmpty {
            wedgeIDs = []
            wedges = [:]
        }
    }

    /// Randomly changes values of existing wedges.
    func randomize() {
        withAnimation(.spring(response: 2, dampingFraction: 0.5)) {
            wedges = wedges.mapValues {
                var wedge = $0
                wedge.width = .random(in: max(0.2, wedge.width - 0.2)
                    ... min(1, wedge.width + 0.2))
                wedge.depth = .random(in: max(0.2, wedge.depth - 0.2)
                    ... min(1, wedge.depth + 0.2))
                return wedge
            }
        }
    }

    private var timer: Timer?

    /// Ensures the random-walk timer has the correct state.
    func updateTimer() {
        if randomWalk, timer == nil {
            randomize()
            timer = Timer.scheduledTimer(
                withTimeInterval: 1, repeats: true
            ) { [weak self] _ in
                self?.randomize()
            }
        } else if !randomWalk, let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
}

/// Extend the wedge description to conform to the Animatable type to
/// simplify creation of custom shapes using the wedge.
extension Ring.Wedge: Animatable {
    // Use a composition of pairs to merge the interpolated values into
    // a single type. AnimatablePair acts as a single interpolatable
    // values, given two interpolatable input types.

    // We'll interpolate the derived start/end angles, and the depth
    // and color values. The width parameter is not used for rendering,
    // and so doesn't need to be interpolated.

    typealias AnimatableData = AnimatablePair<
        AnimatablePair<Double, Double>, AnimatablePair<Double, Double>>

    var animatableData: AnimatableData {
        get {
            .init(.init(start, end), .init(depth, hue))
        }
        set {
            start = newValue.first.first
            end = newValue.first.second
            depth = newValue.second.first
            hue = newValue.second.second
        }
    }
}
