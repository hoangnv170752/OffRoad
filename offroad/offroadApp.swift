//
//  offroadApp.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

@main
struct offroadApp: App {
    @State private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(appSettings.theme.colorScheme)
                .environment(appSettings)
        }
    }
}
