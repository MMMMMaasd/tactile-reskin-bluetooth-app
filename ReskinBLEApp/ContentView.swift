//
//  ContentView.swift
//  PolySense
//
//  Created by Michael on 2024/5/22.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var appStatus : AppInformation
    var body: some View {
        if appStatus.ifGoToNextPage == 0{
            VStack {
                Image("PolySense_Logo")
                    .resizable()
                    .frame(width:180.0, height: 220.0)
                Text("Welcome to PolySense")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .bold()
                Button(action: {
                    appStatus.initializeARSession()
                    appStatus.ifGoToNextPage = 1
                    if(appStatus.hapticFeedbackLevel == "medium") {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    } else if (appStatus.hapticFeedbackLevel == "heavy") {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                    } else if (appStatus.hapticFeedbackLevel == "light") {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }) {
                    Image("StartButton")
                        .resizable()
                        .frame(width: 150, height: 150)
                }
                .padding(.top, 10.0)
                .background(.white)
            }
        }else{
            MainPage()
        }
    }
}


class AppInformation : ObservableObject{
    @Published var ifGoToNextPage = 0
    @Published var ifAllowedRead = 0
    //@Published var sharedBluetoothManager =  BluetoothManager(self)
//    @Published var tactileRecordTimeInterval: Double = 0.1
    @Published var animationFPS: Double = 30.0
    @Published var hapticFeedbackLevel: String = "medium"
    @Published var rgbdVideoStreaming: StreamingMode = .off
    @Published var gridProjectionTrigger: String = "off"
    @Published var colorMapTrigger: Bool = false
    @Published var ifTactileConnected: Bool = false
    @Published var peripherals: [CBPeripheral] = []
    @Published var sharedBluetoothManager: BluetoothManager!
    @Published var sharedARViewModel: ARViewModel!
    init() {
        // Make sure bluetooth and AR model initialized before the app entering main page
        self.sharedBluetoothManager = BluetoothManager(appStatus: self)
        self.sharedARViewModel = ARViewModel()
    }
    
    func initializeARSession() {
        sharedARViewModel.startSession()
    }
}


#Preview {
    ContentView()
        .environmentObject(AppInformation())
}


