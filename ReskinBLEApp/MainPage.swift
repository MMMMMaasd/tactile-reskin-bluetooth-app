//
//  MainPage.swift
//  PolySense
//
//  Created by Michael on 2024/5/22.
//

import SwiftUI

struct MainPage: View {
    @EnvironmentObject var appStatus : AppInformation
    // Start the default page be the read page
    var body: some View {
        TabView(){
            Group{
                PeripheralView()
                    .tabItem {
                        Label("ble-device", systemImage: "iphone.gen1.radiowaves.left.and.right")
                }

                ReadView()
                    .tabItem {
                        Label("read", systemImage: "dot.scope")
                }

                
                
                SettingsView()
                    .tabItem {
                        Label("settings", systemImage: "gear")
            
                    }

            }
                .toolbarBackground(.tabBackground, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
    }

    
}

#Preview {
    MainPage()
        .environmentObject(AppInformation())
}
