//
//  readView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/27.
//

import SwiftUI
import UIKit
import CoreBluetooth

class BluetoothManager :  NSObject, ObservableObject{
    
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    private var matchedPeripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    
    @Published var peripheralsNames: [String] = []
    
    override init(){
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothManager: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        /*
        if(central.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
         */
        switch central.state {
                  case .poweredOff:
                      print("Is Powered Off.")
                  case .poweredOn:
                      print("Is Powered On.")
                      self.scan()
                  case .unsupported:
                      print("Is Unsupported.")
                  case .unauthorized:
                      print("Is Unauthorized.")
                  case .unknown:
                      print("Unknown")
                  case .resetting:
                      print("Resetting")
                  @unknown default:
                      print("Error")
                  }
    }
    func scan() -> Void{
        centralManager?.scanForPeripherals(withServices: nil)
        //centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }
    func disconnectFromDevice () {
        if matchedPeripheral != nil {
        centralManager?.cancelPeripheralConnection(matchedPeripheral!)
        }
     }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber){
        matchedPeripheral = peripheral
        matchedPeripheral.delegate = self
        print("Peripheral Discovered: \(peripheral)")
        print("Peripheral name: \(String(describing: peripheral.name))")
        print ("Advertisement Data : \(advertisementData)")
        centralManager?.connect(matchedPeripheral!, options: nil)
        //centralManager?.stopScan()
    
        if !peripherals.contains(peripheral) && !peripheralsNames.contains(peripheral.name ?? "unnamed device"){
            self.peripherals.append(peripheral)
            self.peripheralsNames.append(peripheral.name ?? "unnamed device")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       //matchedPeripheral.discoverServices(nil)
       matchedPeripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }
}

extension BluetoothManager: CBPeripheralDelegate{
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            print("*******************************************************")

            if ((error) != nil) {
                print("Error discovering services: \(error!.localizedDescription)")
                return
            }
            guard let services = peripheral.services else {
                return
            }
            //We need to discover the all characteristic
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            print("Discovered Services: \(services)")
        }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
           
               guard let characteristics = service.characteristics else {
              return
          }

          print("Found \(characteristics.count) characteristics.")

          for characteristic in characteristics {

            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx)  {

              rxCharacteristic = characteristic

              peripheral.setNotifyValue(true, for: rxCharacteristic!)
              peripheral.readValue(for: characteristic)

              print("RX Characteristic: \(rxCharacteristic.uuid)")
            }

            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
              
              txCharacteristic = characteristic
              
              print("TX Characteristic: \(txCharacteristic.uuid)")
            }
          }
    }
    
}

extension BluetoothManager: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral Is Powered On.")
        case .unsupported:
            print("Peripheral Is Unsupported.")
        case .unauthorized:
            print("Peripheral Is Unauthorized.")
        case .unknown:
            print("Peripheral Unknown")
        case .resetting:
            print("Peripheral Resetting")
        case .poweredOff:
            print("Peripheral Is Powered Off.")
        @unknown default:
            print("Error")
    }
  }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        var characteristicASCIIValue = NSString()

        guard characteristic == rxCharacteristic,

        let characteristicValue = characteristic.value,
        let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else { return }

        characteristicASCIIValue = ASCIIstring

        print("Value Recieved: \((characteristicASCIIValue as String))")
    }
    
    
}

struct ReadView : View{
    @EnvironmentObject var appStatus : AppInformation
    @ObservedObject private var bluetoothManager = BluetoothManager()
    var body : some View{
            ZStack{
                Text("press to read data")
                    .font(.title)
                    .fontWeight(.medium)
                    .padding(.bottom, 170.0)
                Button {
                    let message = "Read-in text" //***
                    let url = getDocumentsDirect().appendingPathComponent("data.txt")
                    do{
                        try message.write(to: url, atomically: true, encoding: .utf8)
                    }catch{
                        print(error.localizedDescription)
                    }
                    print("read-in data")
                } label: {
                  Image(systemName: "dot.scope")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .frame(width: 100)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(.bordered)
                /*
                Button(action: {
                                bluetoothManager.toggleBluetooth()
                            }) {
                            Text(bluetoothManager.isBluetoothEnabled ? "Turn Off Bluetooth" : "Turn On Bluetooth")
                               .padding()
                }
                Text("Bluetooth is \(bluetoothManager.isBluetoothEnabled ? "enabled" : "disabled")")
                            .padding()
                List(bluetoothManager.discoveredPeripherals, id: \.identifier) { peripheral in
                    Text(peripheral.name ?? "Unknown")
                    }
                 */
            }
            .ignoresSafeArea()
        List(bluetoothManager.peripheralsNames, id: \.self){ peripheral in Text(peripheral)
            
        }
    }
    
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
        return paths[0]
    }
}

#Preview {
    ReadView()
        .environmentObject(AppInformation())
}
