//
//  NearbyDevicesSection.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct NearbyDevicesSection: View {
    let devices: [NearbyDevice]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nearby Devices")
                .font(.system(size: 18, weight: .semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(devices) { device in
                        NearbyDeviceItemView(device: device)
                    }
                    AddScanItemView()
                }
            }
        }
    }
}

struct NearbyDeviceItemView: View {
    let device: NearbyDevice

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(device.avatarColor.opacity(0.25))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(device.name.prefix(1)))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(device.avatarColor)
                )
            Text(device.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
            Text(device.distance)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: 76)
    }
}

struct AddScanItemView: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                )
            Text("Add / Scan")
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
            Text("QR or Invite")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: 76)
    }
}

#Preview {
    NearbyDevicesSection(devices: NearbyDevice.mockData)
        .padding()
}
