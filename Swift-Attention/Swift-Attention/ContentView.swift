//
//  ContentView.swift
//  Swift-Attention
//
//  Created by ec2-user on 30/07/2025.
//

import SwiftUI
import FirebaseMessaging

struct ContentView: View {
    @State private var notifyToken: String = "f2HHSR8BXkwjg6HnCKi2FO:APA91bEIXQbBnFejwRYXMtxqWbmCcoXnZlbIW2ZVXQo16_7yNNpS9XRRzZ5Zs1Lb39k1D3GqqAKZTds39DYuu7Nz-ykxZo4eQPFHpAihzVnwucluXLOfCMc"
    @State private var myToken: String = "Loading..."
    @State private var showToken: Bool = false
    	
    var body: some View {
        ZStack {
            BackgroundView()
            Button(action: {
                /*showToken.toggle()
                if showToken {
                    getToken()
                }*/
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
            
            if showToken {
                Text(myToken)
                    .font(.caption)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
        }
        .padding()
    }
    
    func getToken() {
        Messaging.messaging().token { token, error in
            DispatchQueue.main.async {
                if let token = token {
                    self.myToken = token
                } else if let error = error {
                    self.myToken = "Error: \(error.localizedDescription)"
                } else {
                    self.myToken = "Error getting token"
                }
            }
        }
    }
    
    func sendNotification() {
        let url = URL(string: "https://yrvpgbhl2iuodk7t5o6yujkwsi0kphqp.lambda-url.us-east-1.on.aws/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["token": notifyToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request).resume()
    }
}

#Preview {
    ContentView()
}
