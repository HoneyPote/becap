//
//  MainTabView.swift
//  MyVin
//
//  Created by Adam Mabrouki on 28/03/2022.
//

import Foundation

struct TabItemData {
    let image: String
    let selectedImage: String
    let title: String
}

enum TabType: Int, CaseIterable {
    case home = 0
    case camera
    case settings

    var tabItem: TabItemData {
        switch self {
        case .home:
            return TabItemData(image: "house", selectedImage: "house.fill", title: "")
        case .camera:
            return TabItemData(image: "camera", selectedImage: "camera.fill", title: "")
        case .settings:
            return TabItemData(image: "gearshape", selectedImage: "gearshape.fill", title: "")
        }
    }
}

extension TabType {
    static var allTabItems: [TabItemData] {
        TabType.allCases.map { $0.tabItem }
    }
}
