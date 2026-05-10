//
//  HomeHeaderView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI
import CoreBluetooth

struct HomeHeaderView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("OffRoad")
                    .font(.system(size: 30, weight: .black))
                    .tracking(1.5)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 8)

                BluetoothStatusBadge(selectedTab: $selectedTab)
            }

            HStack {
                Text("Offline. Private. Yours.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(.top, 8)
    }
}

struct BluetoothStatusBadge: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var selectedTab: AppTab

    private var statusText: String {
        switch bluetoothManager.bluetoothState {
        case .poweredOn:
            return bluetoothManager.isScanning ? "Scanning..." : "Connected"
        case .poweredOff:
            return "BT Off"
        case .unauthorized:
            return "No Permission"
        default:
            return "Unavailable"
        }
    }

    private var nearbyCount: Int {
        bluetoothManager.discoveredDevices.count
    }

    private var statusColor: Color {
        switch bluetoothManager.bluetoothState {
        case .poweredOn: return .blue
        case .poweredOff: return .secondary
        case .unauthorized: return .red
        default: return .secondary
        }
    }

    var body: some View {
        Button(action: {
            selectedTab = .contacts
        }) {
            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(statusColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(statusText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.20))
                    Text("\(nearbyCount) nearby")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
}

#Preview {
    HomeHeaderView(selectedTab: .constant(.home))
        .environmentObject(BluetoothManager())
        .padding()
}
