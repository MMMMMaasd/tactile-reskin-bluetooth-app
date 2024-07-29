//
//  peripheralView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/7/29.
//

import SwiftUI
import CoreBluetooth

struct singleBLEPeripheral: View {
    let appInfo = AppInformation()
    @ObservedObject private var bluetoothManager: BluetoothManager
    @EnvironmentObject var appStatus: AppInformation
    @State private var isConnected = false
    @State private var connectAlert : Bool = false
    let peripheral: CBPeripheral
    
    init(peripheral: CBPeripheral, bluetoothManager: BluetoothManager) {
        self.peripheral = peripheral
        self.bluetoothManager = bluetoothManager

    }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
                Text(peripheral.name ?? "unnamed device")
                    .font(.headline)
                Button(action: {
                    if !isConnected{
                        bluetoothManager.connectToPeripheral(peripheral: peripheral)
                        isConnected = true
                    }else{
                        bluetoothManager.disconnectFromDevice()
                        isConnected = false
                    }
                    /*
                    if !isConnected{
                        bluetoothManager.connectToPeripheral(peripheral: peripheral)
                        isConnected = true
                    }else {
                        bluetoothManager.disconnectFromDevice()
                        isConnected = false
                    }
                     */
                }) {
                    if isConnected {
                        Text("Disconnect")
                            .foregroundColor(.red)
                    } else {
                        Text("Connect")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.leading, 50.0)
                .buttonStyle(.bordered)
            /*
                .alert(isPresented: $connectAlert){
                    Alert(
                        
                    )
                }
             */
            }
            //.onAppear(perform: loadDeviceConnectionStatus)
        }
}

struct PeripheralView: View {
    @EnvironmentObject var appStatus : AppInformation
    var body: some View {
        List(appStatus.sharedBluetoothManager.peripherals, id: \.name) { peripheral in
            singleBLEPeripheral(peripheral: peripheral, bluetoothManager: appStatus.sharedBluetoothManager)
        }
    }
}

#Preview {
    PeripheralView()
        .environmentObject(AppInformation())
}
