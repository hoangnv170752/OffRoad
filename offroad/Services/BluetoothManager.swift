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
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var permissionDenied = false

    private var centralManager: CBCentralManager!
    private var scanTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        discoveredDevices.removeAll()
        isScanning = true
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
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
                    lastSeen: Date()
                )
                self.discoveredDevices.append(device)
            }
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

// MARK: - DiscoveredDevice Model

struct DiscoveredDevice: Identifiable {
    let id = UUID()
    let peripheralId: UUID
    var name: String
    var rssi: Int
    var distance: String
    var lastSeen: Date

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

        var color: (any ShapeStyle) {
            switch self {
            case .excellent: return Color.green
            case .good: return Color.green.opacity(0.7)
            case .fair: return Color.orange
            case .weak: return Color.red.opacity(0.7)
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
