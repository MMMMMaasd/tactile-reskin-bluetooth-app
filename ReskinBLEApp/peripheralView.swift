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
        VStack{
            /*
            Text("BLE-devices")
                .fontWeight(.black)
                .foregroundColor(Color.black)
                .frame(width: 500.0, height: 130)
                .ignoresSafeArea()
                .background(.tabBackground)
                .padding(.bottom, 10)
             */
            List(appStatus.sharedBluetoothManager.peripherals, id: \.name) { peripheral in
                singleBLEPeripheral(peripheral: peripheral, bluetoothManager: appStatus.sharedBluetoothManager)
            }
            
        }
    }
}

#Preview {
    PeripheralView()
        .environmentObject(AppInformation())
}
