//
//  ShareChallengeView.swift
//  becap
//
//  Created by Adam Mabrouki on 23/07/2025.
//

import SwiftUI

struct ShareChallengeView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ShareChallengeViewModel()

    @State private var shareItems: [Any] = []
    @State private var isShareSheetPresented = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("iphone_wallpaper_forest")
                         .resizable()
                         .scaledToFill()
                         .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header

                        GlassCard {
                            challengePickerSection
                        }

                        GlassCard {
                            shareDescriptionSection
                        }

                        shareButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 36)
                    .padding(.bottom, 44)
                }
                .refreshable { await viewModel.loadChallenges() }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .accessibilityLabel("Fermer")
                }
            }
        }
        .task { await viewModel.loadChallengesIfNeeded() }
        .sheet(isPresented: $isShareSheetPresented) {
            if !shareItems.isEmpty {
                ShareSheet(activityItems: shareItems)
            }
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Partager un défi")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

            Text("Choisis un défi actif et partage son lien d'accès en quelques secondes.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var challengePickerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sélectionne ton défi")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
                    .foregroundColor(.white)

                Text("Tous les défis en cours auxquels tu participes sont listés ci-dessous.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.72))
            }

            if viewModel.isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Chargement des défis…")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.challenges.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.yellow)

                    Text("Aucun défi actif pour le moment")
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundColor(.white)

                    Text("Crée ou rejoins un défi pour le partager avec ton équipe !")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.challenges) { challenge in
                            ChallengeChip(
                                title: challenge.title,
                                subtitle: challenge.category?.displayName,
                                isSelected: viewModel.selectedChallenge == challenge
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    viewModel.selectedChallenge = challenge
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .modifier(ShakeEffect(animatableData: viewModel.shakeChallenge ? 1 : 0))
            }
        }
        .padding(4)
    }

    private var shareDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comment ça marche ?")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            Text("Un lien personnalisé sera généré et redirigera directement vers le calendrier du défi sélectionné.")
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shareButton: some View {
        Button {
            guard let items = viewModel.makeShareItems() else { return }
            shareItems = items
            isShareSheetPresented = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                Text("Partager le défi")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .textCase(.uppercase)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.28, green: 0.57, blue: 0.84),
                                Color(red: 0.20, green: 0.43, blue: 0.68)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedChallenge == nil || viewModel.isLoading)
        .opacity((viewModel.selectedChallenge == nil || viewModel.isLoading) ? 0.6 : 1)
        .modifier(ShakeEffect(animatableData: viewModel.shakeChallenge ? 1 : 0))
        .padding(.top, -6)
    }
}
