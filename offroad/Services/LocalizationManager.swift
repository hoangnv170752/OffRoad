//
//  LocalizationManager.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

extension String {
    func localized(lang: String) -> String {
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}

extension AppSettings {
    func localized(_ key: String) -> String {
        key.localized(lang: language.rawValue)
    }
}
