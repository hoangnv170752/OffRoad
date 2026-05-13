//
//  NearbyDevicesSection.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct NearbyDevicesSection: View {
    let devices: [DiscoveredDevice]
    var onSelectDevice: (DiscoveredDevice) -> Void
    var onScanTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby Devices")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button("Scan Again", action: onScanTap)
                    .font(.system(size: 13, weight: .medium))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(devices) { device in
                        NearbyDeviceItemView(device: device) {
                            onSelectDevice(device)
                        }
                    }
                    AddScanItemView(onTap: onScanTap)
                }
            }
        }
    }
}

struct NearbyDeviceItemView: View {
    let device: DiscoveredDevice
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.blue.opacity(0.25))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(device.name.prefix(1)))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.blue)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(device.signalStrength.color)
                            .frame(width: 12, height: 12)
                    }
                Text(device.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(device.isConnected ? "Connected" : device.distance)
                    .font(.system(size: 11))
                    .foregroundStyle(device.isConnected ? Color.green : Color.secondary)
            }
            .frame(width: 76)
        }
        .buttonStyle(.plain)
    }
}

struct AddScanItemView: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.secondary)
                    )
                Text("Refresh")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text("Bluetooth")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 76)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NearbyDevicesSection(devices: [], onSelectDevice: { _ in }, onScanTap: {})
        .padding()
}
