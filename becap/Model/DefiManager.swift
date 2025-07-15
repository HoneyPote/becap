//
//  DefiManager.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

// ChallengeApp/Managers/DefiManager.swift

import Foundation
import SwiftUI

class DefiManager: ObservableObject {
    @Published var defis: [Defi] = [] {
        didSet {
            sauvegarderDefis()
        }
    }
    @Published var photos: [PhotoDefi] = [] {
        didSet {
            sauvegarderPhotos()
        }
    }

    private let storageKey = "defis_stockes"
    private let photoKey = "photos_stockees"

    func ajouterDefi(_ defi: Defi) {
        defis.append(defi)
    }

    func ajouterPhoto(_ photo: PhotoDefi) {
        photos.append(photo)
    }

    func photosPour(defiId: UUID, date: Date, participant: String?) -> [PhotoDefi] {
        photos.filter { p in
            Calendar.current.isDate(p.date, inSameDayAs: date)
            && p.defiId == defiId
            && (participant == nil || p.prenomAuteur == participant!)
        }
    }

    func sauvegarderDefis() {
        do {
            let data = try JSONEncoder().encode(defis)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Erreur lors de la sauvegarde des défis: \(error)")
        }
    }

    func chargerDefis() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            defis = try JSONDecoder().decode([Defi].self, from: data)
        } catch {
            print("Erreur lors du chargement des défis: \(error)")
        }
    }

    func sauvegarderPhotos() {
        do {
            let data = try JSONEncoder().encode(photos)
            UserDefaults.standard.set(data, forKey: photoKey)
        } catch {
            print("Erreur lors de la sauvegarde des photos: \(error)")
        }
    }

    func chargerPhotos() {
        guard let data = UserDefaults.standard.data(forKey: photoKey) else { return }
        do {
            photos = try JSONDecoder().decode([PhotoDefi].self, from: data)
        } catch {
            print("Erreur lors du chargement des photos: \(error)")
        }
    }
}
