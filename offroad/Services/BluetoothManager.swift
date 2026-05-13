//
//  BluetoothManager.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import Foundation
import CoreBluetooth
import Combine
import SwiftUI

class BluetoothManager: NSObject, ObservableObject {
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var isScanning = false
    @Published var isAdvertising = false
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var permissionDenied = false
    @Published var isConnected = false
    @Published var activePeerName: String?
    @Published var activePeerId: UUID?
    @Published var lastErrorMessage: String?
    @Published var incomingRequest: IncomingConnectionRequest?
    @Published var shouldNavigateToChat: DiscoveredDevice?

    /// Persistent encrypted store. Set by the host once `BluetoothManager` is created.
    weak var chatStore: ChatStore?

    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var scanTimer: Timer?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var activePeripheral: CBPeripheral?
    private var activeWritableCharacteristic: CBCharacteristic?
    private var transferCharacteristic: CBMutableCharacteristic?
    private var recentPayloadHashes: [Int: Date] = [:]

    private let serviceUUID = CBUUID(string: "A0E6F0B3-7D58-4F43-85B2-D441E61A4F11")
    private let characteristicUUID = CBUUID(string: "CA6D76C5-CE1A-4B1A-90A3-80EA499D500E")

    private let controlPrefix = "__CTRL:"
    private let connectRequestTag = "CONNECT_REQ"
    private let connectAcceptTag = "CONNECT_ACK"

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        discoveredPeripherals.removeAll()
        isScanning = true
        lastErrorMessage = nil
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            self?.stopScanning()
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
    }

    func refreshScan() {
        stopScanning()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.startScanning()
        }
    }

    func connect(to device: DiscoveredDevice) {
        guard let peripheral = discoveredPeripherals[device.peripheralId] else {
            lastErrorMessage = "Device is no longer available."
            return
        }

        if activePeripheral?.identifier != peripheral.identifier, let activePeripheral {
            centralManager.cancelPeripheralConnection(activePeripheral)
        }

        activePeerName = device.name
        activePeerId = device.peripheralId
        activePeripheral = peripheral
        activeWritableCharacteristic = nil
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let activePeripheral {
            centralManager.cancelPeripheralConnection(activePeripheral)
        }
        markDisconnectedState()
    }

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let payload = Data(trimmed.utf8)
        appendOutgoingMessage(trimmed)

        var delivered = false
        if let activePeripheral, let activeWritableCharacteristic {
            let writeType: CBCharacteristicWriteType = activeWritableCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            activePeripheral.writeValue(payload, for: activeWritableCharacteristic, type: writeType)
            delivered = true
        }

        if let transferCharacteristic {
            let didNotify = peripheralManager.updateValue(payload, for: transferCharacteristic, onSubscribedCentrals: nil)
            delivered = delivered || didNotify
        }

        if !delivered {
            lastErrorMessage = "No active Bluetooth connection."
        }
    }

    private func appendOutgoingMessage(_ text: String) {
        persistMessage(text: text, isFromMe: true)
    }

    private func appendIncomingMessage(_ text: String) {
        persistMessage(text: text, isFromMe: false)
    }

    private func persistMessage(text: String, isFromMe: Bool) {
        let snapshotPeerId = activePeerId ?? activePeripheral?.identifier
        let snapshotPeerName = activePeerName ?? "Nearby device"
        let message = Message(text: text, isFromMe: isFromMe, timestamp: Date())

        DispatchQueue.main.async {
            guard let peerId = snapshotPeerId else { return }
            self.chatStore?.append(message, peerId: peerId, peerName: snapshotPeerName)
        }
    }

    private func handleIncomingPayload(_ data: Data) {
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }

        let hash = text.hashValue
        let now = Date()
        recentPayloadHashes = recentPayloadHashes.filter { now.timeIntervalSince($0.value) < 2 }
        if recentPayloadHashes[hash] != nil { return }
        recentPayloadHashes[hash] = now

        if text.hasPrefix(controlPrefix) {
            handleControlMessage(String(text.dropFirst(controlPrefix.count)))
            return
        }

        appendIncomingMessage(text)
    }

    private func handleControlMessage(_ message: String) {
        let parts = message.split(separator: "|", maxSplits: 1)
        guard let tag = parts.first else { return }
        let peerName = parts.count > 1 ? String(parts[1]) : "Nearby device"

        DispatchQueue.main.async {
            if tag == Substring(self.connectRequestTag) {
                let request = IncomingConnectionRequest(
                    peerName: peerName,
                    peerId: self.activePeripheral?.identifier
                )
                self.incomingRequest = request
            } else if tag == Substring(self.connectAcceptTag) {
                if let peerId = self.activePeerId ?? self.activePeripheral?.identifier {
                    let device = DiscoveredDevice(
                        peripheralId: peerId,
                        name: peerName,
                        rssi: -50,
                        distance: "< 1 m",
                        lastSeen: Date(),
                        isConnected: true
                    )
                    self.shouldNavigateToChat = device
                }
            }
        }
    }

    func sendConnectRequest() {
        let deviceName = UIDevice.current.name
        let payload = Data("\(controlPrefix)\(connectRequestTag)|\(deviceName)".utf8)

        if let activePeripheral, let activeWritableCharacteristic {
            let writeType: CBCharacteristicWriteType = activeWritableCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            activePeripheral.writeValue(payload, for: activeWritableCharacteristic, type: writeType)
        }
        if let transferCharacteristic {
            peripheralManager.updateValue(payload, for: transferCharacteristic, onSubscribedCentrals: nil)
        }
    }

    func acceptIncomingConnection() {
        let deviceName = UIDevice.current.name
        let payload = Data("\(controlPrefix)\(connectAcceptTag)|\(deviceName)".utf8)

        if let activePeripheral, let activeWritableCharacteristic {
            let writeType: CBCharacteristicWriteType = activeWritableCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            activePeripheral.writeValue(payload, for: activeWritableCharacteristic, type: writeType)
        }
        if let transferCharacteristic {
            peripheralManager.updateValue(payload, for: transferCharacteristic, onSubscribedCentrals: nil)
        }

        if let request = incomingRequest, let peerId = request.peerId ?? activePeerId ?? activePeripheral?.identifier {
            let device = DiscoveredDevice(
                peripheralId: peerId,
                name: request.peerName,
                rssi: -50,
                distance: "< 1 m",
                lastSeen: Date(),
                isConnected: true
            )
            shouldNavigateToChat = device
        }
        incomingRequest = nil
    }

    func declineIncomingConnection() {
        incomingRequest = nil
    }

    private func configurePeripheralService() {
        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.notify, .write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        transferCharacteristic = characteristic
        peripheralManager.add(service)
    }

    private func startAdvertisingIfPossible() {
        guard peripheralManager.state == .poweredOn, !peripheralManager.isAdvertising else { return }
        let displayName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "OFFROAD"
        let nameSuffix = UUID().uuidString.prefix(4)
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "\(displayName)-\(nameSuffix)"
        ])
    }

    private func markConnected(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.activePeerName = peripheral.name ?? self.activePeerName
            if let index = self.discoveredDevices.firstIndex(where: { $0.peripheralId == peripheral.identifier }) {
                self.discoveredDevices[index].isConnected = true
            }
        }
    }

    private func markDisconnectedState() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.activePeerName = nil
            self.activePeerId = nil
            self.activeWritableCharacteristic = nil
            self.activePeripheral = nil
            self.discoveredDevices = self.discoveredDevices.map { device in
                var updated = device
                updated.isConnected = false
                return updated
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.bluetoothState = central.state
            switch central.state {
            case .poweredOn:
                self.permissionDenied = false
                self.startScanning()
            case .unauthorized:
                self.permissionDenied = true
                self.lastErrorMessage = "Bluetooth permission denied."
            default:
                self.isScanning = false
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        guard let deviceName = name, !deviceName.isEmpty else { return }
        let rssiValue = RSSI.intValue
        guard rssiValue != 127 else { return }
        discoveredPeripherals[peripheral.identifier] = peripheral

        let distance = estimateDistance(rssi: rssiValue)

        DispatchQueue.main.async {
            if let index = self.discoveredDevices.firstIndex(where: { $0.peripheralId == peripheral.identifier }) {
                self.discoveredDevices[index].rssi = rssiValue
                self.discoveredDevices[index].distance = distance
                self.discoveredDevices[index].lastSeen = Date()
            } else {
                let device = DiscoveredDevice(
                    peripheralId: peripheral.identifier,
                    name: deviceName,
                    rssi: rssiValue,
                    distance: distance,
                    lastSeen: Date(),
                    isConnected: false
                )
                self.discoveredDevices.append(device)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        markConnected(peripheral)
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.lastErrorMessage = error?.localizedDescription ?? "Failed to connect."
        }
        markDisconnectedState()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error {
            DispatchQueue.main.async {
                self.lastErrorMessage = error.localizedDescription
            }
        }
        markDisconnectedState()
    }

    private func estimateDistance(rssi: Int) -> String {
        switch rssi {
        case -50...0:
            return "< 1 m"
        case -60...(-51):
            return "~2 m"
        case -70...(-61):
            return "~5 m"
        case -80...(-71):
            return "~10 m"
        case -90...(-81):
            return "~15 m"
        default:
            return "> 20 m"
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            DispatchQueue.main.async {
                self.lastErrorMessage = error.localizedDescription
            }
            return
        }

        peripheral.services?.forEach { service in
            guard service.uuid == serviceUUID else { return }
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            DispatchQueue.main.async {
                self.lastErrorMessage = error.localizedDescription
            }
            return
        }

        service.characteristics?.forEach { characteristic in
            guard characteristic.uuid == characteristicUUID else { return }
            activeWritableCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            DispatchQueue.main.async {
                self.lastErrorMessage = error.localizedDescription
            }
            return
        }

        guard characteristic.uuid == characteristicUUID, let data = characteristic.value else { return }
        handleIncomingPayload(data)
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        DispatchQueue.main.async {
            self.isAdvertising = peripheral.isAdvertising
            if peripheral.state == .poweredOn {
                self.configurePeripheralService()
            } else {
                self.isAdvertising = false
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error {
            DispatchQueue.main.async {
                self.lastErrorMessage = error.localizedDescription
            }
            return
        }
        startAdvertisingIfPossible()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        DispatchQueue.main.async {
            self.isAdvertising = error == nil
            if let error {
                self.lastErrorMessage = error.localizedDescription
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests where request.characteristic.uuid == characteristicUUID {
            if let value = request.value {
                handleIncomingPayload(value)
            }
            peripheral.respond(to: request, withResult: .success)
        }
    }
}

// MARK: - DiscoveredDevice Model

struct IncomingConnectionRequest: Identifiable {
    let id = UUID()
    let peerName: String
    let peerId: UUID?
}

struct DiscoveredDevice: Identifiable, Equatable {
    var id: UUID { peripheralId }
    let peripheralId: UUID
    var name: String
    var rssi: Int
    var distance: String
    var lastSeen: Date
    var isConnected: Bool

    var signalStrength: SignalStrength {
        switch rssi {
        case -50...0: return .excellent
        case -65...(-51): return .good
        case -80...(-66): return .fair
        default: return .weak
        }
    }

    enum SignalStrength {
        case excellent, good, fair, weak

        var label: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .weak: return "Weak"
            }
        }

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .green.opacity(0.7)
            case .fair: return .orange
            case .weak: return .red.opacity(0.7)
            }
        }

        var bars: Int {
            switch self {
            case .excellent: return 4
            case .good: return 3
            case .fair: return 2
            case .weak: return 1
            }
        }
    }
}
