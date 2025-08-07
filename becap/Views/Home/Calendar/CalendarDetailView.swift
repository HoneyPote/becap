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
                challengeTitle: viewModel.challenge.title,
                onClose: { selectedGridCell = nil }
            )
        }
        .onAppear { viewModel.fetchInfos() }
        .refreshable { viewModel.fetchInfos() }
        .navigationBarHidden(true)
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        showNotifSheet = true
                    }) {
                        GlassCircleIcon(systemName: "bell.fill")
                    }

                    Button(action: {
                        showJoinSheet = true
                    }) {
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
            .padding(.top, 12)

            Text(viewModel.challenge.title)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 10)
        }
    }

    private var filterView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                )

            Picker("Filtrer par", selection: $selectedParticipant) {
                Text("Tous").tag(Participant?.none)
                ForEach(viewModel.participants, id: \.self) { participant in
                    Text(participant.name).tag(Optional(participant))
                }
            }
            .pickerStyle(.segmented)
            .padding(4)
        }
        .frame(height: 42)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    func photoPagerSheetView(info: PagerInfo) -> some View {
        CalendarPhotoPagerView(
            challengeTitle: viewModel.challenge.title,
            photos: info.photos,
            startIndex: info.index,
            canDelete: viewModel.canDeletePhoto(photos: info.photos),
            getParticipant: { viewModel.participant(for: $0)},
            onDelete: { photo in viewModel.deletePhoto(photo) },
            onClose: { viewModel.selectedPagerInfo = nil }
        )
    }
}

struct CalendarDayButtonView: View {
    let cell: CalendarDetailCell
    var isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled { action() }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cell.date, style: .date)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundColor(.white)

                    if cell.isToday {
                        Text("Aujourd’hui")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.85))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("\(cell.photos.count) photo(s)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.caption)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cell.isToday ? Color.green.opacity(0.25) : Color.white.opacity(0.08))
            )
        }
        .disabled(!isEnabled)
    }
}

struct CalendarCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.21), radius: 10, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.4), lineWidth: 0.7)
                )
            content
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
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
