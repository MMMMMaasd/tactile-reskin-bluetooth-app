//
//  readView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/27.
//

import SwiftUI
import UIKit
import CoreBluetooth
import BackgroundTasks
import UserNotifications
import Foundation
import AVFoundation

struct ReadView : View{
    @StateObject var arViewModel = ARViewModel()
    @StateObject var cameraModel = CameraViewModel()
    @EnvironmentObject var appStatus : AppInformation
    //let deviceViewModel = DeviceView()
    @ObservedObject var sharedBluetoothManager =  BluetoothManager()
    @ObservedObject private var bluetoothManager = BluetoothManager()
    @State private var isReading = false
    //private let timerInterval: TimeInterval = 0.1
    @State private var recordingTimer: Timer?
    @State private var showSheet = false
    @State var showingAlert : Bool = false
    @Environment(\.scenePhase) private var phase
    @State private var fileSetNames = ["", "", "", "", "", "", "", ""]
    @State var showingExporter = false
    @State var showingFPSInfo = false
    @State var showingSelectSheet = false
    @State var openFlash = true
    @State var exportFileName = ""
    var body : some View{
        var paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        ZStack{
            /*
            CameraView(cameraModel: cameraModel)
                .frame(width: 350.0, height: 450.0)
                .environmentObject(cameraModel)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.bottom, 250.0)
             */
            ARViewContainer(session: arViewModel.session)
                .edgesIgnoringSafeArea(.all)
                .frame(width: 400.0, height: 550.0)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.bottom, 100.0)
             
            
            
            /*
            Text("press to read data")
                .font(.title)
                .fontWeight(.medium)
                .padding(.bottom, 170.0)
                .padding(.top, 450)
             */
            Button(action: toggleRecording) {
                if isReading {
                    Image(systemName: "stop.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 80)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                    /*
                    if(appStatus.sharedBluetoothManager.ifConnected){
                        Image(systemName: "stop.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                    }
                     */
                } else {
                    Image(systemName: "dot.scope")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 80)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
               }
            }
            .padding(.top, 580.0)
            .padding(.leading, 10)
            .buttonStyle(.bordered)
            
            .alert(isPresented: $showingAlert){
                Alert(title: Text("Warning")
                    .foregroundColor(.red),
                      message: Text("Your last recorded data will all be deleted, are you sure?"),
                      primaryButton: .destructive(Text("Yes")) {
                                  showingAlert = false
                                  deleteRecordedData(url: paths, targetDirect: fileSetNames[6])
                              },
                              secondaryButton: .cancel(Text("No")) {
                                  showingAlert = false
                                  
                              }
                )
            }
            .alert(isPresented: $showingFPSInfo){
                Alert(title: Text("This Record's Frame Rate")
                    .foregroundColor(.red),
                      message: Text(arViewModel.recordFrameRate),
                      dismissButton: .default(Text("Close")) {
                            showingFPSInfo = false
                      }
                )
            }
            VStack{
                Button(action: {
                    showingExporter.toggle()
                    if(appStatus.hapticFeedbackLevel == "medium") {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    } else if (appStatus.hapticFeedbackLevel == "heavy") {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                    } else if (appStatus.hapticFeedbackLevel == "light") {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }}){
                    Text("Export to local")
                        .font(.footnote)
                        .frame(width: 80.0, height: 35.0)
                }
                .padding(.trailing, 250.0)
                .padding(.top, 590.0)
                .buttonStyle(.bordered)
                Button(action: {
                    showingAlert = true
                    deleteRecordedData(url: paths, targetDirect: fileSetNames[6])
                    if(appStatus.hapticFeedbackLevel == "medium") {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    } else if (appStatus.hapticFeedbackLevel == "heavy") {
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                    } else if (appStatus.hapticFeedbackLevel == "light") {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }}){
                    Text("Delete last record")
                        .font(.footnote)
                        .frame(width: 80.0, height: 35.0)
                        .foregroundStyle(.red)
                }
                .padding(.trailing, 250.0)
                .buttonStyle(.bordered)
                
            }
            
            VStack{
                if(isReading){
                    if(appStatus.sharedBluetoothManager.ifConnected){
                        VStack{
                            Text("tactile on")
                                .font(.footnote)
                                .foregroundColor(Color.white)
                                .frame(width: 80.0, height: 35.0)
                                .border(Color.green)
                                .background(.green)
                            /*
                            Button(action:{
                                arViewModel.switchCamera()
                            }){
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .resizable()
                                    .frame(height: 35)
                                    .frame(width: 39)
                            }
                             */
                            Button(action: toggleFlash){
                                if(openFlash){
                                    Image(systemName: "flashlight.off.fill")
                                        .resizable()
                                        .frame(height: 35)
                                        .frame(width: 20)
                                }else{
                                    Image(systemName: "flashlight.on.fill")
                                        .resizable()
                                        .frame(height: 35)
                                        .frame(width: 20)
                                }
                            }
                        }
                        .padding(.leading, 250)
                        .padding(.top, 560)
                        .buttonStyle(.bordered)
                    }else{
                        VStack{
                            Text("tactile off")
                                .font(.footnote)
                                .foregroundColor(Color.white)
                                .frame(width: 80.0, height: 35.0)
                                .border(Color.red)
                                .background(.red)
                            /*
                            Button(action:{
                                arViewModel.switchCamera()
                            }){
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .resizable()
                                    .frame(height: 35)
                                    .frame(width: 39)
                            }
                            */
                            Button(action: toggleFlash){
                                if(openFlash){
                                    Image(systemName: "flashlight.off.fill")
                                        .resizable()
                                        .frame(height: 35)
                                        .frame(width: 20)
                                }else{
                                    Image(systemName: "flashlight.on.fill")
                                        .resizable()
                                        .frame(height: 35)
                                        .frame(width: 20)
                                }
                            }
                        }
                        .padding(.leading, 250)
                        .padding(.top, 560)
                        .buttonStyle(.bordered)
                    }
                }else{
                    /*
                    Button(action:{
                        arViewModel.switchCamera()
                    }){
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .resizable()
                            .frame(height: 35)
                            .frame(width: 39)
                    }*/
                    Button(action: toggleFlash){
                        if(openFlash){
                            Image(systemName: "flashlight.off.fill")
                                .resizable()
                                .frame(height: 35)
                                .frame(width: 20)
                        }else{
                            Image(systemName: "flashlight.on.fill")
                                .resizable()
                                .frame(height: 35)
                                .frame(width: 20)
                        }
                    }
                    .padding(.leading, 250)
                    .padding(.top, 603)
                    .buttonStyle(.bordered)
                }
            }
            
        }
        .frame(width: 10.0, height: 10.0)
        
        /*
        .actionSheet(isPresented: $showingSelectSheet){
            ActionSheet(title: Text("Choose Export Option"), buttons: [
                .default(Text("Save RGB Video File (.mp4)"), action: {
                    //saveFile(targetIndex: 0)
                    exportFileName = fileSetNames[0]
                    showingExporter = true
                }),
                .default(Text("Save Depth Video File (.mp4)"), action: {
                    //saveFile(targetIndex: 1)
                    exportFileName = fileSetNames[1]
                    showingExporter = true
                }),
                .cancel()
            ])
        }
         */
        .fileExporter(isPresented: $showingExporter, document: DocumentaryFolder(files: createDocumentaryFolderFiles(paths: paths, fileSetNames: fileSetNames)), contentType: .folder, defaultFilename: fileSetNames[2]) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .ignoresSafeArea()
        
        /*
        .onAppear{
            arViewModel.startSession()
        }
         */
        /*.sheet(isPresented: $showSheet){
         List(sharedBluetoothManager.peripherals, id: \.name) { peripheral in
             singleBLEPeripheral(peripheral: peripheral, bluetoothManager: sharedBluetoothManager)
         }
     }*/
    }
    
    private func saveFile(targetIndex: Int){
        exportFileName = fileSetNames[targetIndex]
        showingSelectSheet.toggle()
    }
    func toggleRecording() {
        arViewModel.isColorMapOpened = appStatus.colorMapTrigger
        print(appStatus.colorMapTrigger)
        arViewModel.timeInterval = (1.0/appStatus.animationFPS)
        arViewModel.userFPS = appStatus.animationFPS
        if(isReading){
            showingFPSInfo = true
        }
            isReading = !isReading
            //cameraModel.isRecording = !cameraModel.isRecording
            arViewModel.isOpen = !arViewModel.isOpen
            if isReading && arViewModel.isOpen{
                fileSetNames = arViewModel.startSession()
                if(appStatus.sharedBluetoothManager.ifConnected){
                    startRecording(targetURL: fileSetNames[6], targetFile: fileSetNames[7])
                }
                //cameraModel.startRecording()
                /*
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
                let currentDateTime = dateFormatter.string(from: Date())
                fileName = "AR \(currentDateTime).mp4"
                do {
                    try createFile(fileName: fileName)
                    print("File saved successfully at \(fileName)")
                    let url = getDocumentsDirect().appendingPathComponent(fileName)
                } catch {
                    print("Error saving file: \(error)")
                    return
                }
                 */
                
                print(fileSetNames)
            } else {
                if(appStatus.sharedBluetoothManager.ifConnected){
                    stopRecording()
                }
                //cameraModel.stopRecording()
                arViewModel.pauseSession()
                
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
                    
        }
    /*
        else{
            showingAlert = true
        }
     */
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)
        else {return}
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                if openFlash == true { device.torchMode = .on // set on
                } else {
                    device.torchMode = .off // set off
                }
                device.unlockForConfiguration()
            } catch {
                print("Flash could not be used")
            }
        } else {
            print("Flash is not available")
        }
        openFlash = !openFlash
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
    }

        
    func startRecording(targetURL: String, targetFile: String) {
        isReading = true
        let timer = Timer.scheduledTimer(withTimeInterval: appStatus.tactileRecordTimeInterval, repeats: true) { _ in
            //appStatus.SharedDataString += sharedBluetoothManager.recordSingleData() ?? ""
            //appStatus.SharedDataString = sharedBluetoothManager.recordString
            appStatus.sharedBluetoothManager.recordSingleData(targetURL: targetURL, targetFile: targetFile)
        }
        recordingTimer = timer
    }
    
    func stopRecording() {
        if let timer = recordingTimer {
            timer.invalidate()
            isReading = false
        }
    }
    
    /*
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
        return paths[0]
    }
    */
    
    func createFile(fileName: String) throws {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = documentsURL[0].appendingPathComponent(fileName)
            try FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    }
    
    
    func createDocumentaryFolderFiles(paths: [URL], fileSetNames: [String]) -> [FileElement] {
        do {
            let targetpath = paths[0].appendingPathComponent(fileSetNames[6])
            let rgbFile = FileElement.videoFile(VideoFile(url: (targetpath.appendingPathComponent(fileSetNames[0]))))
            let depthFile = FileElement.videoFile(VideoFile(url: (targetpath.appendingPathComponent(fileSetNames[1]))))
            // let text1 = FileElement.textFile(TextFile(url: "path/to/example.txt"))
            let poseFile = FileElement.textFile(TextFile(url: (targetpath.appendingPathComponent(fileSetNames[5]).path)))
            let rgbImageFolder = FileElement.directory(SubLevelDirectory(url: (targetpath.appendingPathComponent(fileSetNames[3]))))
            let depthImageFolder = FileElement.directory(SubLevelDirectory(url: (targetpath.appendingPathComponent(fileSetNames[4]))))
            return [rgbFile, depthFile, poseFile, rgbImageFolder, depthImageFolder]
        } catch {
            print("Out of Index")
        }
    }
    
    func deleteRecordedData(url: [URL], targetDirect: String){
        do {
            let urlToDelete = url[0].appendingPathComponent(targetDirect)
            try FileManager.default.removeItem(at: urlToDelete)
            print("Successfully deleted file!")
        } catch {
            print("Error deleting file: \(error)")
        }
    }

    

}
    
    
    
    #Preview {
        ReadView()
            .environmentObject(AppInformation())
    }
    
