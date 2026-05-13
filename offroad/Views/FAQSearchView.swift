//
//  FAQSearchView.swift
//  offroad
//
//  Created by Codex on 13/5/26.
//

import SwiftUI

struct FAQItem: Identifiable, Hashable {
    let id = UUID()
    let question: String
    let answer: String
    let category: String
}

struct FAQSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if filteredFAQs.isEmpty {
                    emptyState
                } else {
                    faqList
                }
            }
            .navigationTitle(appSettings.localized("Search FAQ"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(appSettings.localized("Search questions"))
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appSettings.localized("Done")) { dismiss() }
                }
            }
        }
    }

    // MARK: - List

    private var faqList: some View {
        List {
            ForEach(groupedFAQs, id: \.0) { section in
                Section(header: Text(section.0)) {
                    ForEach(section.1) { faq in
                        DisclosureGroup {
                            Text(faq.answer)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        } label: {
                            Text(faq.question)
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary.opacity(0.6))
            Text(appSettings.localized("No matching questions"))
                .font(.system(size: 16, weight: .semibold))
            Text(appSettings.localized("Try a different keyword."))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Data

    private var filteredFAQs: [FAQItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Self.allFAQs }
        return Self.allFAQs.filter { faq in
            faq.question.localizedCaseInsensitiveContains(trimmed)
            || faq.answer.localizedCaseInsensitiveContains(trimmed)
            || faq.category.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var groupedFAQs: [(String, [FAQItem])] {
        let groups = Dictionary(grouping: filteredFAQs, by: { $0.category })
        return groups
            .map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }
    }

    // MARK: - Static Content

    static let allFAQs: [FAQItem] = [
        FAQItem(
            question: "How does OFFROAD work without internet?",
            answer: "OFFROAD uses Bluetooth Low Energy to discover nearby devices and exchange messages directly, peer-to-peer, without any server.",
            category: "Getting Started"
        ),
        FAQItem(
            question: "How do I pair two devices?",
            answer: "Open the Home tab, wait until your friend's device appears in Nearby Devices, then tap it to start a Bluetooth chat. The other device will accept the connection automatically.",
            category: "Getting Started"
        ),
        FAQItem(
            question: "What is the maximum range?",
            answer: "Bluetooth Low Energy typically works within 10-30 meters, depending on obstacles and the environment.",
            category: "Connectivity"
        ),
        FAQItem(
            question: "Why can't I see my friend's device?",
            answer: "Make sure both devices have Bluetooth turned on, the OFFROAD app is open in the foreground, and grant Bluetooth permission when prompted.",
            category: "Connectivity"
        ),
        FAQItem(
            question: "Are my messages encrypted?",
            answer: "Yes. All messages are end-to-end encrypted on the device. Nothing is uploaded to any server.",
            category: "Privacy"
        ),
        FAQItem(
            question: "Where are my chats stored?",
            answer: "Chats are stored locally on your device only. Uninstalling the app removes all data permanently.",
            category: "Privacy"
        ),
        FAQItem(
            question: "Does OFFROAD use mobile data?",
            answer: "No. OFFROAD never uses cellular or Wi-Fi. All communication happens over Bluetooth.",
            category: "Privacy"
        ),
        FAQItem(
            question: "How do I change the theme?",
            answer: "Go to Settings → Appearance and pick System, Light, or Dark.",
            category: "Customization"
        )
    ]
}

#Preview {
    FAQSearchView()
        .environment(AppSettings())
}
