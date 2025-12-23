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
                existingContentSection
                addContentSection
                pendingSection
                progressSection
                errorSection
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

    // MARK: - Sections

    private var existingContentSection: some View {
        Section("Contenus existants") {
            let items = viewModel.attachments(for: selectedDay)

            if items.isEmpty {
                Text("Aucun contenu premium pour ce jour.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(items) { attachment in
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
    }

    private var addContentSection: some View {
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
    }

    @ViewBuilder
    private var pendingSection: some View {
        if let attachment = pendingAttachment {
            Section("Contenu prêt à être ajouté") {
                let isPDF = (attachment.kind == .pdf)
                let iconName = isPDF ? "doc.richtext.fill" : "photo.fill"

                HStack {
                    Image(systemName: iconName)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(attachment.title)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Text("Jour \(selectedDay)")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    pendingAttachment = nil
                    errorMessage = nil
                } label: {
                    Label("Retirer la sélection", systemImage: "xmark.circle")
                }
                .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if viewModel.isSavingPremiumContent || isProcessing {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(viewModel.premiumSaveStage ?? "Sauvegarde en cours…")
                    }

                    ProgressView(value: max(0, min(viewModel.premiumSaveProgress, 1)))
                        .progressViewStyle(.linear)

                    Text("\(Int((viewModel.premiumSaveProgress) * 100))%")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage {
            Section {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Actions

    private func handleMediaPick(_ item: PhotosPickerItem) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        defer { Task { @MainActor in isProcessing = false } }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }

            let filename = item.itemIdentifier ?? "media-premium"
            let ext = item.supportedContentTypes.first?.preferredFilenameExtension

            await MainActor.run {
                pendingAttachment = PendingAttachment(
                    data: data,
                    title: filename,
                    kind: .media,
                    fileExtension: ext
                )
                // Optionnel : pour pouvoir re-sélectionner le même élément
                mediaPickerItem = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = "Import impossible : \(error.localizedDescription)"
            }
        }
    }

    private func handlePDFImport(_ result: Result<URL, Error>) async {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        defer { Task { @MainActor in isProcessing = false } }

        switch result {
        case .success(let url):
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }

            do {
                let data = try Data(contentsOf: url)
                await MainActor.run {
                    pendingAttachment = PendingAttachment(
                        data: data,
                        title: url.lastPathComponent,
                        kind: .pdf,
                        fileExtension: url.pathExtension
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Lecture du PDF impossible."
                }
            }

        case .failure(let error):
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func confirmAdd() async {
        guard let pendingAttachment else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try await viewModel.addAttachment(
                data: pendingAttachment.data,
                title: pendingAttachment.title,
                kind: pendingAttachment.kind,
                dayIndex: selectedDay,
                fileExtension: pendingAttachment.fileExtension
            )
            self.pendingAttachment = nil
            isPresented = false
        } catch {
            errorMessage = "Sauvegarde impossible : \(error.localizedDescription)"
        }
    }
}

private struct PendingAttachment {
    let data: Data
    let title: String
    let kind: PremiumAttachmentKind
    let fileExtension: String?
}
