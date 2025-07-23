//
//  CalendarPhotoPagerView.swift
//  becap
//
//  Created by Adam Mabrouki on 18/07/2025.
//

import SwiftUI

struct CalendarPhotoPagerView: View {
    let photos: [PhotoDefi]
    let startIndex: Int
    let onDelete: (PhotoDefi) -> Void
    let onClose: () -> Void

    @State private var page: Int

    init(photos: [PhotoDefi], startIndex: Int, onDelete: @escaping (PhotoDefi) -> Void, onClose: @escaping () -> Void) {
        self.photos = photos
        self.startIndex = startIndex
        self.onDelete = onDelete
        self.onClose = onClose
        _page = State(initialValue: startIndex)
    }

    var body: some View {
        NavigationView {
            TabView(selection: $page) {
                ForEach(photos.indices, id: \.self) { idx in
                    let photo = photos[idx]
                    VStack {
                        ZStack(alignment: .bottom) {
                            if let uiImage = UIImage(contentsOfFile: photo.imagePath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(16)
                                    .padding()
                                    .transition(.opacity)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .cornerRadius(16)
                                    .padding()
                                    .overlay(Text("No Image"))
                            }
                            if let desc = photo.description, !desc.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(desc)
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding(.bottom, 2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.2)]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(18)
                                .padding(.bottom, 24)
                                .padding(.horizontal, 30)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }

                        // Infos sous la photo
                        Text(photo.prenomAuteur)
                            .font(.title2)
                            .padding(.top)
                        Text(photo.date, style: .date)
                            .font(.body)
                            .foregroundColor(.gray)
                        Text(photo.date, style: .time)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        // Plus de bouton delete ici !
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: page)
            .navigationTitle("Photos (\(photos.count))")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { onClose() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !photos.isEmpty {
                        Button(role: .destructive) {
                            onDelete(photos[page])
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }
}
