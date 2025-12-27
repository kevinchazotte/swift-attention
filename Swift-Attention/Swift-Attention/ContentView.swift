import SwiftUI
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {
    @State private var notifyToken: String = ""
    @State private var db = Firestore.firestore()
    @State private var showSettingsView = false
    @State private var lastRegisteredToken: String?

    var body: some View {
        ZStack {
            BackgroundView()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showSettingsView = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title)
                            .foregroundColor(.gray)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
                
                Button(action: {
                    sendNotification()
                }) {
                    Text("boop")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 3, y: 3)
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.6)).offset(x: 5, y: 5))
                
                Spacer()
            }
        }
        .padding()
        .onAppear {
            refreshAndRegisterToken()
        }
        .overlay {
            if showSettingsView {
                SettingsView(isPresented: $showSettingsView)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSettingsView)
    }

    func refreshAndRegisterToken() {
        Messaging.messaging().token { token, error in
            if let token = token {
                self.notifyToken = token
                self.registerToken(token)
            } else if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
            }
        }
    }
    
    func sendNotification() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        user.getIDToken { idToken, error in
            if let error = error {
                print("Error getting ID token: \(error)")
                return
            }
            
            guard let idToken = idToken else {
                print("ID token is nil")
                return
            }
            
            let url = URL(string: "https://yrvpgbhl2iuodk7t5o6yujkwsi0kphqp.lambda-url.us-east-1.on.aws/sendNotification")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

            let payload = ["title": "boop", "body": "boop boop boop!"]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending notification: \(error)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                    } else {
                        let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
                        print("Notification failed with status \(httpResponse.statusCode): \(body)")
                    }
                }
            }.resume()
        }
    }

    func registerToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if token == lastRegisteredToken {
            return
        }

        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error checking user document: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                userRef.updateData([
                    "token": token,
                    "updatedAt": ISO8601DateFormatter().string(from: Date())
                ]) { error in
                   if let error = error {
                       print("Error updating token: \(error.localizedDescription)")
                   } else {
                       self.lastRegisteredToken = token
                   }
                }
            } else {
                userRef.setData([
                    "token": token,
                    "createdAt": ISO8601DateFormatter().string(from: Date()),
                    "updatedAt": ISO8601DateFormatter().string(from: Date())
                ]) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        self.lastRegisteredToken = token
                    }
                }
            }
        }
    }

    func pairWith(partnerId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let batch = db.batch()
        let pairId = UUID().uuidString
        let pairRef = db.collection("pairs").document(pairId)

        batch.setData([
            "first": userId,
            "second": partnerId
        ], forDocument: pairRef)

        let userRef = db.collection("users").document(userId)
        let partnerRef = db.collection("users").document(partnerId)
        
        batch.setData([
            "pairedWith": partnerId,
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ], forDocument: userRef, merge: true)

        batch.setData([
            "pairedWith": userId,
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ], forDocument: partnerRef, merge: true)

        batch.commit { error in
            if let error = error {
                print("Error pairing users: \(error)")
            } else {
                print("Users paired successfully")
            }
        }
    }

}

#Preview {
    ContentView()
}
