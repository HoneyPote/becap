//
//  CreatorConsoleView.swift
//  becap
//
//  Created by OpenAI Assistant on 2025-xx-xx.
//

import SwiftUI
import FirebaseFirestore

final class CreatorProgramManagementViewModel: ObservableObject {
    @Published var updates: [CreatorUpdate] = []
    @Published var enrollmentCount: Int = 0

    private let challenge: Challenge
    private let challengeManager: ChallengeManager
    private var updatesListener: ListenerRegistration?

    init(challenge: Challenge, challengeManager: ChallengeManager = .shared) {
        self.challenge = challenge
        self.challengeManager = challengeManager
    }

    deinit { updatesListener?.remove() }

    func start() {
        updatesListener = challengeManager.listenCreatorUpdates(for: challenge.id) { [weak self] updates in
            DispatchQueue.main.async {
                self?.updates = updates
            }
        }

        Task { [weak self] in
            guard let self else { return }
            let count = (try? await challengeManager.enrollmentCount(for: challenge.id)) ?? 0
            await MainActor.run { self.enrollmentCount = count }
        }
    }

    func postUpdate(text: String, mediaUrl: String?) async throws {
        let update = CreatorUpdate(authorId: challengeManager.currentUser?.id ?? "",
                                   createdAt: Date(),
                                   text: text,
                                   mediaUrl: mediaUrl,
                                   mediaType: mediaUrl == nil ? nil : "image")
        try await challengeManager.createCreatorUpdate(for: challenge.id, update: update)
    }
}

struct CreatorConsoleView: View {
    @ObservedObject private var challengeManager = ChallengeManager.shared

    private var creatorPrograms: [Challenge] {
        guard let userId = challengeManager.currentUser?.id else { return [] }
        return challengeManager.challenges.filter { $0.isCoachProgram && (($0.creatorId ?? $0.creatorUID) == userId) }
    }

    var body: some View {
        List {
            if creatorPrograms.isEmpty {
                Text("Aucun programme coach configuré pour votre compte.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(creatorPrograms) { challenge in
                    NavigationLink(destination: CreatorProgramManagementView(challenge: challenge)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(challenge.title)
                                .font(.headline)
                            Text(challenge.shortTagline ?? "Programme coach")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Console coach")
    }
}

struct CreatorProgramManagementView: View {
    let challenge: Challenge
    @StateObject private var viewModel: CreatorProgramManagementViewModel
    @State private var updateText: String = ""
    @State private var mediaUrl: String = ""
    @State private var isPosting = false
    @State private var errorMessage: String?

    init(challenge: Challenge) {
        self.challenge = challenge
        _viewModel = StateObject(wrappedValue: CreatorProgramManagementViewModel(challenge: challenge))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                statsSection
                postComposer
                updatesList
            }
            .padding()
        }
        .navigationTitle("Gestion programme")
        .onAppear { viewModel.start() }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistiques")
                .font(.headline)
            Text("Participants : \(viewModel.enrollmentCount)")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var postComposer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Publier une update")
                .font(.headline)
            TextEditor(text: $updateText)
                .frame(height: 120)
                .padding(8)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            TextField("URL image (optionnel)", text: $mediaUrl)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button {
                Task {
                    await postUpdate()
                }
            } label: {
                if isPosting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Publier")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPosting || updateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var updatesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Updates publiées")
                .font(.headline)

            if viewModel.updates.isEmpty {
                Text("Aucune update pour le moment.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.updates) { update in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(update.text)
                            .foregroundColor(.primary)
                        Text(update.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func postUpdate() async {
        guard !updateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isPosting = true
        errorMessage = nil
        do {
            try await viewModel.postUpdate(text: updateText, mediaUrl: mediaUrl.isEmpty ? nil : mediaUrl)
            await MainActor.run {
                updateText = ""
                mediaUrl = ""
            }
        } catch {
            await MainActor.run {
                errorMessage = "Impossible de publier l’update."
            }
        }
        await MainActor.run { isPosting = false }
    }
}

