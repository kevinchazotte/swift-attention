import SwiftUI
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

enum AppState {
    case launch
    case authenticating
    case requestingNotifications
    case ready
    case error(String)
}

@main
struct Swift_AttentionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var appState: AppState = .launch
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch appState {
                case .launch, .authenticating:
                    ProgressView("Authenticating...")
                case .requestingNotifications:
                    ProgressView("Setting up Notifications...")
                case .ready:
                    ContentView()
                case .error(let message):
                    VStack {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(message)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            startAuthFlow()
                        }
                    }
                }
            }
            .onAppear {
                startAuthFlow()
            }
        }
    }
    
    func startAuthFlow() {
        appState = .authenticating
        
        if Auth.auth().currentUser != nil {
            requestNotificationPermissions()
        } else {
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("Error signing in anonymously: \(error.localizedDescription)")
                    appState = .error(error.localizedDescription)
                } else {
                    requestNotificationPermissions()
                }
            }
        }
    }
    
    func requestNotificationPermissions() {
        appState = .requestingNotifications
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notifications: \(error.localizedDescription)")
                    if granted {
                         UIApplication.shared.registerForRemoteNotifications()
                         appState = .ready
                    } else {
                       appState = .error("Notifications are required. Please enable them in settings.")
                    }
                } else if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    appState = .ready
                } else {
                    appState = .error("Notifications are required. Please enable them in settings.")
                }
            }
        }
    }
}
