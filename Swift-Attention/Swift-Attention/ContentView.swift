//
//  ContentView.swift
//  Swift-Attention
//
//  Created by ec2-user on 30/07/2025.
//

import SwiftUI
import FirebaseMessaging

struct ContentView: View {
    @State private var myToken: String = "Loading..."
    @State private var showToken: Bool = false
    
    var body: some View {
        ZStack {
            BackgroundView()
            Button(action: {
                showToken.toggle()
                if showToken {
                    getToken()
                }
            }) {
                Text("Press me")
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
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func getToken() {
        Messaging.messaging().token { token, error in
            DispatchQueue.main.async {
                if let token = token {
                    self.myToken = token
                } else {
                    self.myToken = "Error getting token"
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
