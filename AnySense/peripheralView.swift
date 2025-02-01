//
//  peripheralView.swift
//  Anysense
//
//  Created by Michael on 2024/7/29.
//

import SwiftUI
import CoreBluetooth

struct singleBLEPeripheral: View {
    @ObservedObject private var bluetoothManager: BluetoothManager
    @EnvironmentObject var appStatus: AppInformation
    @State private var currentDeviceConnectStatus = false
    @State private var connectAlert : Bool = false
    @State private var serviceUUID : [CBUUID]
    let peripheral: CBPeripheral
    
    init(peripheral: CBPeripheral, bluetoothManager: BluetoothManager) {
        self.peripheral = peripheral
        self.bluetoothManager = bluetoothManager
        self.serviceUUID = []

    }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
                Text(peripheral.name ?? "unnamed device")
                    .font(.headline)
                Spacer()
            if(!appStatus.ifTactileConnected || currentDeviceConnectStatus){
                Button(action: {
                    if !currentDeviceConnectStatus{
                        bluetoothManager.connectToPeripheral(peripheral: peripheral)
                        currentDeviceConnectStatus = true
                        if(appStatus.sharedBluetoothManager.peripheralUUIDs[peripheral] == [CBUUIDs.BLEService_UUID]){
                            appStatus.ifTactileConnected = true
                        }
                    }else{
                        currentDeviceConnectStatus = false
                        if(appStatus.sharedBluetoothManager.peripheralUUIDs[peripheral] == [CBUUIDs.BLEService_UUID]){
                            appStatus.ifTactileConnected = false
                        }
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
    var body: some View {
        VStack{
            Text("Devices Detected")
                .font(.body)
                .frame(width: 500.0, height: 50)
                .ignoresSafeArea()
                .foregroundStyle(.deviceWord)
                .background(.deviceTop)
                .padding(.top, 5)
            List(appStatus.peripherals, id: \.name) { peripheral in
                singleBLEPeripheral(peripheral: peripheral, bluetoothManager: appStatus.sharedBluetoothManager)
            }
            
        }
    }
}

#Preview {
    PeripheralView()
        .environmentObject(AppInformation())
}
