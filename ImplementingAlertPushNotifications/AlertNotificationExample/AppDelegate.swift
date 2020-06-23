/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The AppDelegate for the application.
*/

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running,
        // this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // Handle remote notification registration.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenComponents = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let deviceTokenString = tokenComponents.joined()

        // Forward the token to your provider, using a custom method.
        self.forwardTokenToServer(tokenString: deviceTokenString)
        guard let viewController = UIApplication.shared.windows.first!.rootViewController as? ViewController else {
            return
        }

        viewController.showDeviceToken(deviceTokenString)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
        guard let viewController = UIApplication.shared.windows.first!.rootViewController as? ViewController else {
            return
        }

        viewController.showDeviceToken(error.localizedDescription)
    }

    func forwardTokenToServer(tokenString: String) {
        print("Token: \(tokenString)")
        let queryItems = [URLQueryItem(name: "deviceToken", value: tokenString)]
        var urlComps = URLComponents(string: "www.example.com/register")!
        urlComps.queryItems = queryItems
        guard let url = urlComps.url else {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                // Handle the error
                return
            }
            guard response != nil else {
                // Handle empty response
                return
            }
            guard data != nil else {
                // Handle empty data
                return
            }

            // Handle data
        }

        task.resume()
    }

    /* Example Payload
     {
         "aps" : {
            "alert" : {
                 "title" : "Check out our new special!",
                 "body" : "Avocado Bacon Burger on sale"
             },
             "sound" : "default",
             "badge" : 1,
        },
         "special" : "avocado_bacon_burger",
         "price" : "9.99"
     }
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("User info \(userInfo)")
        guard let specialName = userInfo["special"] as? String,
              let specialPriceString = userInfo["price"] as? String,
              let specialPrice = Float(specialPriceString) else {
            // Always call the completion handler when done.
            completionHandler()
            return
        }

        // Opening this alert will start purchasing the item in a real app.
        let item = Item(name: specialName, price: specialPrice)
        addItemToCart(item)
        showCartViewController()

        // Always call the completion handler when done.
        completionHandler()
     }

    func addItemToCart(_ item: Item) {
        // Add the item to the cart in response to a notification tap
        // so the user can purchase that item.
    }

    func showCartViewController() {
        // Show the cart so the application is in the proper state
        // after opening a notification.
    }

}
