//
//  USBInterfaceAppApp.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/22.
//

import SwiftUI
import BackgroundTasks
    
@main
struct USBInterfaceAppApp: App {
    //let backgroundTaskManager = BackgroundTaskManager()
    //@Environment(\.scenePhase) private var phase
    var body: some Scene {
        @StateObject var appStatus = AppInformation()
        WindowGroup {
            ContentView().environmentObject(appStatus)
        }
    }
}
