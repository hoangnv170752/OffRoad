//
//  ContactsView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ContactsView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("No contacts yet")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Contacts")
        }
    }
}

#Preview {
    ContactsView()
}
