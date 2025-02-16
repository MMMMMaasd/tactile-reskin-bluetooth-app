//
//  peripheralView.swift
//  Anysense
//
//  Created by Michael on 2024/7/29.
//

import SwiftUI
import CoreBluetooth

struct singleBLEPeripheral: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var appStatus: AppInformation
    @State private var currentDeviceConnectStatus = false
    @State private var connectAlert : Bool = false
    let name: String
    let uuid: UUID
//    let peripheral: CBPeripheral
//    
//    init(peripheral: CBPeripheral) {
//        self.peripheral = peripheral
//    }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(.headline)
                Spacer()
            if(!appStatus.ifTactileConnected || currentDeviceConnectStatus){
                Button(action: {
                    if !currentDeviceConnectStatus{
//                        bluetoothManager.connectToPeripheral(peripheral: peripheral)
                        bluetoothManager.connectToPeripheral(withUUID: uuid) { result in
                            switch result {
                            case .success(let connectedPeripheral):
                                print("✅ Successfully connected to: \(connectedPeripheral.name ?? "Unknown Device")")
                            case .failure(let error):
                                print("❌ Connection failed: \(error.localizedDescription)")
                            }
                        }
                        currentDeviceConnectStatus = true
                        appStatus.ifTactileConnected = true
                    }else{
                        currentDeviceConnectStatus = false
                        appStatus.ifTactileConnected = false
                        bluetoothManager.disconnectFromDevice()
                    }
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
                    if currentDeviceConnectStatus {
                        Text("Disconnect")
                            .foregroundColor(.red)
                    } else {
                        Text("Connect")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.leading, 50.0)
                .buttonStyle(.bordered)
            }
        }
    }
}

struct PeripheralView: View {
    @EnvironmentObject var appStatus : AppInformation
    @EnvironmentObject var bluetoothManager: BluetoothManager
    var body: some View {
        VStack{
            Text("Devices Detected")
                .font(.body)
                .frame(width: 500.0, height: 50)
                .ignoresSafeArea()
                .foregroundStyle(.deviceWord)
                .background(.deviceTop)
                .padding(.top, 5)
            List(Array(bluetoothManager.discoveredPeripherals.keys), id: \.self) { uuid in
                if let peripheral = bluetoothManager.discoveredPeripherals[uuid] {
                    singleBLEPeripheral(
                        name: peripheral.name ?? "Unknown Device",
                        uuid: peripheral.identifier
                    )
                }
            }
        }
    }
}

#Preview {
    PeripheralView().environmentObject(AppInformation())
}
