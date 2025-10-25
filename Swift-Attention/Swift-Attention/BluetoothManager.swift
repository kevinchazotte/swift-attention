import Foundation
import CoreBluetooth
import FirebaseFirestore

class BluetoothManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var isConnected = false
    @Published var connectionStatus = "Not connected"

    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var characteristic: CBMutableCharacteristic?
    private var service: CBMutableService?

    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    private let characteristicUUID = CBUUID(string: "87654321-4321-4321-4321-CBA987654321")

    private var currentToken: String = ""
    private var receivedToken: String?
    private var hasExchangedTokens = false
    private var db = Firestore.firestore()

    private var centralReady = false
    private var peripheralReady = false
    private var isAdvertising = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startPairing(with token: String) {
        currentToken = token
        hasExchangedTokens = false
        receivedToken = nil
        discoveredDevices.removeAll()

        if peripheralReady {
            setupPeripheral()
        }

        if centralReady {
            startScanning()
        }

        connectionStatus = "Initializing..."
    }

    func stopPairing() {
        centralManager.stopScan()
        if isAdvertising {
            peripheralManager.stopAdvertising()
            isAdvertising = false
        }

        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        isScanning = false
        hasExchangedTokens = false
        receivedToken = nil
        connectedPeripheral = nil
        writeCharacteristic = nil
        discoveredDevices.removeAll()
        connectionStatus = "Stopped"
    }
    
    private func setupPeripheral() {
        guard peripheralManager.state == .poweredOn else { return }

        if let existingService = service {
            peripheralManager.remove(existingService)
        }

        characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .write, .notify, .writeWithoutResponse],
            value: nil,
            permissions: [.readable, .writeable]
        )

        service = CBMutableService(type: serviceUUID, primary: true)
        service?.characteristics = [characteristic!]
        peripheralManager.add(service!)
    }
    
    private func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionStatus = "Bluetooth not available"
            return
        }
        
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        isScanning = true
        connectionStatus = "Scanning for devices..."
    }
    
    func connectToDevice(_ peripheral: CBPeripheral) {
        centralManager.stopScan()
        isScanning = false

        connectedPeripheral = peripheral
        connectionStatus = "Connecting..."
        centralManager.connect(peripheral, options: nil)
    }

    private func sendTokenToPeer() {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              !currentToken.isEmpty else {
            return
        }

        let tokenData = currentToken.data(using: .utf8)!

        if characteristic.properties.contains(.write) {
            peripheral.writeValue(tokenData, for: characteristic, type: .withResponse)
        } else if characteristic.properties.contains(.writeWithoutResponse) {
            peripheral.writeValue(tokenData, for: characteristic, type: .withoutResponse)
        }

        connectionStatus = "Exchanging tokens..."
    }
    
    private func processReceivedToken(_ tokenData: Data) {
        guard let receivedTokenString = String(data: tokenData, encoding: .utf8),
              !receivedTokenString.isEmpty else {
            return
        }

        self.receivedToken = receivedTokenString
        if writeCharacteristic != nil {
            sendTokenToPeer()
        }

        checkAndCompletePairing()
    }

    private func checkAndCompletePairing() {
        guard let receivedToken = receivedToken,
              !currentToken.isEmpty,
              !hasExchangedTokens else {
            return
        }

        hasExchangedTokens = true
        connectionStatus = "Processing pairing..."

        findUserIdByToken(receivedToken) { [weak self] partnerUserId in
            guard let self = self, let partnerUserId = partnerUserId else {
                DispatchQueue.main.async {
                    self?.connectionStatus = "Failed to find partner user"
                    self?.hasExchangedTokens = false
                }
                return
            }
            self.pairWith(partnerId: partnerUserId)
        }
    }
    
    private func findUserIdByToken(_ token: String, completion: @escaping (String?) -> Void) {
        db.collection("users")
            .whereField("token", isEqualTo: token)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error finding user by token: \(error)")
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No user found with token: \(token)")
                    completion(nil)
                    return
                }
                
                let userId = documents.first?.documentID
                completion(userId)
            }
    }
    
    private func pairWith(partnerId: String) {
        let userId = UIDevice.current.identifierForVendor!.uuidString
        let batch = db.batch()
        let pairId = UUID().uuidString
        let pairRef = db.collection("pairs").document(pairId)
        
        batch.setData([
            "user1": userId,
            "user2": partnerId
        ], forDocument: pairRef)

        let userRef = db.collection("users").document(userId)
        let partnerRef = db.collection("users").document(partnerId)
        batch.updateData(["pairedWith": partnerId], forDocument: userRef)
        batch.updateData(["pairedWith": userId], forDocument: partnerRef)

        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.connectionStatus = "Error pairing: \(error.localizedDescription)"
                } else {
                    self?.connectionStatus = "Successfully paired!"
                    self?.isConnected = true
                }
            }
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralReady = true
            connectionStatus = "Bluetooth ready"
            if !currentToken.isEmpty && !isScanning {
                startScanning()
            }
        case .poweredOff:
            centralReady = false
            connectionStatus = "Bluetooth is off"
        case .unauthorized:
            centralReady = false
            connectionStatus = "Bluetooth permission denied"
        case .unsupported:
            centralReady = false
            connectionStatus = "Bluetooth not supported"
        default:
            centralReady = false
            connectionStatus = "Bluetooth unavailable"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            DispatchQueue.main.async {
                self.discoveredDevices.append(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStatus = "Connected, discovering services..."
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
        connectedPeripheral = nil
        writeCharacteristic = nil

        if centralReady && !currentToken.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startScanning()
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if !isConnected {
            connectionStatus = "Disconnected"
            connectedPeripheral = nil
            writeCharacteristic = nil
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            connectionStatus = "Error discovering services: \(error.localizedDescription)"
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            connectionStatus = "Error discovering characteristics: \(error.localizedDescription)"
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                writeCharacteristic = characteristic
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }

                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }

                sendTokenToPeer()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }

        guard characteristic.uuid == characteristicUUID,
              let data = characteristic.value,
              !data.isEmpty else {
            return
        }

        processReceivedToken(data)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            connectionStatus = "Error sending token: \(error.localizedDescription)"
        }
    }
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            peripheralReady = true
            if !currentToken.isEmpty {
                setupPeripheral()
            }
        case .poweredOff:
            peripheralReady = false
            isAdvertising = false
        case .unauthorized:
            peripheralReady = false
            isAdvertising = false
        default:
            peripheralReady = false
            isAdvertising = false
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            connectionStatus = "Error adding service: \(error.localizedDescription)"
            return
        }

        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "Swift-Attention"
        ]
        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
        connectionStatus = "Ready for pairing..."
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == characteristicUUID {
            // Send our token when partner reads
            if let tokenData = currentToken.data(using: .utf8) {
                request.value = tokenData
                peripheralManager.respond(to: request, withResult: .success)
            } else {
                peripheralManager.respond(to: request, withResult: .unlikelyError)
            }
        } else {
            peripheralManager.respond(to: request, withResult: .requestNotSupported)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == characteristicUUID {
                if let data = request.value {
                    // Received partner's token
                    processReceivedToken(data)
                }
                peripheralManager.respond(to: request, withResult: .success)
            } else {
                peripheralManager.respond(to: request, withResult: .requestNotSupported)
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        // Partner subscribed to notifications - send our token
        if characteristic.uuid == characteristicUUID,
           let tokenData = currentToken.data(using: .utf8),
           let char = self.characteristic {
            peripheralManager.updateValue(tokenData, for: char, onSubscribedCentrals: [central])
        }
    }
}
