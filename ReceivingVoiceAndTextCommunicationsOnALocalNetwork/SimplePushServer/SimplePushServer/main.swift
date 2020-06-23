/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main entry point of the server.
*/

import Combine
import SimplePushKit

let router = Router()
let controlChannel = Channel(port: Port.control, type: .control, router: router)
let notificationChannel = Channel(port: Port.notification, type: .notification, router: router)

controlChannel.start()
notificationChannel.start()

print("SimplePushServer started. See Console for logs.")

while RunLoop.current.run(mode: .default, before: Date.distantFuture) {
    continue
}
