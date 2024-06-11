//
//  USBInterfaceAppApp.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/22.
//

import SwiftUI

@main
struct USBInterfaceAppApp: App {
    var body: some Scene {
        @StateObject var appStatus = AppInformation()
        WindowGroup {
            ContentView().environmentObject(appStatus)
        }
    }
}
