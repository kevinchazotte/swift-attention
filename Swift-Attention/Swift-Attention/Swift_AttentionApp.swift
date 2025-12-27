import SwiftUI
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

@main
struct Swift_AttentionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseApp.configure()
        signInAnonymously()
    }

    func signInAnonymously() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("Error signing in anonymously: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
