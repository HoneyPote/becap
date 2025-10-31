//
//  NotificationCenterViewModel.swift
//  becap
//
//  Created by ChatGPT on 2025-XX-XX.
//

import Foundation
import FirebaseFirestore

final class NotificationCenterViewModel: ObservableObject {
    @Published private(set) var sections: [NotificationSection] = []
    @Published private(set) var isLoading: Bool = true

    private let notificationService: NotificationService
    private let userManager: UserManagerProtocol
    private var listener: ListenerRegistration?
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter
    private let relativeFormatter: RelativeDateTimeFormatter

    init(notificationService: NotificationService = NotificationService.shared,
         userManager: UserManagerProtocol = UserManager.shared) {
        self.notificationService = notificationService
        self.userManager = userManager

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        self.dateFormatter = formatter

        let relative = RelativeDateTimeFormatter()
        relative.locale = Locale(identifier: "fr_FR")
        relative.unitsStyle = .full
        self.relativeFormatter = relative
    }

    deinit {
        stop()
    }

    func start() {
        guard let userId = userManager.currentUser?.id else {
            sections = []
            isLoading = false
            return
        }

        listener?.remove()
        listener = notificationService.observeNotifications(for: userId) { [weak self] notifications in
            self?.handle(notifications: notifications)
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func markAllAsRead() {
        guard let userId = userManager.currentUser?.id else { return }
        let ids = sections.flatMap { $0.items.map { $0.id } }
        Task { await notificationService.markNotificationsAsRead(ids, for: userId) }
    }

    func open(_ item: NotificationItemViewModel) {
        guard let userId = userManager.currentUser?.id else { return }

        if !item.isRead {
            Task { await notificationService.markNotificationsAsRead([item.id], for: userId) }
        }

        if let route = item.route {
            NotificationCenter.default.post(name: .didReceiveNotificationRoute, object: route)
        }
    }

    private func handle(notifications: [AppNotification]) {
        let sorted = notifications.sorted { $0.createdAt > $1.createdAt }

        let grouped = Dictionary(grouping: sorted) { notification in
            calendar.startOfDay(for: notification.createdAt)
        }

        let sections = grouped
            .sorted { $0.key > $1.key }
            .map { date, items in
                NotificationSection(title: sectionTitle(for: date),
                                     items: items.map { makeItem(from: $0) })
            }

        DispatchQueue.main.async {
            self.sections = sections
            self.isLoading = false
        }
    }

    private func makeItem(from notification: AppNotification) -> NotificationItemViewModel {
        let time = relativeFormatter.localizedString(for: notification.createdAt, relativeTo: Date())
        return NotificationItemViewModel(id: notification.id ?? UUID().uuidString,
                                         title: notification.title,
                                         message: notification.message,
                                         time: time,
                                         accentColor: accentColor(for: notification.type),
                                         iconName: iconName(for: notification.type),
                                         isRead: notification.isRead,
                                         route: notification.route)
    }

    private func sectionTitle(for date: Date) -> String {
        if calendar.isDateInToday(date) { return "Aujourd'hui" }
        if calendar.isDateInYesterday(date) { return "Hier" }
        if let daysBetween = calendar.dateComponents([.day], from: date, to: Date()).day,
           daysBetween < 7 {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.locale = Locale(identifier: "fr_FR")
            weekdayFormatter.dateFormat = "EEEE"
            return weekdayFormatter.string(from: date).capitalized
        }

        return dateFormatter.string(from: date)
    }

    private func accentColor(for kind: AppNotificationKind) -> String {
        switch kind {
        case .photoPosted:
            return "#34D399"
        case .like:
            return "#F472B6"
        case .comment:
            return "#60A5FA"
        case .reminder:
            return "#FBBF24"
        }
    }

    private func iconName(for kind: AppNotificationKind) -> String {
        switch kind {
        case .photoPosted:
            return "photo.fill.on.rectangle.fill"
        case .like:
            return "hand.thumbsup.fill"
        case .comment:
            return "text.bubble.fill"
        case .reminder:
            return "bell.badge.fill"
        }
    }
}
