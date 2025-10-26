import SwiftUI
import FirebaseMessaging
import FirebaseFirestore

struct ContentView: View {
    @State private var notifyToken: String = ""
    @State private var db = Firestore.firestore()
    @State private var showSettingsView = false
    	
    var body: some View {
        ZStack {
            BackgroundView()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showSettingsView = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
                
                Button(action: {
                    syncToken { }
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
            syncTokenOnAppear()
        }
        .fullScreenCover(isPresented: $showSettingsView) {
            SettingsView()
        }
    }
    
    func syncToken(completion: @escaping () -> Void) {
        Messaging.messaging().token { token, error in
            DispatchQueue.main.async {
                if let token = token {
                    self.notifyToken = token
                    self.registerToken(token)
                } else if let error = error {
                    self.notifyToken = "Error: \(error.localizedDescription)"
                    print("Error getting FCM token: \(error)")
                } else {
                    self.notifyToken = "Error getting token"
                }
                completion()
            }
        }
    }

    func syncTokenOnAppear() {
        syncToken { }
    }
    
    func sendNotification() {
        let senderId = UIDevice.current.identifierForVendor!.uuidString
        let url = URL(string: "https://yrvpgbhl2iuodk7t5o6yujkwsi0kphqp.lambda-url.us-east-1.on.aws/sendNotification")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["senderId": senderId, "title": "boop", "body": "boop boop boop!"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending: \(error)")
            } else {
                print("Notification sent")
            }
        }.resume()
    }

    func registerToken(_ token: String) {
        let userId = UIDevice.current.identifierForVendor!.uuidString
        let userRef = db.collection("users").document(userId)

        userRef.setData([
            "token": token,
            "pairedWith": "",
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ], merge: true)
    }

    func pairWith(partnerId: String) {
        let userId = UIDevice.current.identifierForVendor!.uuidString
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
