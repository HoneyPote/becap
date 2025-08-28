//
//  CustomTableView.swift
//  becap
//
//  Created by Adam Mabrouki on 28/03/2022.
//

import SwiftUI

struct CustomTabView<Content: View>: View {
    let tabs: [TabItemData]
    @Binding var selectedIndex: Int
    @ViewBuilder let content: (Int) -> Content
    @StateObject private var keyboard = KeyboardResponder()

    var body: some View {
        ZStack {
            LinearGradient.petrolToSky.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(tabs.indices, id: \.self) { index in
                    content(index)
                        .tag(index)
                }
            }

            VStack {
                Spacer()
                if keyboard.keyboardHeight == 0 {
                    TabBottomView(selectedIndex: $selectedIndex, tabbarItems: tabs)
                        .padding(.bottom, 8)
                }
            }
            .onAppear {
                UITabBar.appearance().isHidden = true
            }
        }
    }
}
