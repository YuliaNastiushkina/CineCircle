import FirebaseAppCheck
import FirebaseCore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if DEBUG
            AppCheck.setAppCheckProviderFactory(
                AppCheckDebugProviderFactory()
            )
        #endif

        FirebaseApp.configure()
        return true
    }
}
