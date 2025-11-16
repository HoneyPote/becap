//
//  TabBottomView.swift
//  becap
//
//  Created by Adam Mabrouki on 28/03/2022.
//

import SwiftUI
import Foundation

struct TabBottomView: View {
    @Binding var selectedIndex: Int

    let tabbarItems: [TabItemData]

    var height: CGFloat = 70
    var width: CGFloat = UIScreen.main.bounds.width - 42

    var body: some View {
        HStack {
            Spacer()

            ForEach(tabbarItems.indices, id: \.self) { index in
                let item = tabbarItems[index]
                Button {
                    if selectedIndex == index {
                        NotificationCenter.default.post(name: .tabBarItemReselected,
                                                          object: TabType(rawValue: index))
                    } else {
                        selectedIndex = index
                    }
                } label: {
                    let isSelected = selectedIndex == index
                    TabItemView(data: item, isSelected: isSelected)
                }
                Spacer()
            }
        }
        .frame(width: width, height: height)
        .background(.ultraThinMaterial)
        .cornerRadius(33)
        .shadow(radius: 5, x: 0, y: 4)
    }
}

extension Notification.Name {
    static let tabBarItemReselected = Notification.Name("TabBarItemReselected")
}
