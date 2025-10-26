import SwiftUI
import FirebaseFirestore
import FirebaseMessaging

struct SettingsView: View {
    @Binding var isPresented: Bool
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var notifyToken: String = ""
    @State private var showPairingView = false
    @State private var isLoadingToken = false
    @State private var isPaired = false
    @State private var pairedUserId: String? = nil
    @State private var showRemovePairAlert = false

    private var db = Firestore.firestore()

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pairing")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            if isPaired, let partnerId = pairedUserId {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Currently Paired")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }

                                    Text("Partner ID: \(partnerId.prefix(8))...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            } else {
                                HStack {
                                    Image(systemName: "person.2.slash")
                                        .foregroundColor(.orange)
                                    Text("Not Paired")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }

                            Button(action: {
                                isLoadingToken = true
                                syncToken {
                                    isLoadingToken = false
                                    showPairingView = true
                                }
                            }) {
                                HStack {
                                    if isLoadingToken {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                        Text(isPaired ? "Pair with New Device" : "Pair Device")
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .disabled(isLoadingToken)

                            if isPaired {
                                Button(action: {
                                    showRemovePairAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "person.2.slash.fill")
                                        Text("Remove Pair")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Device Info")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Device ID:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(UIDevice.current.identifierForVendor?.uuidString.prefix(8) ?? "Unknown")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }

                                if !notifyToken.isEmpty && !notifyToken.starts(with: "Error") {
                                    Divider()
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("FCM Token:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(notifyToken.prefix(20) + "...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: 500)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(40)
        }
        .onAppear {
            syncToken { }
            checkPairStatus()
        }
        .sheet(isPresented: $showPairingView) {
            PairingView(bluetoothManager: bluetoothManager, notifyToken: notifyToken, onPairingComplete: {
                checkPairStatus()
            })
        }
        .alert("Remove Pair", isPresented: $showRemovePairAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removePair()
            }
        } message: {
            Text("Are you sure you want to remove your current pairing? You'll need to pair again to send notifications.")
        }
    }

    func syncToken(completion: @escaping () -> Void) {
        FirebaseMessaging.Messaging.messaging().token { token, error in
            DispatchQueue.main.async {
                if let token = token {
                    self.notifyToken = token
                } else if let error = error {
                    self.notifyToken = "Error: \(error.localizedDescription)"
                } else {
                    self.notifyToken = "Error getting token"
                }
                completion()
            }
        }
    }

    func checkPairStatus() {
        let userId = UIDevice.current.identifierForVendor!.uuidString
        db.collection("users").document(userId).getDocument { document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    let pairedWith = document.data()?["pairedWith"] as? String ?? ""
                    if !pairedWith.isEmpty {
                        self.isPaired = true
                        self.pairedUserId = pairedWith
                    } else {
                        self.isPaired = false
                        self.pairedUserId = nil
                    }
                }
            }
        }
    }

    func removePair() {
        let userId = UIDevice.current.identifierForVendor!.uuidString
        let batch = db.batch()

        // Remove pairedWith from current user
        let userRef = db.collection("users").document(userId)
        batch.setData([
            "pairedWith": "",
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ], forDocument: userRef, merge: true)

        // Remove pairedWith from partner (if exists)
        if let partnerId = pairedUserId {
            let partnerRef = db.collection("users").document(partnerId)
            batch.setData([
                "pairedWith": "",
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ], forDocument: partnerRef, merge: true)
        }

        // Find and delete the pair document
        db.collection("pairs")
            .whereField("first", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents, !documents.isEmpty {
                    for doc in documents {
                        batch.deleteDocument(doc.reference)
                    }
                }

                // Also check if user is "second" in any pair
                self.db.collection("pairs")
                    .whereField("second", isEqualTo: userId)
                    .getDocuments { snapshot2, error2 in
                        if let documents2 = snapshot2?.documents, !documents2.isEmpty {
                            for doc in documents2 {
                                batch.deleteDocument(doc.reference)
                            }
                        }

                        // Commit all changes
                        batch.commit { error in
                            DispatchQueue.main.async {
                                if error == nil {
                                    self.isPaired = false
                                    self.pairedUserId = nil
                                }
                            }
                        }
                    }
            }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}
