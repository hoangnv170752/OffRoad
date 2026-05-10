//
//  PrivacyBannerView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct PrivacyBannerView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.25))
                    Text("Offline & Private")
                        .font(.system(size: 17, weight: .semibold))
                }
                Text("Messages are stored only\non your phone and your\npartner's.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            Spacer()
            ZStack {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary.opacity(0.3))
                    .offset(x: -14)
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary.opacity(0.5))
                    .offset(x: 14)
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 16))
                    .foregroundColor(.blue.opacity(0.6))
            }
            .frame(width: 80)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    PrivacyBannerView()
        .padding()
}
