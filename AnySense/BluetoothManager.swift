//
//  BluetoothManager.swift
//  Anysense
//
//  Created by Michael on 2024/6/8.
//

import SwiftUI
import CoreBluetooth

class BluetoothManager :  NSObject, ObservableObject{
    private var centralManager: CBCentralManager?
    private var matchedPeripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    private var characteristicValues: [String] = []
    private var displayLink: CADisplayLink?
    private var BTFileHandle: FileHandle?
    @State public var recordString: String = ""
    @Published var ifConnected: Bool = false
    @Published var peripheralsNames: [String] = []
    // Dictionary that mapped CBUUID of each peripheral to scanned peripheral
    @Published var peripheralUUIDs: [CBPeripheral: [CBUUID]] = [:]
    
    private var appStatus: AppInformation
    
    init(appStatus: AppInformation){
        self.appStatus = appStatus
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
        centralManager?.scanForPeripherals(withServices: nil)
        //centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
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
        //print("Peripheral Discovered: \(peripheral)")
        //print("Peripheral name: \(String(describing: peripheral.name))")
        //print ("Advertisement Data : \(advertisementData)")
        //centralManager?.stopScan()
        
        if !self.appStatus.peripherals.contains(peripheral) && !peripheralsNames.contains(peripheral.name ?? "unnamed device"){
            self.appStatus.peripherals.append(peripheral)
            self.peripheralsNames.append(peripheral.name ?? "unnamed device")
            if let detectedUUID = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                peripheralUUIDs[peripheral] = detectedUUID
            }
        }
    }
    
    func connectToPeripheral(peripheral: CBPeripheral){
        centralManager?.connect(peripheral, options: nil)
        ifConnected = true
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
    func startRecording(targetURL: String, targetFile: String, fps: Double) {
        let url = getDocumentsDirect().appendingPathComponent(targetURL)
        let targeturl = url.appendingPathComponent(targetFile)
        do {
            self.BTFileHandle = try FileHandle(forWritingTo: targeturl)
//            defer {try? BTDataFileHandle.close()}
            try self.BTFileHandle?.seekToEnd()
            
        } catch {
            print("Error opening BTFileHandle")
        }
        
        displayLink = CADisplayLink(target: self, selector: #selector(recordSingleData))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: Float(fps), maximum: Float(fps), preferred: Float(fps))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopRecording() {
        displayLink?.invalidate()
        displayLink = nil
        do {
            try BTFileHandle?.close()
        } catch {
            print("Error closing pose file")
        }
    }
    
    @objc private func recordSingleData(link: CADisplayLink){
        if(ifConnected == true){
            guard let characteristic = rxCharacteristic else { return
            }
            characteristicPeripheralUpdate(characteristic: characteristic)
        }
    }
    
    private func characteristicPeripheralUpdate(characteristic: CBCharacteristic){
        let currentTimer = Date()
        var dataReadTimeStamp = Int64(currentTimer.timeIntervalSince1970 * 1000)
        let timeStampData = Data(bytes: &dataReadTimeStamp, count: MemoryLayout<Int64>.size)
        
        let crlfData = Data([0x0D, 0x0A])
        
        guard let characteristicValue = characteristic.value else {return}
        let writeData = timeStampData + characteristicValue + crlfData
        self.BTFileHandle!.write(writeData)
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
    
    func readDataFromTextFile(targetURL: String, targetFile: String) -> String? {
        let url = getDocumentsDirect().appendingPathComponent(targetURL)
        let targeturl = url.appendingPathComponent(targetFile)
        do {
            let contents = try String(contentsOf: targeturl, encoding: .utf8)
            return contents
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
}

