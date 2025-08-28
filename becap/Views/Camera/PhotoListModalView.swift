//
//  PhotoListModalView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// TODO: Utile ? (Vue appelée nulle part)
import SwiftUI

//struct PhotoListModalView: View {
//    var challenge: Challenge
//    var date: Date
//    var participant: String?
//    @EnvironmentObject var challengeManager: ChallengeManager
//    @Environment(\.dismiss) var dismiss
//    @State private var toDelete: ChallengePhoto?
//    @State private var showDeleteAlert = false
//
//    var photos: [ChallengePhoto] {
//        (challengeManager.photos[challenge.id ?? ""] ?? [])
//            .filter {
//                Calendar.current.isDate($0.date, inSameDayAs: date)
//                && (participant == nil || $0.authorName == participant)
//            }
//    }
//
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Photos du \(formatted(date))")
//                .font(.headline)
//
//            if let participant = participant {
//                Text("Filtré : \(participant)")
//            } else {
//                Text("Tous les participants")
//            }
//
//            if photos.isEmpty {
//                Spacer()
//                Text("📸 Aucune photo enregistrée")
//                Spacer()
//            } else {
//                ScrollView {
//                    ForEach(photos) { photo in
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(photo.authorName)
//                                    .font(.subheadline)
//                                Spacer()
//                                Button(role: .destructive) {
//                                    toDelete = photo
//                                    showDeleteAlert = true
//                                } label: {
//                                    Image(systemName: "trash")
//                                        .foregroundColor(.red)
//                                }
//                            }
//                            .padding(.bottom, 2)
//                            if let url = URL(string: photo.imageUrl) {
//                                AsyncImage(url: url) { phase in
//                                    switch phase {
//                                    case .success(let image):
//                                        image
//                                            .resizable()
//                                            .scaledToFit()
//                                            .frame(maxHeight: 200)
//                                            .cornerRadius(10)
//                                    case .failure:
//                                        Text("Image introuvable")
//                                            .foregroundColor(.gray)
//                                    case .empty:
//                                        ProgressView()
//                                    @unknown default:
//                                        EmptyView()
//                                    }
//                                }
//                            } else {
//                                Text("URL invalide")
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                        .padding()
//                    }
//                }
//            }
//        }
//        .padding()
//        .navigationTitle("Détails")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Fermer") { dismiss() }
//            }
//        }
//        .alert("Supprimer la photo ?", isPresented: $showDeleteAlert, presenting: toDelete) { photo in
//            Button("Supprimer", role: .destructive) {
//                //  supprimer(photo)
//            }
//            Button("Annuler", role: .cancel) {}
//        } message: { _ in
//            Text("Cette action est irréversible.")
//        }
//    }
//
//    //    func supprimer(_ photo: ChallengePhoto) {
//    //        challengeManager.deletePhoto(photo) { _ in }
//    //    }
//
//    func formatted(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .long
//        return formatter.string(from: date)
//    }
//}
