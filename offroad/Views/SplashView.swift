//
//  SplashView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image("OffroadLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)

                    VStack(spacing: 6) {
                        Text("OffRoad")
                            .font(.system(size: 34, weight: .black))
                            .tracking(2)

                        Text("Offline. Private. Yours.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .opacity(textOpacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    logoOpacity = 1
                    logoScale = 1
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    textOpacity = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
