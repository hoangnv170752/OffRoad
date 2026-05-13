//
//  ChatInputBar.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onSendImage: (Data) -> Void
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var isFileImporterPresented = false
    @State private var isAttachmentMenuPresented = false
    @State private var pendingAttachmentData: Data?
    @State private var pendingAttachmentName: String?

    var body: some View {
        VStack(spacing: 8) {
            if let pendingAttachmentName {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                    Text(pendingAttachmentName)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    Spacer()
                    Button("Cancel", role: .destructive) {
                        clearPendingAttachment()
                    }
                    .font(.system(size: 13, weight: .medium))
                    Button("Send") {
                        sendPendingAttachment()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .disabled(pendingAttachmentData == nil)
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 12) {
                Button {
                    isAttachmentMenuPresented = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0.15, green: 0.40, blue: 0.30))
                }

                HStack {
                    TextField("Type a message...", text: $text)
                        .font(.system(size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .background(Color(.systemGray6))
                .clipShape(Capsule())

                Button(action: {
                    if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                        onSend()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(
                            text.trimmingCharacters(in: .whitespaces).isEmpty
                                ? .secondary
                                : Color(red: 0.15, green: 0.40, blue: 0.30)
                        )
                        .rotationEffect(.degrees(45))
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
        .confirmationDialog("Choose attachment", isPresented: $isAttachmentMenuPresented) {
            Button {
                isPhotoPickerPresented = true
            } label: {
                Label("Choose photo", systemImage: "photo")
            }
            Button("Choose image file") {
                isFileImporterPresented = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                if let data = try? Data(contentsOf: url) {
                    pendingAttachmentData = data
                    pendingAttachmentName = url.lastPathComponent
                }
            case .failure:
                break
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        pendingAttachmentData = data
                        pendingAttachmentName = "Selected photo"
                    }
                }
                await MainActor.run {
                    selectedPhotoItem = nil
                }
            }
        }
    }

    private func sendPendingAttachment() {
        guard let pendingAttachmentData else { return }
        onSendImage(pendingAttachmentData)
        clearPendingAttachment()
    }

    private func clearPendingAttachment() {
        pendingAttachmentData = nil
        pendingAttachmentName = nil
    }
}

#Preview {
    ChatInputBar(text: .constant("Hello")) {
        print("Send")
    } onSendImage: { _ in
        print("Send image")
    }
}
