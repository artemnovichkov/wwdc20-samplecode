/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Wrapper class for lazily computed values for use as properties elsewhere.
*/

// Using a provided closure the value is computed upon request.
// Managing classes can set the dirty state of the ComputedValue to
// force a consecutive compute of the value.
class ComputedValue<T> {
    
    private var compute: () -> T
    private var dirty = true
    private var storage: T!
    
    init(_ compute: @escaping () -> T) {
        self.compute = compute
    }
    
    // a flag specifying if the value has to be re-computed.
    // note: there is no way to set the flag to false from the outside
    var isDirty: Bool {
        get {
            return dirty
        }
        set {
            dirty = true
        }
    }
    
    private func computeIfRequired() {
        if !dirty {
            return
        }
        storage = compute()
        dirty = false
    }

    // accessor property to retrieved the
    // computed value.
    var value: T {
        computeIfRequired()
        return storage
    }
}
