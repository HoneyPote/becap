//
//  NotificationSettingsViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 19/07/2025.
//

import SwiftUI

enum NotificationConfigScope {
    case challenge
    case user
}

class NotificationSettingsViewModel: ObservableObject {
    @Published var challengeNotifTimes: [NotificationTime] = []
    @Published var userNotifTimes: [NotificationTime] = []

    private let challengeManager: ChallengeManager

    let currentChallenge: Challenge
    let currentParticipant: ParticipantUIModel

    var updatedChallengeConfig: [Int] {
        challengeNotifTimes.map { $0.minutes }
    }

    var updatedUserConfig: [Int] {
        userNotifTimes.map { $0.minutes }
    }

    init(challengeManager: ChallengeManager = ChallengeManager.shared,
         currentChallenge: Challenge,
         currentParticipant: ParticipantUIModel) {
        self.challengeManager = challengeManager
        self.currentChallenge = currentChallenge
        self.currentParticipant = currentParticipant

        // Un peu horrible faudra faire un truc ici un jour
        let challengeNotif = challengeManager.challenges.first(where: { $0.id == currentChallenge.id })?.defaultNotificationsConfig ?? []

        self.challengeNotifTimes = buildNotificationTimes(config: challengeNotif)
        self.userNotifTimes = buildNotificationTimes(config: currentParticipant.progress.notificationsConfig)
    }

    func addNotificationTime(scope: NotificationConfigScope) {
        var times = getNotifications(for: scope)
        guard times.count < 3 else { return }

        times.append(NotificationTime(id: UUID(), minutes: Date().convertToMinutes))
        setNotifications(times, for: scope)
    }

    func updateNotificationTime(scope: NotificationConfigScope, index: Int, newDate: Date) {
        var times = getNotifications(for: scope)
        guard times.indices.contains(index) else { return }

        times[index].minutes = newDate.convertToMinutes
        setNotifications(sortNotificationTimes(times), for: scope)
    }

    func removeNotificationTime(scope: NotificationConfigScope, index: Int) {
        var times = getNotifications(for: scope)
        guard times.indices.contains(index) else { return }

        times.remove(at: index)
        setNotifications(times, for: scope)
    }

    func resetNotificationTime(scope: NotificationConfigScope) {
        setNotifications([], for: scope)
    }

    func copyChallengeNotifToUser() {
        setNotifications(challengeNotifTimes, for: .user)
    }

    func saveConfigs() {
        challengeManager.updateChallengeNotifications(for: currentChallenge, config: updatedChallengeConfig)
        challengeManager.updateUserNotifications(for: currentParticipant.userId, challenge: currentChallenge, config: updatedUserConfig)
    }

    func getNotifications(for scope: NotificationConfigScope) -> [NotificationTime] {
        switch scope {
        case .challenge:
            return challengeNotifTimes
        case .user:
            return userNotifTimes
        }
    }

    private func sortNotificationTimes(_ times: [NotificationTime]) -> [NotificationTime] {
        Dictionary(grouping: times, by: \.minutes)
            .compactMap { $0.value.first }
            .sorted { $0.minutes < $1.minutes }
    }

    private func buildNotificationTimes(config: [Int]) -> [NotificationTime] {
        return config.map { NotificationTime(id: UUID(), minutes: $0) }
    }

    private func setNotifications(_ times: [NotificationTime], for scope: NotificationConfigScope) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            assign(times, to: scope)
        }
    }

    private func assign(_ times: [NotificationTime], to scope: NotificationConfigScope) {
        switch scope {
        case .challenge:
            challengeNotifTimes = times
        case .user:
            userNotifTimes = times
        }
    }
}
