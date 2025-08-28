//
//  GridPhotosSheetViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 01/08/2025.
//

import SwiftUI

class GridPhotosSheetViewModel: ObservableObject {
    let cell: CalendarDetailCell

    init(cell: CalendarDetailCell) {
        self.cell = cell
    }

    /// Les photos triées par nom d’auteur
    var sortedPhotos: [ChallengePhoto] {
        cell.photos.sorted { $0.authorName.lowercased() < $1.authorName.lowercased() }
    }

    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.locale = Locale(identifier: "fr_FR")

        return dateFormatter.string(from: cell.date)
    }
}
