/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate for the application.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
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
        // Forward the token to your provider, using a custom method.
        let tokenComponents = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let deviceTokenString = tokenComponents.joined()
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

        URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
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
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let url = URL(string: "www.example.com/todays-menu") else {
            completionHandler(.failed)
            return
        }

        let session = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                print("Error fetching menu from server! \(error.localizedDescription)")
                completionHandler(.failed)
                return
            }
            guard response != nil else {
                print("No response found fetching menu from the server")
                completionHandler(.noData)
                return
            }
            guard let data = data else {
                print("No data found fetching menu from the server")
                completionHandler(.noData)
                return
            }

            self.updateMenu(withData: data)
            completionHandler(.newData)
        }

        session.resume()
    }

    func updateMenu(withData data: Data) {
        // Use the data fetched to update the content of the application in the background.
    }
}

