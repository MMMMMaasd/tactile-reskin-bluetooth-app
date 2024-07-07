//
//  MainPage.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/22.
//

import SwiftUI

struct MainPage: View {
    @EnvironmentObject var appStatus : AppInformation
    var body: some View {
        TabView{
            Group{
                RecordView()
                    /*
                        .navigationTitle("Data")
                        .toolbarBackground(.tabBackground, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                     */
                    .tabItem {
                        Label("data stroage", systemImage: "externaldrive.fill.badge.person.crop")
                }
                ReadView()
                    .tabItem {
                        Label("read", systemImage: "dot.scope")
                }
                /*
                DeviceView()
                    .tabItem {
                        Label("ble-device", systemImage: "iphone.gen1.radiowaves.left.and.right")
                }
                 */
                AccountView()
                    .tabItem {
                        Label("account", systemImage:"person.circle.fill")
            
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
