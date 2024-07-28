//
//  ARViewContainer.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/7/25.
//

import SwiftUI
import ARKit
import RealityKit
import Foundation

struct ARViewContainer : UIViewRepresentable{
    var session: ARSession
    typealias UIViewType = ARView
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        //let arView = ARView(frame: .zero)
        arView.session = session
        return arView
    }
    
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
    
    
}

class ARViewModel: ObservableObject{
    var session = ARSession()
    private var timeInterval = 5.0
    @Published var rgbValue: String = "N/A"
    @Published var depthValue: String = "N/A"
    @Published var position: String = "N/A"
    @Published var orientation: String = "N/A"
    @Published var isOpen : Bool = false
    
    private var timer: Timer?
    
    func startSession(savefileName : String){
        
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.frameSemantics = .sceneDepth
        session.run(configuration)
        
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true){ [weak self] _ in
            self?.updateData(saveFileName: savefileName)
        }
    }
    
    func pauseSession(){
        session.pause()
        timer?.invalidate()
    }
    
    private func updateData(saveFileName : String){
        let url = getDocumentsDirect().appendingPathComponent(saveFileName)
        guard let currentFrame = session.currentFrame else {return}
        
        let image = currentFrame.capturedImage
        let pixelBuffer = CVPixelBufferGetBaseAddress(image)
        let width = CVPixelBufferGetWidth(image)
        let height = CVPixelBufferGetHeight(image)
        
        rgbValue = "RGB: [0, 0, 0]\n"
        
        print(rgbValue)
        
        if let depthData = currentFrame.sceneDepth{
            let centerX = width/2
            let centerY = height/2
            let depthMap = depthData.depthMap
            CVPixelBufferLockBaseAddress(depthMap, [])
            
            let pixelPointer = CVPixelBufferGetBaseAddress(depthMap)
            let pixelBytesPerWor = CVPixelBufferGetBytesPerRow(depthMap)
            let depth = pixelPointer?.load(fromByteOffset: centerY * pixelBytesPerWor + centerX * MemoryLayout<Float>.stride, as: Float.self)
            let depthFormatType = CVPixelBufferGetPixelFormatType(depthMap)
            print("n\(depthFormatType)\n")
            //kCVPixelFormatType_DepthFloat32
            depthValue = "Depth: \(depth) meters \n"
            CVPixelBufferUnlockBaseAddress(depthMap, [])
        }else{
            depthValue = "Depth: N/A meters \n"
        }
        
        print(depthValue)
        
        let cameraTransform = currentFrame.camera.transform
        let NewPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        let NewOrientation = matrix_float3x3(
            SIMD3<Float>(cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z),
            SIMD3<Float>(cameraTransform.columns.1.x, cameraTransform.columns.1.y, cameraTransform.columns.1.z),
            SIMD3<Float>(cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z)
        )

        
        //position = "Position: (\(cameraTransform.columns.3.x), \(cameraTransform.columns.3.y), \(cameraTransform.columns.3.z))"
        //orientation = "Orientation: (\(cameraTransform.columns.2.x), \(cameraTransform.columns.2.y), \(cameraTransform.columns.2.z))"
        print("Position: \(position)\n")
        print("Orientation: \(orientation)\n")
        position = "Position: " + NewPosition.description + "\n"
        orientation = "Orientation: " + NewOrientation.debugDescription + "\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let currentDateTime = dateFormatter.string(from: Date())
        let arData = ""
        
        if let existingARData = readDataFromTextFile(fileName: saveFileName) {
            do {
                let arData = existingARData + "\n" + currentDateTime + "\n" + rgbValue + depthValue + position + orientation
                try arData.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Error appending to file: \(error)")
            }
        }
        
    }
    
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
        return paths[0]
    }
    
    func createFile(fileName: String) throws {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = documentsURL[0].appendingPathComponent(fileName)
            try FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    }
    
    func readDataFromTextFile(fileName : String) -> String? {
        let url = getDocumentsDirect().appendingPathComponent(fileName)
        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            return contents
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
    
    
    
}
