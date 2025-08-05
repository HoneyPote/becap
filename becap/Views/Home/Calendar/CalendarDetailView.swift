import SwiftUI

struct PagerInfo: Identifiable {
    let id = UUID()
    var photos: [ChallengePhoto]
    var index: Int
    let date: Date
}

struct CalendarDetailView: View {

    @StateObject private var viewModel: CalendarDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedParticipant: Participant?
    @State private var selectedGridCell: CalendarDetailCell?
    @State private var showNotifSheet = false
    @State private var showJoinSheet = false

    init(challenge: Challenge) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(challenge: challenge))
    }

    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()
            VStack(spacing: 0) {
                headerView
                filterView

                // JOURNÉES
                ScrollView {
                    VStack(spacing: 10) {
                        if viewModel.doneLoadingPhotos {
                            ForEach(viewModel.buildDetailcells(for: selectedParticipant), id: \.self) { cell in
                                CalendarCard {
                                    CalendarDayButtonView(
                                        cell: cell,
                                        isEnabled: !cell.photos.isEmpty,
                                        action: {
                                            if selectedParticipant == nil {
                                                selectedGridCell = cell
                                            } else {
                                                viewModel.detailButtonClicked(cell: cell)
                                            }
                                        }
                                    )
                                }
                            }
                        } else {
                            ProgressView().padding()
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
        }
        .sheet(item: $viewModel.selectedPagerInfo) { info in
            photoPagerSheetView(info: info)
        }
        .sheet(item: $selectedGridCell) { cell in
            GridPhotosSheetView(
                cell: cell,
                getParticipant: { viewModel.participant(for: $0) },
                onClose: { selectedGridCell = nil }
            )
        }
        .onAppear { viewModel.fetchInfos() }
        .refreshable { viewModel.fetchInfos() }
        .navigationBarHidden(true)
    }

    // --- HEADER
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // --- Close button ---
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(12)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.19), radius: 8, x: 0, y: 4)
                }
                // Spacer pour centrer le titre
                Spacer()
                // --- Boutons à droite (bell + share) ---
                HStack(spacing: 10) {
                    Button {
                        showNotifSheet = true
                    } label: {
                        GlassCircleIcon(systemName: "bell.fill")
                    }
                    Button {
                        showJoinSheet = true
                    } label: {
                        GlassCircleIcon(systemName: "square.and.arrow.up.fill")
                    }
                }
                .sheet(isPresented: $showNotifSheet, onDismiss: {
                    viewModel.fetchInfos()
                }) {
                    NotificationSettingsView(challenge: viewModel.challenge)
                }
                .sheet(isPresented: $showJoinSheet) {
                    JoinChallengeView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // --- Title, centré ---
            Text(viewModel.challenge.title)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // --- PICKER
    private var filterView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(.clear)
                .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
            Picker("Filtrer par", selection: $selectedParticipant) {
                Text("Tous").tag(Participant?.none)
                ForEach(viewModel.participants, id: \.self) { participant in
                    Text(participant.name).tag(Optional(participant))
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 2)
            .padding(.vertical, 0)
        }
        .frame(height: 36)
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // --- SHEETS
    func photoPagerSheetView(info: PagerInfo) -> some View {
        CalendarPhotoPagerView(
            photos: info.photos,
            startIndex: info.index,
            canDelete: viewModel.canDeletePhoto(photos: info.photos),
            getParticipant: { viewModel.participant(for: $0)},
            onDelete: { photo in viewModel.deletePhoto(photo) },
            onClose: { viewModel.selectedPagerInfo = nil }
        )
    }
}

// --- BOUTON JOUR/PARTICIPANT REUTILISABLE ---
struct CalendarDayButtonView: View {
    let cell: CalendarDetailCell
    var isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled { action() }
        }) {
            HStack(spacing: 12) {
                Text(cell.date, style: .date)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundColor(.white)
                if cell.isToday {
                    Text("Aujourd’hui")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.9)))
                        .padding(.leading, 3)
                }
                Spacer()
                Text("\(cell.photos.count) photo(s)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(cellBackgroundView(isToday: cell.isToday))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!isEnabled)
    }

    // --- BACKGROUND
    @ViewBuilder
    private func cellBackgroundView(isToday: Bool) -> some View {
        if isToday {
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.82), Color.green.opacity(0.45)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white.opacity(0.10)
        }
    }
}

// --- CARTE ULTRA COMPACTE POUR CALENDRIER ---
struct CalendarCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.21), radius: 14, x: 0, y: 8)
                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.53), lineWidth: 0.7)
                                )
            content
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 0)
    }
}

struct GlassCircleIcon: View {
    let systemName: String
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.19), lineWidth: 0.7)
                )
                .shadow(color: Color.black.opacity(0.19), radius: 5, x: 0, y: 7)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
