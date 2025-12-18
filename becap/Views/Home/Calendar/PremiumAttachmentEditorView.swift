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

    private var dayRange: [Int] { Array(1...max(viewModel.challenge.duration, 1)) }

    var body: some View {
        NavigationView {
            Form {
                Section("Jour ciblé") {
                    Picker("Jour", selection: $selectedDay) {
                        ForEach(dayRange, id: \.self) { day in
                            Text("Jour \(day)").tag(day)
                        }
                    }
                }

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
            }
            .onChange(of: mediaPickerItem) { newItem in
                guard let newItem else { return }
                Task { await handleMediaPick(newItem) }
            }
            .onAppear {
                selectedDay = min(max(selectedDay, 1), viewModel.challenge.duration)
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

            await viewModel.addAttachment(data: data,
                                          title: filename,
                                          kind: .media,
                                          dayIndex: selectedDay)
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
                let data = try Data(contentsOf: url)
                await viewModel.addAttachment(data: data,
                                              title: url.lastPathComponent,
                                              kind: .pdf,
                                              dayIndex: selectedDay)
            } catch {
                await MainActor.run { errorMessage = "Lecture du PDF impossible." }
            }
        case .failure(let error):
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
}
