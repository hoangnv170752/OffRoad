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
import UIKit

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
    private var pendingDeviceToConnect: DiscoveredDevice?
    private var activeWritableCharacteristic: CBCharacteristic?
    private var transferCharacteristic: CBMutableCharacteristic?
    private var recentPayloadHashes: [Int: Date] = [:]
    private var didSendConnectRequestForSession = false
    private var didReceiveConnectRequestForSession = false
    private var isChatSessionEstablished = false
    private var incomingImageBuffers: [UUID: IncomingImageBuffer] = [:]

    private let serviceUUID = CBUUID(string: "A0E6F0B3-7D58-4F43-85B2-D441E61A4F11")
    private let characteristicUUID = CBUUID(string: "CA6D76C5-CE1A-4B1A-90A3-80EA499D500E")

    private let controlPrefix = "__CTRL:"
    private let connectRequestTag = "CONNECT_REQ"
    private let connectAcceptTag = "CONNECT_ACK"
    private let imageBeginTag = "IMAGE_BEGIN"
    private let imageChunkTag = "IMAGE_CHUNK"
    private let imageEndTag = "IMAGE_END"
    private let maxImagePayloadBytes = 45_000
    private let imageChunkSize = 120

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

        if activePeerId != device.peripheralId {
            resetHandshakeState()
        }

        if activePeripheral?.identifier != peripheral.identifier, let activePeripheral {
            pendingDeviceToConnect = device
            centralManager.cancelPeripheralConnection(activePeripheral)
            return
        }

        pendingDeviceToConnect = nil
        activePeerName = device.name
        activePeerId = device.peripheralId
        activePeripheral = peripheral
        activeWritableCharacteristic = nil
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        pendingDeviceToConnect = nil
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

        let delivered = transmitPayload(payload)

        if !delivered {
            lastErrorMessage = "No active Bluetooth connection."
        }
    }

    func sendImage(_ rawImageData: Data) {
        guard isConnected else {
            lastErrorMessage = "No active Bluetooth connection."
            return
        }

        guard let payloadImageData = prepareImagePayload(from: rawImageData) else {
            lastErrorMessage = "Image is too large to send over Bluetooth."
            return
        }

        let messageId = UUID()
        let fileName = "img-\(messageId.uuidString).jpg"
        do {
            _ = try ChatAttachmentStore.shared.save(data: payloadImageData, suggestedFileName: fileName)
        } catch {
            lastErrorMessage = "Failed to save image locally."
            return
        }

        let base64 = payloadImageData.base64EncodedString()
        let chunks = base64.chunked(by: imageChunkSize)
        guard !chunks.isEmpty else {
            lastErrorMessage = "Failed to encode image payload."
            return
        }

        let begin = "\(controlPrefix)\(imageBeginTag)|\(messageId.uuidString)|jpg|\(chunks.count)"
        var controlMessages: [String] = [begin]
        controlMessages.append(
            contentsOf: chunks.enumerated().map { index, chunk in
                "\(controlPrefix)\(imageChunkTag)|\(messageId.uuidString)|\(index)|\(chunk)"
            }
        )
        controlMessages.append("\(controlPrefix)\(imageEndTag)|\(messageId.uuidString)")

        let delivered = transmitControlMessages(controlMessages)
        if delivered {
            appendOutgoingImageMessage(fileName: fileName, messageId: messageId)
        } else {
            lastErrorMessage = "Failed to send image over Bluetooth."
        }
    }

    private func appendOutgoingMessage(_ text: String) {
        persistMessage(text: text, isFromMe: true)
    }

    private func appendIncomingMessage(_ text: String) {
        persistMessage(text: text, isFromMe: false)
    }

    private func appendOutgoingImageMessage(fileName: String, messageId: UUID) {
        persistMessage(
            id: messageId,
            text: "🖼 Photo",
            isFromMe: true,
            isImage: true,
            attachmentFileName: fileName
        )
    }

    private func appendIncomingImageMessage(fileName: String, messageId: UUID) {
        persistMessage(
            id: messageId,
            text: "🖼 Photo",
            isFromMe: false,
            isImage: true,
            attachmentFileName: fileName
        )
    }

    private func persistMessage(
        id: UUID = UUID(),
        text: String,
        isFromMe: Bool,
        isImage: Bool = false,
        attachmentFileName: String? = nil
    ) {
        let snapshotPeerId = activePeerId ?? activePeripheral?.identifier
        let snapshotPeerName = activePeerName ?? "Nearby device"
        let message = Message(
            id: id,
            text: text,
            isFromMe: isFromMe,
            timestamp: Date(),
            isImage: isImage,
            attachmentFileName: attachmentFileName
        )

        DispatchQueue.main.async {
            guard let peerId = snapshotPeerId else { return }
            self.chatStore?.append(message, peerId: peerId, peerName: snapshotPeerName)
        }
    }

    private func transmitPayload(_ payload: Data) -> Bool {
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
        return delivered
    }

    private func transmitControlMessages(_ messages: [String]) -> Bool {
        guard !messages.isEmpty else { return false }
        var hadDelivery = false
        for message in messages {
            let sent = transmitControlMessage(message)
            hadDelivery = hadDelivery || sent
            if !sent {
                return false
            }
        }
        return hadDelivery
    }

    private func transmitControlMessage(_ message: String) -> Bool {
        guard let payload = message.data(using: .utf8) else { return false }
        return transmitPayload(payload)
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
        if message.hasPrefix("\(imageBeginTag)|") {
            handleIncomingImageBeginControl(message)
            return
        }
        if message.hasPrefix("\(imageChunkTag)|") {
            handleIncomingImageChunkControl(message)
            return
        }
        if message.hasPrefix("\(imageEndTag)|") {
            handleIncomingImageEndControl(message)
            return
        }

        let parts = message.split(separator: "|", maxSplits: 1)
        guard let tag = parts.first else { return }
        let peerName = parts.count > 1 ? String(parts[1]) : "Nearby device"

        DispatchQueue.main.async {
            if tag == Substring(self.connectRequestTag) {
                self.didReceiveConnectRequestForSession = true
                // Remote side initiated first, prevent local request loop.
                self.didSendConnectRequestForSession = false
                guard !self.isChatSessionEstablished else { return }
                if self.incomingRequest != nil { return }
                let request = IncomingConnectionRequest(
                    peerName: peerName,
                    peerId: self.activePeripheral?.identifier
                )
                self.incomingRequest = request
            } else if tag == Substring(self.connectAcceptTag) {
                self.isChatSessionEstablished = true
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

    private func handleIncomingImageBeginControl(_ message: String) {
        let parts = message.split(separator: "|", maxSplits: 3, omittingEmptySubsequences: false)
        guard parts.count == 4 else { return }
        guard let messageId = UUID(uuidString: String(parts[1])) else { return }
        let fileExtension = String(parts[2])
        let expectedChunkCount = Int(parts[3]) ?? 0
        guard expectedChunkCount > 0 else { return }

        incomingImageBuffers[messageId] = IncomingImageBuffer(
            fileExtension: fileExtension,
            expectedChunkCount: expectedChunkCount,
            chunks: [:]
        )
    }

    private func handleIncomingImageChunkControl(_ message: String) {
        let parts = message.split(separator: "|", maxSplits: 3, omittingEmptySubsequences: false)
        guard parts.count == 4 else { return }
        guard let messageId = UUID(uuidString: String(parts[1])) else { return }
        guard let chunkIndex = Int(parts[2]) else { return }

        guard var buffer = incomingImageBuffers[messageId] else { return }
        buffer.chunks[chunkIndex] = String(parts[3])
        incomingImageBuffers[messageId] = buffer
    }

    private func handleIncomingImageEndControl(_ message: String) {
        let parts = message.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return }
        guard let messageId = UUID(uuidString: String(parts[1])) else { return }
        guard let buffer = incomingImageBuffers[messageId] else { return }

        let orderedChunks = (0..<buffer.expectedChunkCount).compactMap { buffer.chunks[$0] }
        guard orderedChunks.count == buffer.expectedChunkCount else {
            incomingImageBuffers.removeValue(forKey: messageId)
            DispatchQueue.main.async {
                self.lastErrorMessage = "Image transfer incomplete."
            }
            return
        }

        let base64Payload = orderedChunks.joined()
        guard let imageData = Data(base64Encoded: base64Payload), !imageData.isEmpty else {
            incomingImageBuffers.removeValue(forKey: messageId)
            return
        }

        let fileName = "img-\(messageId.uuidString).\(buffer.fileExtension)"
        do {
            _ = try ChatAttachmentStore.shared.save(data: imageData, suggestedFileName: fileName)
            appendIncomingImageMessage(fileName: fileName, messageId: messageId)
        } catch {
            DispatchQueue.main.async {
                self.lastErrorMessage = "Failed to save received image."
            }
        }
        incomingImageBuffers.removeValue(forKey: messageId)
    }

    func sendConnectRequest() {
        guard isConnected else { return }
        guard !didSendConnectRequestForSession else { return }
        // If the remote peer initiated pairing first, don't ask back.
        guard !didReceiveConnectRequestForSession else { return }
        guard !isChatSessionEstablished else { return }

        let deviceName = UIDevice.current.name
        let payload = Data("\(controlPrefix)\(connectRequestTag)|\(deviceName)".utf8)

        if let activePeripheral, let activeWritableCharacteristic {
            let writeType: CBCharacteristicWriteType = activeWritableCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            activePeripheral.writeValue(payload, for: activeWritableCharacteristic, type: writeType)
            didSendConnectRequestForSession = true
        }
        if let transferCharacteristic {
            let didNotify = peripheralManager.updateValue(payload, for: transferCharacteristic, onSubscribedCentrals: nil)
            if didNotify {
                didSendConnectRequestForSession = true
            }
        }
    }

    func acceptIncomingConnection() {
        guard !isChatSessionEstablished else {
            incomingRequest = nil
            return
        }

        let deviceName = UIDevice.current.name
        let payload = Data("\(controlPrefix)\(connectAcceptTag)|\(deviceName)".utf8)

        if let activePeripheral, let activeWritableCharacteristic {
            let writeType: CBCharacteristicWriteType = activeWritableCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            activePeripheral.writeValue(payload, for: activeWritableCharacteristic, type: writeType)
        }
        if let transferCharacteristic {
            peripheralManager.updateValue(payload, for: transferCharacteristic, onSubscribedCentrals: nil)
        }

        isChatSessionEstablished = true
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
            self.resetHandshakeState()
            self.discoveredDevices = self.discoveredDevices.map { device in
                var updated = device
                updated.isConnected = false
                return updated
            }
        }
    }

    private func prepareImagePayload(from rawData: Data) -> Data? {
        guard let image = UIImage(data: rawData) else {
            return rawData.count <= maxImagePayloadBytes ? rawData : nil
        }

        let resized = resizedImage(image, maxDimension: 640)
        for quality in stride(from: 0.7, through: 0.3, by: -0.1) {
            if let data = resized.jpegData(compressionQuality: quality), data.count <= maxImagePayloadBytes {
                return data
            }
        }
        return nil
    }

    private func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
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
        resetHandshakeState()
        markConnected(peripheral)
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.lastErrorMessage = error?.localizedDescription ?? "Failed to connect."
        }
        pendingDeviceToConnect = nil
        resetHandshakeState()
        markDisconnectedState()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error {
            DispatchQueue.main.async {
                self.lastErrorMessage = error.localizedDescription
            }
        }
        let isActiveDisconnect = peripheral.identifier == activePeripheral?.identifier

        if let pendingDeviceToConnect {
            markDisconnectedState()
            self.pendingDeviceToConnect = nil
            connect(to: pendingDeviceToConnect)
            return
        }

        if isActiveDisconnect {
            markDisconnectedState()
        }
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

private extension BluetoothManager {
    struct IncomingImageBuffer {
        let fileExtension: String
        let expectedChunkCount: Int
        var chunks: [Int: String]
    }

    func resetHandshakeState() {
        didSendConnectRequestForSession = false
        didReceiveConnectRequestForSession = false
        isChatSessionEstablished = false
        incomingRequest = nil
    }
}

private extension String {
    func chunked(by chunkSize: Int) -> [String] {
        guard chunkSize > 0, !isEmpty else { return [] }
        var chunks: [String] = []
        var start = startIndex
        while start < endIndex {
            let end = index(start, offsetBy: chunkSize, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[start..<end]))
            start = end
        }
        return chunks
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
