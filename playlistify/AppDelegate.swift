import UIKit
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

