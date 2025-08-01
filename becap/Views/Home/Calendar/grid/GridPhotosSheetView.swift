//
//  GridPhotosSheetView.swift
//  becap
//
//  Created by Adam Mabrouki on 01/08/2025.
//
import SwiftUI

struct GridPhotosSheetView: View {
    @ObservedObject private var viewModel: GridPhotosSheetViewModel
    let onClose: () -> Void

    @State private var selectedPhoto: ChallengePhoto?

    init(cell: CalendarDetailCell, onClose: @escaping () -> Void) {
        self._viewModel = ObservedObject(wrappedValue: GridPhotosSheetViewModel(cell: cell))
        self.onClose = onClose
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(viewModel.sortedPhotos.sorted(by: { $0.authorName.lowercased() < $1.authorName.lowercased() }), id: \.id) { photo in
                        VStack(spacing: 2) {
                            AsyncImage(url: URL(string: photo.imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                            Text(photo.authorName)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .onTapGesture {
                            selectedPhoto = photo
                        }
                    }
                }
                .padding()
                .navigationTitle(viewModel.formattedDate)
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { onClose() }
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            photoDetailSheet(for: photo)
        }
    }
    @ViewBuilder
    private func photoDetailSheet(for photo: ChallengePhoto) -> some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()

            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height) * 0.88

                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.07))
                            .frame(width: side, height: side)

                        AsyncImage(url: URL(string: photo.imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .scaleEffect(1.6)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .cornerRadius(22)
                                    .shadow(radius: 22)
                                    .transition(.opacity.combined(with: .scale))
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: side * 0.45, height: side * 0.45)
                                    .foregroundColor(.gray)
                                    .opacity(0.5)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: side, height: side)
                    }

                    .padding(.vertical, 20)
                    .padding(.bottom, 28)
                    Text(photo.authorName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 12)
                    if let desc = photo.description, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.top, 2)
                    }
                    Spacer()
                    Button("Fermer") { selectedPhoto = nil }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding(.bottom, 32)
                }
                .padding(.top, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}
