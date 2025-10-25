import SwiftUI
import CoreBluetooth

struct PairingView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    let notifyToken: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Device Pairing")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Find and connect with your partner")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Status
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(bluetoothManager.isConnected ? Color.green : (bluetoothManager.isScanning ? Color.orange : Color.gray))
                            .frame(width: 12, height: 12)
                        
                        Text(bluetoothManager.connectionStatus)
                            .font(.headline)
                    }
                    
                    if bluetoothManager.isScanning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action buttons
                VStack(spacing: 16) {
                    if !bluetoothManager.isScanning {
                        Button(action: {
                            guard !notifyToken.isEmpty else {
                                return
                            }
                            bluetoothManager.startPairing(with: notifyToken)
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Start Pairing")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(notifyToken.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(notifyToken.isEmpty)

                        if notifyToken.isEmpty {
                            Text("Waiting for notification token...")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Button(action: {
                            bluetoothManager.stopPairing()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle")
                                Text("Stop Pairing")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Discovered devices
                if !bluetoothManager.discoveredDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Devices")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                                    DeviceRow(device: device) {
                                        bluetoothManager.connectToDevice(device)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to pair:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("1.")
                            Text("Both devices tap 'Start Pairing' to begin advertising and scanning")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("2.")
                            Text("Wait for nearby devices to appear in the list")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("3.")
                            Text("Tap on your partner's device to connect")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("4.")
                            Text("Notification tokens will be exchanged automatically and pairing will complete")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    if bluetoothManager.isConnected {
                        Divider()
                            .padding(.vertical, 4)

                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Pairing successful! You can close this window.")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    bluetoothManager.stopPairing()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct DeviceRow: View {
    let device: CBPeripheral
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? "Unknown Device")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(device.identifier.uuidString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PairingView(bluetoothManager: BluetoothManager(), notifyToken: "test-token")
}
