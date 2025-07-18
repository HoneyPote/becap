//
//  DefiManager.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import Foundation
import SwiftUI

class DefiManager: ObservableObject {
    @Published var defis: [Defi] = [] {
        didSet {
            saveDefis()
        }
    }
    @Published var photos: [PhotoDefi] = [] {
        didSet {
            savePhotos()
        }
    }

    private let storageKey = "stored_defis"
    private let photoKey = "stored_photos"

    func addPhoto(_ photo: PhotoDefi) {
        photos.append(photo)
    }

    func photosFor(defiId: UUID, date: Date, participant: String?) -> [PhotoDefi] {
        photos.filter { p in
            Calendar.current.isDate(p.date, inSameDayAs: date)
            && p.defiId == defiId
            && (participant == nil || p.prenomAuteur == participant!)
        }
    }

    func saveDefis() {
        do {
            let data = try JSONEncoder().encode(defis)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Error saving challenges: \(error)")
        }
    }

    func loadDefis() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            defis = try JSONDecoder().decode([Defi].self, from: data)
        } catch {
            print("Error loading challenges: \(error)")
        }
    }

    func savePhotos() {
        do {
            let data = try JSONEncoder().encode(photos)
            UserDefaults.standard.set(data, forKey: photoKey)
        } catch {
            print("Error saving photos: \(error)")
        }
    }

    func loadPhotos() {
        guard let data = UserDefaults.standard.data(forKey: photoKey) else { return }
        do {
            photos = try JSONDecoder().decode([PhotoDefi].self, from: data)
        } catch {
            print("Error loading photos: \(error)")
        }
    }

    func addDefi(_ defi: Defi) {
        defis.append(defi)
        NotificationManager.shared.scheduleAllNotifications(for: defi)
    }

    func removeDefi(_ defi: Defi) {
        defis.removeAll { $0.id == defi.id }
        NotificationManager.shared.removeNotifications(for: defi)
    }
}
