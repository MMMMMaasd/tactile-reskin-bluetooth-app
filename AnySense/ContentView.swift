//
//  ContentView.swift
//  Anysense
//
//  Created by Michael on 2024/5/22.
//

import SwiftUI
import CoreBluetooth
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var appStatus : AppInformation
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var showPermissionAlert = false
    var body: some View {
        if appStatus.ifGoToNextPage == 0{
            VStack {
                Image("Anysense_Logo")
                    .resizable()
                    .frame(width:180.0, height: 220.0)
                    .cornerRadius(30.0)
                Text("Welcome to AnySense")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .bold()
                Button(action: {
                    appStatus.checkCameraPermissions { granted in
                        if granted {
                            appStatus.initializeARSession()
                            appStatus.ifGoToNextPage = 1
                            UIImpactFeedbackGenerator(style: appStatus.hapticFeedbackLevel).impactOccurred()
                        } else {
                            showPermissionAlert = true
                        }
                    }
                }) {
                    Image("StartButton")
                        .resizable()
                        .frame(width: 200, height: 200)
                }
                .padding(.top, 10.0)
                .background(.background)
            }
            .alert(isPresented: $showPermissionAlert) {
                Alert(
                    title: Text("Camera Access Required"),
                    message: Text("Please enable camera access in Settings to use AR features."),
                    primaryButton: .default(Text("Settings"), action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }),
                    secondaryButton: .cancel()
                )
            }
        }else{
            MainPage()
        }
    }
}


class AppInformation : ObservableObject{
    @Published var ifGoToNextPage = 0
    @Published var ifAllowedRead = 0
    @Published var animationFPS: Double = 30.0
    @Published var hapticFeedbackLevel: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    @Published var rgbdVideoStreaming: StreamingMode = .off
    @Published var gridProjectionTrigger: String = "off"
    @Published var colorMapTrigger: Bool = false
    @Published var ifTactileConnected: Bool = false
    @Published var sharedARViewModel: ARViewModel!
    @Published var ifRecordedOnce: Bool = false
    init() {
        // Make sure AR model initialized before the app entering main page
//        self.sharedBluetoothManager = BluetoothManager(appStatus: self)
        self.sharedARViewModel = ARViewModel()
    }
    
    func initializeARSession() {
        sharedARViewModel.startSession()
    }
    
    func checkCameraPermissions(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AppInformation())
}


