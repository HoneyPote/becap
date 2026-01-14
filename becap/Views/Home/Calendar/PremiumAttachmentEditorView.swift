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
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 27 / 255, green: 40 / 255, blue: 74 / 255),
                    Color(red: 21 / 255, green: 73 / 255, blue: 114 / 255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        existingContentSection
                        addContentSection
                        pendingSection
                        progressSection
                        errorSection
                    }
                    .padding()
                }

                confirmButton
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

    private var header: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 5, x: 0, y: 2)
            }
            .buttonStyle(.hapticPlain)

            Spacer()

            VStack(spacing: 2) {
                Text("Contenu premium")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundColor(.white)
                Text("Jour \(selectedDay)")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(Color.white.opacity(0.7))
            }

            Spacer(minLength: 36)
        }
        .padding(.horizontal)
        .padding(.top, 30)
    }

    private var confirmButton: some View {
        Button(action: { Task { await confirmAdd() } }) {
            Text("Ajouter")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 82 / 255, green: 207 / 255, blue: 144 / 255),
                            Color(red: 27 / 255, green: 188 / 255, blue: 155 / 255)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(Color(red: 9 / 255, green: 34 / 255, blue: 44 / 255))
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
        .padding(.top, 2)
        .disabled(pendingAttachment == nil || viewModel.isSavingPremiumContent || isProcessing)
        .hapticTap()
    }

    // MARK: - Sections

    private var existingContentSection: some View {
        let items = viewModel.attachments(for: selectedDay)

        return premiumCard(title: "Contenus existants", subtitle: "Vos contenus déjà associés à ce jour") {
            if items.isEmpty {
                Text("Aucun contenu premium pour ce jour.")
                    .foregroundColor(.white.opacity(0.75))
                    .font(.system(.subheadline, design: .rounded))
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { attachment in
                        HStack(spacing: 12) {
                            PremiumAttachmentRow(attachment: attachment)

                            Spacer()

                            Button(role: .destructive) {
                                Task { await viewModel.removeAttachment(attachment) }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Color(red: 255 / 255, green: 112 / 255, blue: 112 / 255))
                                    .padding(10)
                                    .background(Color.white.opacity(0.16))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.hapticPlain)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var addContentSection: some View {
        premiumCard(title: "Ajouter un contenu", subtitle: "Photo, vidéo ou document premium") {
            VStack(spacing: 12) {
                PhotosPicker(selection: $mediaPickerItem,
                             matching: .any(of: [.images, .videos])) {
                    addRow(title: "Photo ou vidéo", systemImage: "photo")
                }
                .hapticTap()

                Button {
                    isImportingPDF = true
                } label: {
                    addRow(title: "Document PDF", systemImage: "doc.richtext")
                }
                .buttonStyle(.hapticPlain)
            }
        }
    }

    @ViewBuilder
    private var pendingSection: some View {
        if let attachment = pendingAttachment {
            premiumCard(title: "Contenu prêt à être ajouté", subtitle: "Aperçu de votre sélection") {
                let isPDF = (attachment.kind == .pdf)
                let iconName = isPDF ? "doc.richtext.fill" : "photo.fill"

                HStack(spacing: 12) {
                    Image(systemName: iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(attachment.title)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(.white)
                        Text("Jour \(selectedDay)")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.white.opacity(0.72))
                    }

                    Spacer()

                    Button {
                        pendingAttachment = nil
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 255 / 255, green: 112 / 255, blue: 112 / 255))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.hapticPlain)
                }
            }
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if viewModel.isSavingPremiumContent || isProcessing {
            premiumCard(title: "Import en cours", subtitle: "Ne quittez pas l'écran") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(viewModel.premiumSaveStage ?? "Sauvegarde en cours…")
                            .foregroundColor(.white)
                    }

                    ProgressView(value: max(0, min(viewModel.premiumSaveProgress, 1)))
                        .progressViewStyle(.linear)
                        .tint(Color.white.opacity(0.9))

                    Text("\(Int((viewModel.premiumSaveProgress) * 100))%")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage {
            premiumCard(title: "Erreur", subtitle: "Un problème est survenu") {
                Text(errorMessage)
                    .foregroundColor(Color(red: 255 / 255, green: 112 / 255, blue: 112 / 255))
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
        }
    }

    // MARK: - UI helpers

    private func premiumCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                Text(subtitle)
                    .foregroundColor(Color.white.opacity(0.7))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }

            content()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 58 / 255, green: 107 / 255, blue: 173 / 255).opacity(0.88),
                            Color(red: 47 / 255, green: 146 / 255, blue: 200 / 255).opacity(0.76)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 16)
    }

    private func addRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())

            Text(title)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
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
