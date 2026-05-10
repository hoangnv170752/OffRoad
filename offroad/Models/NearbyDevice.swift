//
//  NearbyDevice.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct NearbyDevice: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let avatarColor: Color
}

extension NearbyDevice {
    static let mockData: [NearbyDevice] = [
        NearbyDevice(name: "Linh Nguyen", distance: "5 m", avatarColor: .green),
        NearbyDevice(name: "Alex Tran", distance: "12 m", avatarColor: .teal),
        NearbyDevice(name: "Mountain Crew", distance: "18 m", avatarColor: .brown),
    ]
}
