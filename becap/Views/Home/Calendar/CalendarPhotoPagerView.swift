//
//  CalendarPhotoPagerView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//
import SwiftUI

struct CalendarPhotoPagerView: View {
    let photos: [ChallengePhoto]
    let startIndex: Int
    let canDelelte: Bool
    let onDelete: (ChallengePhoto) -> Void
    let onClose: () -> Void

    @State private var selection: Int

    init(photos: [ChallengePhoto],
         startIndex: Int = 0,
         canDelete: Bool,
         onDelete: @escaping (ChallengePhoto) -> Void,
         onClose: @escaping () -> Void) {
        self.photos = photos
        self.startIndex = startIndex
        self.canDelelte = canDelete
        self.onDelete = onDelete
        self.onClose = onClose
        _selection = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient.petrolToSky.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title)
                            .padding(10)
                            .background(Color.black.opacity(0.3).clipShape(Circle()))
                    }
                    .padding(.trailing, 12)
                }
                .frame(height: 24)

                if photos.isEmpty {
                    Spacer()
                    Text("Aucune photo")
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    TabView(selection: $selection) {
                        ForEach(photos.indices, id: \.self) { idx in
                            VStack(spacing: 18) {
                                if let url = URL(string: photos[idx].imageUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxHeight: 350)
                                                .cornerRadius(18)
                                                .shadow(radius: 12)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 120)
                                                .foregroundColor(.gray)
                                        case .empty:
                                            ProgressView()
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.gray)
                                }
                                Text(photos[idx].authorName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                if let desc = photos[idx].description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.85))
                                        .padding(.top, 2)
                                }
                                Text(photos[idx].date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.top, 4)
                            }
                            .padding()
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                    .animation(.default, value: selection)

                    // Bouton supprimer en haut à droite
                    if canDelelte {
                        HStack {
                            Spacer()
                            Button(role: .destructive) {
                                if !photos.isEmpty, selection < photos.count {
                                    onDelete(photos[selection])
                                }
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                                    .foregroundColor(.red)
                                    .padding(8)
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 16)
                        }
                        .frame(height: 44)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal)
        }
    }
}
