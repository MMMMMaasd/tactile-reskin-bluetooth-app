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
    //@EnvironmentObject var appStatus : AppInformation
    private let appStatus: AppInformation
    private var centralManager: CBCentralManager?
    public var peripherals: [CBPeripheral] = []
    private var matchedPeripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    private var characteristicValues: [String] = []
    private var recordString: String = ""
    public var ifConnected: Bool = false
    @Published var peripheralsNames: [String] = []
    
    /*
    init?(appStatus: AppInformation){
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        self.appStatus = appStatus
    }
     */
    override init(){
        self.appStatus = AppInformation()
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
    
    func sendDataToRead() -> String? {
        return recordString
    }
    
    
    func startRecordData() {
        if(ifConnected == true){
            guard let characteristic = rxCharacteristic else { return
            }
            

            characteristicPeripheralUpdate(characteristic: characteristic)
        }
    }
    
    private func characteristicPeripheralUpdate(characteristic: CBCharacteristic) {
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
        print("Value Recieved: \((characteristicASCIIValue as String))")
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
struct ReadView : View{
    @EnvironmentObject var appStatus : AppInformation
    //let deviceViewModel = DeviceView()
    @ObservedObject var sharedBluetoothManager =  BluetoothManager()
    @ObservedObject private var bluetoothManager = BluetoothManager()
    @State private var isReading = false
    private let timerInterval: TimeInterval = 0.1
    @State private var recordingTimer: Timer?
    @State private var showSheet = false
    @State var showingAlert : Bool = false
    var body : some View{
        ZStack{
            Text("press to read data")
                .font(.title)
                .fontWeight(.medium)
                .padding(.bottom, 170.0)
            Button(action: toggleRecording) {
                if isReading {
                    if(sharedBluetoothManager.ifConnected){
                        Image(systemName: "stop.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                            .frame(width: 100)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Image(systemName: "dot.scope")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .frame(width: 100)
                        .multilineTextAlignment(.center)
               }
            }
            .buttonStyle(.bordered)
            .alert(isPresented: $showingAlert){
                Alert(title: Text("Warning")
                    .foregroundColor(.red),
                      message: Text("No available bluetooth device connected, you need to connect to a device first!"),
                      dismissButton: .destructive(Text("Ok")){
                    showingAlert = false
                    }
                )
            }
            /*
            Button{
                showSheet.toggle()
            } label:{
                Text("show ble device")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
            }
             */
            //.onAppear(perform: startRecordingIfNotAlready)
            //.onDisappear(perform: stopRecording)
            /*
             Button(action: toggleRecording) {
             if isReading {
             Image(systemName: "stop.circle")
             .resizable()
             .aspectRatio(contentMode: .fit)
             .frame(height: 100)
             .frame(width: 100)
             .multilineTextAlignment(.center)
             } else {
             Image(systemName: "dot.scope")
             .resizable()
             .aspectRatio(contentMode: .fit)
             .frame(height: 100)
             .frame(width: 100)
             .multilineTextAlignment(.center)
             }
             }
             
             .buttonStyle(.bordered)
             .onTapGesture {
             isReading = !isReading
             }
             */
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
        /*.sheet(isPresented: $showSheet){
         List(sharedBluetoothManager.peripherals, id: \.name) { peripheral in
             singleBLEPeripheral(peripheral: peripheral, bluetoothManager: sharedBluetoothManager)
         }
     }*/
        .ignoresSafeArea()
        List(sharedBluetoothManager.peripherals, id: \.name) { peripheral in
            singleBLEPeripheral(peripheral: peripheral, bluetoothManager: sharedBluetoothManager)
        }
    }
    func toggleRecording() {
        if(sharedBluetoothManager.ifConnected){
            isReading = !isReading
            if isReading {
                startRecording()
            } else {
                stopRecording()
            }
        }else{
            showingAlert = true
        }
    }
    
    func startRecording() {
        isReading = true
        let timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            sharedBluetoothManager.startRecordData()
        }
        recordingTimer = timer
    }
    
    func stopRecording() {
        if let timer = recordingTimer {
            timer.invalidate()
            isReading = false
        }
    }
    
    func startRecordingIfNotAlready() {
               if isReading {
                   return
               }
               startRecording()
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
    
