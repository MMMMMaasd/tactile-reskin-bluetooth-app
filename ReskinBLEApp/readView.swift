//
//  readView.swift
//  PolySense
//
//  Created by Michael on 2024/5/27.
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
    @EnvironmentObject var appStatus : AppInformation
    @State private var isReading = false
    @State private var displayLink: CADisplayLink?
    @State var showingAlert : Bool = false
    @Environment(\.scenePhase) private var phase
    @State private var fileSetNames = ["", "", "", "", "", "", "", ""]
    @State var showingExporter = false
    @State var openFlash = true
    @State var exportFileName = ""
    @State private var hasAppeared: Bool = false
    var body : some View{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        ZStack{
            ARViewContainer(session: arViewModel.session)
                .edgesIgnoringSafeArea(.all)
                .frame(width: 400.0, height: 550.0)
                // .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.bottom, 100.0)
                .opacity(appStatus.rgbdVideoStreaming == .off ? 1 : 0)
                .allowsHitTesting(appStatus.rgbdVideoStreaming == .off) // Disable interaction in streaming mode
            if(appStatus.ifTactileConnected){
                Text("tactile on")
                    .font(.footnote)
                    .foregroundColor(Color.white)
                    .frame(width: 500.0, height: 25.0)
                    .background(.green)
                    .padding(.bottom, 675)
                    .ignoresSafeArea()
            }else{
                Text("tactile off")
                    .font(.footnote)
                    .foregroundColor(Color.white)
                    .frame(width: 500.0, height: 25.0)
                    .background(.red)
                    .padding(.bottom, 675)
                    .ignoresSafeArea()
            }
            if(appStatus.gridProjectionTrigger == "5x5"){
                GeometryReader { geometry in
                        let GridWidth = geometry.size.width
                        let GridHeight = geometry.size.height

                        Path { path in
                            for col in 1..<5 {
                                let x = GridWidth * CGFloat(col) / CGFloat(5)
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: GridHeight))
                            }

                            for row in 1..<5 {
                                let y = GridHeight * CGFloat(row) / CGFloat(5)
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: GridWidth, y: y))
                            }
                        }
                        .stroke(Color.gray, lineWidth: 2)
                        .opacity(0.5)
                    }
                    .frame(width: 400.0, height: 550.0)
                    .padding(.bottom, 100)
            }else if(appStatus.gridProjectionTrigger == "3x3"){
                GeometryReader { geometry in
                        let GridWidth = geometry.size.width
                        let GridHeight = geometry.size.height

                        Path { path in
                            for col in 1..<3 {
                                let x = GridWidth * CGFloat(col) / CGFloat(3)
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: GridHeight))
                            }

                            for row in 1..<3 {
                                let y = GridHeight * CGFloat(row) / CGFloat(3)
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: GridWidth, y: y))
                            }
                        }
                        .stroke(Color.gray, lineWidth: 2)
                        .opacity(0.5)
                    }
                    .frame(width: 400.0, height: 550.0)
                    .padding(.bottom, 100)
            }

            if appStatus.rgbdVideoStreaming == .usb {
                VStack(alignment: .leading, spacing: 15) { // Reduced spacing
                    // Heading
                    Text("Streaming Mode: USB")
                        .font(.title2) // Semi-bold and slightly smaller than title
                        .fontWeight(.semibold)
                        .padding(.bottom, 5) // Slight padding after the heading

                    // Caption
                    Text("You can disable streaming in settings")
                        .font(.caption) // Small caption font
                        .foregroundColor(.secondary)

                    // Instructions
                    VStack(alignment: .leading, spacing: 8) { // Reduced spacing between instructions
                        Text("1. Connect cable to computer")
                        Text("2. Click the button below to")
                        Text("3. Run python demo-main.py on your computer")
                    }
                    .font(.body) // Regular font for instructions
                    .lineSpacing(4) // Slightly reduced line spacing for compactness

                    // Toggle Instruction
                    Text("Press Toggle to start")
                        .font(.headline) // Smaller than the main heading
                        .fontWeight(.semibold)
                        .padding(.top, 20) // Small padding before this line
                }
                .frame(width: 400.0, height: 450.0)
                .padding()
            }
            Button(action: {toggleRecording(mode:appStatus.rgbdVideoStreaming)}) {
                if isReading {
                    // Record button depends on streaming status
                    Image(systemName: "stop.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .frame(width: 100)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "record.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .frame(width: 100)
                        .multilineTextAlignment(.center)
               }
            }
//            .disabled(appStatus.rgbdVideoStreaming != .off)
            .padding(.top, 580.0)
            .padding(.leading, 2)
            
            .alert(isPresented: $showingAlert){
                // Open warning pop out informing user's delete move
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
            HStack{
                VStack{
                    // Export to local button
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
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .resizable()
                                .frame(height: 40)
                                .frame(width: 40)
                    }
                    .padding(.trailing, 8.0)
                    Text("Export")
                        .foregroundStyle(.blue)
                        .font(.caption)
                        .padding(.trailing, 8.0)
                    Text("to local")
                        .foregroundStyle(.blue)
                        .font(.caption)
                        .padding(.trailing, 8.0)
                }
                VStack{
                    // Delete last record button
                    Button(action: {
                        showingAlert = true
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
                            Image(systemName: "trash.circle.fill")
                                .resizable()
                                .frame(height: 40)
                                .frame(width: 40)
                                .foregroundStyle(.red)
                        
                    }
                    .padding(.trailing, 250.0)
                    Text("Delete")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.trailing, 250)
                    Text("last record")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.trailing, 250)
                }
            }
            .padding(.top, 600)
           
            // Flash light control button
            VStack{
                Button(action: toggleFlash){
                    if(openFlash){
                        VStack{
                            Image(systemName: "flashlight.off.circle.fill")
                                .resizable()
                                .frame(height: 40)
                                .frame(width: 40)
                            Text("Flash light off")
                                .foregroundStyle(.blue)
                                .font(.caption)
                        }
                    }else{
                        VStack{
                            Image(systemName: "flashlight.on.circle.fill")
                                .resizable()
                                .frame(height: 40)
                                .frame(width: 40)
                            Text("Flash light on")
                                .foregroundStyle(.blue)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(.leading, 240)
            .padding(.top, 582)
            
        }
        .frame(width: 10.0, height: 10.0)
        
        // File exporter, connected to export button
        .fileExporter(isPresented: $showingExporter, document: DocumentaryFolder(files: createDocumentaryFolderFiles(paths: paths, fileSetNames: fileSetNames)), contentType: .folder, defaultFilename: fileSetNames[2]) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .onChange(of: appStatus.rgbdVideoStreaming) { oldMode, newMode in
            handleStreamingModeChange(from: oldMode, to: newMode)
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                initCode()
            }
        }
        
    }
    
    private func initCode() {
        arViewModel.startSession()
        arViewModel.isColorMapOpened = appStatus.colorMapTrigger
        arViewModel.userFPS = appStatus.animationFPS
    }
    
    private func handleStreamingModeChange(from oldMode: StreamingMode, to newMode: StreamingMode) {
        if isReading {
            toggleRecording(mode: oldMode)
        }
        switch (oldMode, newMode) {
        case (_, .off):
            arViewModel.killUSBStreaming()
            print("Switched to \(newMode): ARView is active.")

        case (_, .wifi):
            print("NOT IMPLEMENTED: Switched to \(newMode): ARView removed, streaming started.")
        case (_, .usb):
            print("Switched to \(newMode): ARView is hidden.")
            arViewModel.setupUSBStreaming()
        }
    }
    
    func toggleRecording(mode: StreamingMode) {
        isReading = !isReading
        if arViewModel.isOpen {
            if mode == .off {
                if isReading {
                    fileSetNames = arViewModel.startRecording()
                    if(appStatus.sharedBluetoothManager.ifConnected){
                        startRecordingBT(targetURL: fileSetNames[6], targetFile: fileSetNames[7])
                    }
                    
                    print(fileSetNames)
                } else {
                    if(appStatus.sharedBluetoothManager.ifConnected){
                        stopRecordingBT()
                        print("This stop recording is when shared bluetooth manager is connected")
                    }
                    arViewModel.stopRecording()
                    
                }
            }
            else if mode == .usb {
                if isReading {
                    arViewModel.startUSBStreaming()
                } else {
                    arViewModel.stopUSBStreaming()
                }
            }
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

        
    func startRecordingBT(targetURL:String, targetFile: String) {
        appStatus.sharedBluetoothManager.startRecording(
            targetURL: targetURL,
            targetFile: targetFile,
            fps: appStatus.animationFPS
        )
    }

    func stopRecordingBT() {
        appStatus.sharedBluetoothManager.stopRecording()
    }
    
    
    func createDocumentaryFolderFiles(paths: [URL], fileSetNames: [String]) -> [FileElement] {
        do {
            let targetpath = paths[0].appendingPathComponent(fileSetNames[6])
            let rgbFile = FileElement.videoFile(VideoFile(url: (targetpath.appendingPathComponent(fileSetNames[0]))))
            let depthFile = FileElement.videoFile(VideoFile(url: (targetpath.appendingPathComponent(fileSetNames[1]))))
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
    
