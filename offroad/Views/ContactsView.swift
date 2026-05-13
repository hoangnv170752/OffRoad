//
//  ContactsView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI
import CoreBluetooth

struct ContactsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(AppSettings.self) var appSettings

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if bluetoothManager.permissionDenied {
                    permissionDeniedView
                } else if bluetoothManager.bluetoothState == .poweredOff {
                    bluetoothOffView
                } else {
                    scanningContent
                }
            }
            .navigationTitle(appSettings.localized("Contacts"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { bluetoothManager.refreshScan() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .disabled(bluetoothManager.isScanning)
                }
            }
        }
    }

    // MARK: - Scanning Content

    private var scanningContent: some View {
        VStack(spacing: 0) {
            scanStatusBar

            if bluetoothManager.discoveredDevices.isEmpty && !bluetoothManager.isScanning {
                emptyStateView
            } else {
                deviceList
            }
        }
    }

    private var scanStatusBar: some View {
        HStack(spacing: 8) {
            if bluetoothManager.isScanning {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Scanning for nearby devices...")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                Text("\(bluetoothManager.discoveredDevices.count) device(s) found")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    private var deviceList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(bluetoothManager.discoveredDevices) { device in
                    NavigationLink(destination: BluetoothChatView(device: device)) {
                        DeviceRow(device: device)
                    }
                    .buttonStyle(.plain)
                    Divider()
                        .padding(.leading, 72)
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No devices found")
                .font(.system(size: 17, weight: .semibold))
            Text("Make sure nearby devices have\nBluetooth enabled and are discoverable.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { bluetoothManager.startScanning() }) {
                Text("Scan Again")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.15, green: 0.40, blue: 0.30))
                    )
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bluetooth")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.6))
            Text("Bluetooth Permission Required")
                .font(.system(size: 17, weight: .semibold))
            Text("OffRoad needs Bluetooth access to\ndiscover nearby devices and send messages.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: openSettings) {
                Text("Open Settings")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Bluetooth Off

    private var bluetoothOffView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bluetooth")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Bluetooth is Off")
                .font(.system(size: 17, weight: .semibold))
            Text("Turn on Bluetooth to discover\nnearby devices.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: openSettings) {
                Text("Open Settings")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: DiscoveredDevice

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(.system(size: 15, weight: .semibold))
                HStack(spacing: 6) {
                    Text(device.distance)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    SignalBarsView(strength: device.signalStrength)
                    Text(device.signalStrength.label)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("Connect")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.15, green: 0.40, blue: 0.30))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .strokeBorder(Color(red: 0.15, green: 0.40, blue: 0.30), lineWidth: 1.5)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Signal Bars

struct SignalBarsView: View {
    let strength: DiscoveredDevice.SignalStrength

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < strength.bars ? Color.green : Color.secondary.opacity(0.2))
                    .frame(width: 3, height: CGFloat(6 + index * 3))
            }
        }
        .frame(height: 15)
    }
}

#Preview {
    ContactsView()
        .environmentObject(BluetoothManager())
}
