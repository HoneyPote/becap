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

    /// Titre du jour, formaté lisiblement
    var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .full
        return df.string(from: cell.date)
    }
}
