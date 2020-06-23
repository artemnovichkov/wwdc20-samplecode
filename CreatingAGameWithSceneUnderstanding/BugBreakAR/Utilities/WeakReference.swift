/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Weak Reference
*/

//
// WeakReference
// useful generic wrapper for any type to be stored as a weak reference
// (mostly used in array and dictionary storage)
public struct WeakReference<T> where T: AnyObject {
    public private(set) weak var value: T?
    public init(_ value: T?) {
        self.value = value
    }
}
