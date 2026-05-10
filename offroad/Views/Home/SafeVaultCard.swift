//
//  SafeVaultCard.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct SafeVaultCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.25))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.85, green: 0.93, blue: 0.88))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("My Safe Vault")
                    .font(.system(size: 16, weight: .semibold))
                Text("End-to-end encrypted")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {}) {
                Text("Open")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.35))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .strokeBorder(Color(red: 0.15, green: 0.45, blue: 0.35), lineWidth: 1.5)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    SafeVaultCard()
        .padding()
}
