import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PremiumAttachmentEditorView: View {
    @ObservedObject var viewModel: CalendarDetailViewModel
    @Binding var selectedDay: Int
    @Binding var isPresented: Bool

    @State private var mediaPickerItem: PhotosPickerItem?
    @State private var isImportingPDF = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var pendingAttachment: PendingAttachment?

    var body: some View {
        NavigationView {
            Form {
                Section("Contenus existants") {
                    if viewModel.attachments(for: selectedDay).isEmpty {
                        Text("Aucun contenu premium pour ce jour.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.attachments(for: selectedDay)) { attachment in
                            HStack {
                                PremiumAttachmentRow(attachment: attachment)

                                Button(role: .destructive) {
                                    Task { await viewModel.removeAttachment(attachment) }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                }

                Section("Ajouter un contenu") {
                    PhotosPicker(selection: $mediaPickerItem,
                                 matching: .any(of: [.images, .videos])) {
                        Label("Photo ou vidéo", systemImage: "photo")
                    }

                    Button {
                        isImportingPDF = true
                    } label: {
                        Label("Document PDF", systemImage: "doc.richtext")
                    }
                }

                if let pendingAttachment {
                    Section("Contenu prêt à être ajouté") {
                        HStack {
                            Image(systemName: pendingAttachment.kind == .pdf ? "doc.richtext.fill" : "photo.fill")
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pendingAttachment.title)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                Text("Jour \(selectedDay)")
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button {
                            pendingAttachment = nil
                        } label: {
                            Label("Retirer la sélection", systemImage: "xmark.circle")
                        }
                        .foregroundColor(.red)
                    }
                }

                if viewModel.isSavingPremiumContent || isProcessing {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Sauvegarde en cours…")
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        Task { await confirmAdd() }
                    }
                    .disabled(pendingAttachment == nil || viewModel.isSavingPremiumContent || isProcessing)
                }
            }
            .onChange(of: mediaPickerItem) { newItem in
                guard let newItem else { return }
                Task { await handleMediaPick(newItem) }
            }
            .fileImporter(isPresented: $isImportingPDF,
                          allowedContentTypes: [.pdf]) { result in
                Task { await handlePDFImport(result) }
            }
        }
    }

    private func handleMediaPick(_ item: PhotosPickerItem) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let filename = item.itemIdentifier ?? "media-premium"
            let ext = item.supportedContentTypes.first?.preferredFilenameExtension

            await MainActor.run {
                pendingAttachment = PendingAttachment(data: data,
                                                      title: filename,
                                                      kind: .media,
                                                      fileExtension: ext)
            }
        } catch {
            await MainActor.run { errorMessage = "Import impossible : \(error.localizedDescription)" }
        }
    }

    private func handlePDFImport(_ result: Result<URL, Error>) async {
        isProcessing = true
        defer { isProcessing = false }

        switch result {
        case .success(let url):
            do {
                let scoped = url.startAccessingSecurityScopedResource()
                let data = try Data(contentsOf: url)
                if scoped { url.stopAccessingSecurityScopedResource() }
                await MainActor.run {
                    pendingAttachment = PendingAttachment(data: data,
                                                          title: url.lastPathComponent,
                                                          kind: .pdf,
                                                          fileExtension: url.pathExtension)
                }
            } catch {
                url.stopAccessingSecurityScopedResource()
                await MainActor.run { errorMessage = "Lecture du PDF impossible." }
            }
        case .failure(let error):
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func confirmAdd() async {
        guard let pendingAttachment else { return }

        await viewModel.addAttachment(data: pendingAttachment.data,
                                      title: pendingAttachment.title,
                                      kind: pendingAttachment.kind,
                                      dayIndex: selectedDay,
                                      fileExtension: pendingAttachment.fileExtension)
        await MainActor.run {
            self.pendingAttachment = nil
            isPresented = false
        }
    }
}

private struct PendingAttachment {
    let data: Data
    let title: String
    let kind: PremiumAttachmentKind
    let fileExtension: String?
}
