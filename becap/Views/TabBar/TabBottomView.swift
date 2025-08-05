//
//  TabBottomView.swift
//  MyVin
//
//  Created by Adam Mabrouki on 28/03/2022.
//

import SwiftUI

struct TabBottomView: View {
    let tabbarItems: [TabItemData]
    var height: CGFloat = 70
    var width: CGFloat = UIScreen.main.bounds.width - 42
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack {
            Spacer()
            
            ForEach(tabbarItems.indices, id: \.self) { index in
                let item = tabbarItems[index]
                Button {
                    self.selectedIndex = index
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
