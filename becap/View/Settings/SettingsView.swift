//
//  SettingsView.swift
//  becap
//
//  Created by Adam Mabrouki on 15/07/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var defiManager: DefiManager
    @StateObject private var vm: SettingsViewModel

    init(defiManager: DefiManager) {
        _vm = StateObject(wrappedValue: SettingsViewModel(defiManager: defiManager))
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 42)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 24)

                // Picker pour sélectionner un défi avant de gérer ses notifs
                if !vm.availableDefis.isEmpty {
                    Picker("Défi à configurer", selection: $vm.selectedDefi) {
                        ForEach(vm.availableDefis) { defi in
                            Text(defi.name).tag(Optional(defi))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
                }

                List {
                    NavigationLink("Créer un nouveau défi", destination: NewDefiView())
                    NavigationLink("Rejoindre un défi", destination: JoinDefiView())
                    if let defi = vm.currentDefi {
                        NavigationLink(
                            "Notifications",
                            destination: {
                                NotificationSettingsView(
                                    vm: NotificationSettingsViewModel(
                                        config: defi.notificationConfig,
                                        duration: defi.duration
                                    )
                                )
                            }
                        )
                    } else {
                        Label("Notifications", systemImage: "bell")
                            .foregroundColor(.gray)
                    }
                    Button("Se déconnecter") {
                        vm.signOut()
                    }
                    .foregroundStyle(.red)
                    .frame(alignment: .center)
                }
                .listStyle(.insetGrouped)
                .background(LinearGradient.petrolToSky.ignoresSafeArea())
            }
            .background(LinearGradient.petrolToSky.ignoresSafeArea())
            .onAppear {
                vm.refresh()
            }
        }
        .navigationViewStyle(.stack)
        .navigationDestination(isPresented: $vm.isSignedOut) {
            LoginView()
        }
    }
}
