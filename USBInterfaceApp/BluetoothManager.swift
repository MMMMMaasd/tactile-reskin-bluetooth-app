//
//  BluetoothManager.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/6/8.
//

import SwiftUI
import CoreBluetooth

class BluetoothManager :  NSObject, ObservableObject{
    //@EnvironmentObject var appStatus : AppInformation
    //private let appStatus: AppInformation
    private var centralManager: CBCentralManager?
    public var peripherals: [CBPeripheral] = []
    private var matchedPeripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    private var characteristicValues: [String] = []
    @State public var recordString: String = ""
    public var ifConnected: Bool = false
    @Published var peripheralsNames: [String] = []
    
    override init(){
        //self.appStatus = AppInformation()
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothManager: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
        //centralManager?.scanForPeripherals(withServices: nil)
        centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }
    func disconnectFromDevice () {
        if matchedPeripheral != nil {
        centralManager?.cancelPeripheralConnection(matchedPeripheral!)
        }
        ifConnected = false
     }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber){
        matchedPeripheral = peripheral
        matchedPeripheral.delegate = self
        print("Peripheral Discovered: \(peripheral)")
        print("Peripheral name: \(String(describing: peripheral.name))")
        print ("Advertisement Data : \(advertisementData)")
        //centralManager?.stopScan()
        
        if !peripherals.contains(peripheral) && !peripheralsNames.contains(peripheral.name ?? "unnamed device"){
            self.peripherals.append(peripheral)
            self.peripheralsNames.append(peripheral.name ?? "unnamed device")
        }
    }
    
    func connectToPeripheral(peripheral: CBPeripheral){
        centralManager?.connect(peripheral, options: nil)
        ifConnected = true
        let url = getDocumentsDirect().appendingPathComponent("data.txt")
        do {
            let emptyString = ""
            try emptyString.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Error cleaning the file")
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
    /*
    func sendDataToRead() -> String? {
        return recordString
    }
    */
    
    func recordSingleData(){
        if(ifConnected == true){
            guard let characteristic = rxCharacteristic else { return
            }
            

            characteristicPeripheralUpdate(characteristic: characteristic)
        }
    }
    
    private func characteristicPeripheralUpdate(characteristic: CBCharacteristic){
        var characteristicASCIIValue = NSString()
            
        guard let characteristicValue = characteristic.value,
        let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else { return }

        
        characteristicASCIIValue = ASCIIstring
        
        if let characteristicASCIIValueStr = characteristicASCIIValue as? String {
            /*
             characteristicValues.append(characteristicASCIIValueStr)
             recordString = recordString + characteristicASCIIValueStr + "\n"*/
             let url = getDocumentsDirect().appendingPathComponent("data.txt")
             if let existingContent = readDataFromTextFile() {
             let combinedContent = existingContent + "\n" + characteristicASCIIValueStr
             do {
             try combinedContent.write(to: url, atomically: true, encoding: .utf8)
             characteristicValues.removeAll()
             } catch {
             print("Error appending to file: \(error)")
             }
             } else {
             try? characteristicASCIIValueStr.write(to: url, atomically: true, encoding: .utf8)
             characteristicValues.removeAll()
             }
            //recordString = recordString + "\n" + characteristicASCIIValueStr
            print("Value Recieved: \((characteristicASCIIValue as String))")
        }
        /*
        if characteristicValues.count > 100 {
            let url = getDocumentsDirect().appendingPathComponent("data.txt")
            do {
                let contents = try String(contentsOf: url, encoding: .utf8)
                try recordString.write(to: url, atomically: true, encoding: .utf8)
                characteristicValues.removeAll()
                recordString = ""
            } catch {
                print(error.localizedDescription)
            }
        }
         */
        //print("Value Recieved: \((characteristicASCIIValue as String))")
}

    func writeOutgoingValue(data: String){
          
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        
        if let bluefruitPeripheral = matchedPeripheral {
              
          if let txCharacteristic = txCharacteristic {
                  
            bluefruitPeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
              }
          }
      }
    
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
        return paths[0]
    }
    
    func readDataFromTextFile() -> String? {
        let url = getDocumentsDirect().appendingPathComponent("data.txt")
        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            return contents
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
}

