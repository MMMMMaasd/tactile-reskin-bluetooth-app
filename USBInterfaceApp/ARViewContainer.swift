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
import AVFoundation
import CoreMedia

struct ARViewContainer : UIViewRepresentable{
    var session: ARSession
    typealias UIViewType = ARView
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        //let arView = ARView(frame: .zero)
        arView.session = session
        configureCamera(arView: arView)
        return arView
    }
    
    func configureCamera(arView: ARView) {
            guard let camera = arView.session.configuration as? ARWorldTrackingConfiguration else { return }
            camera.videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: {
                $0.imageResolution.width == 720 && $0.imageResolution.height == 1280
            }) ?? ARWorldTrackingConfiguration.supportedVideoFormats[0]
            camera.frameSemantics = .sceneDepth
            arView.session.run(camera)
    }
    
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    
}

class ARViewModel: ObservableObject{
    var session = ARSession()
    private var timeInterval = 0.01
    //private var backgroundRecordingID: UUID?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    private var depthAssetWriter: AVAssetWriter?
    private var depthVideoInput: AVAssetWriterInput?
    private var depthPixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    
    @Published var rgbValue: String = "N/A"
    @Published var depthValue: String = "N/A"
    @Published var position: String = "N/A"
    @Published var orientation: String = "N/A"
    @Published var isOpen : Bool = false
    
    private var timer: Timer?
    private var startTime: CMTime?
    
    func startSession() -> Array<String>{
        
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.frameSemantics = [.sceneDepth]
        session.run(configuration)
        
        let saveFileNames = setupRecording()
        
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true){ [weak self] _ in
            self?.updateData()
        }
        isOpen = true
        return saveFileNames
    }
    
    func pauseSession(){
        session.pause()
        timer?.invalidate()
        isOpen = false
        stopRecording()
    }
    
    func setupRecording() -> Array<String>{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        let currentDateTime = dateFormatter.string(from: Date())
        let rgbFileName = "AR RGB \(currentDateTime).mp4"
        let depthFileName = "AR Depth \(currentDateTime).mp4"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let rgbVideoURL = url[0].appendingPathComponent(rgbFileName)
        let depthVideoURL = url[0].appendingPathComponent(depthFileName)
        
        print(rgbVideoURL)
        print(depthVideoURL)
        
        do {
            try FileManager.default.removeItem(at: rgbVideoURL)
            try FileManager.default.removeItem(at: depthVideoURL)
        } catch {
            print("Error")
        }
        
        do {
            assetWriter = try AVAssetWriter(outputURL: rgbVideoURL, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 720,
                AVVideoHeightKey: 1280,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            assetWriter?.add(videoInput!)
            
            let rgbAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: 720,
                kCVPixelBufferHeightKey as String: 1280
                
            ]
            pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput!, sourcePixelBufferAttributes: rgbAttributes)
            assetWriter?.startWriting()
            startTime = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
            assetWriter?.startSession(atSourceTime: startTime!)
            
            depthAssetWriter = try AVAssetWriter(outputURL: depthVideoURL, fileType: .mp4)
            depthVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            depthVideoInput?.expectsMediaDataInRealTime = true
            depthAssetWriter?.add(depthVideoInput!)
            
            let depthAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: 720,
                kCVPixelBufferHeightKey as String: 1280
            ]
            
            depthPixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: depthVideoInput!, sourcePixelBufferAttributes: depthAttributes)
            
            depthAssetWriter?.startWriting()
            depthAssetWriter?.startSession(atSourceTime: startTime!)
        } catch {
            print("Failed to setup recording: \(error)")
        }
        
        return [rgbFileName, depthFileName]
    }
    
    /*
    func captureVideoFrame(){
        guard let currentFrame = session.currentFrame else {return}
        let currentTime = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
        
        if videoInput?.isReadyForMoreMediaData == true {
            let pixelBuffer = currentFrame.capturedImage
            
            pixelBufferAdapter?.append(pixelBuffer, withPresentationTime: currentTime)
        }
        
    }
    */
    func captureVideoFrame() {
        guard let currentFrame = session.currentFrame,
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        let orientation = windowScene.interfaceOrientation
        let viewportSize = CGSize(width: 720, height: 1280)
        
        let currentTime = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
        
        let rgbPixelBuffer = currentFrame.capturedImage
        
        //guard let rgbdPixelBuffer = createRGBDFrame(rgb: rgbPixelBuffer, depth: depthPixelBuffer) else {return}
        /*
        if videoInput?.isReadyForMoreMediaData == true{
            pixelBufferAdapter?.append(rgbdPixelBuffer, withPresentationTime: currentTime)
        }
         */
        if let videoInput = videoInput, videoInput.isReadyForMoreMediaData == true {
            guard let outputPixelBufferPool = pixelBufferAdapter?.pixelBufferPool else { return }
            var outputPixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(nil, outputPixelBufferPool, &outputPixelBuffer)
            if status == kCVReturnSuccess, let outputBuffer = outputPixelBuffer {
                CVPixelBufferLockBaseAddress(rgbPixelBuffer, .readOnly)
                CVPixelBufferLockBaseAddress(outputBuffer, [])

                //let orient = UIApplication.shared.statusBarOrientation
                //let viewportSize = .bounds.size
                
                let ciImage = CIImage(cvPixelBuffer: rgbPixelBuffer)
                //let transform = currentFrame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
            
                let transform = CGAffineTransform(rotationAngle: -.pi / 2)
                        .translatedBy(x: -ciImage.extent.height, y: 0)
                let transformedCiImage = ciImage.transformed(by: transform)
            
                
               // let transformedCiImage = ciImage.transformed(by: transform)
                let context = CIContext()

                // Render the transformed image to the output buffer without scaling
                context.render(transformedCiImage, to: outputBuffer, bounds: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(outputBuffer), height: CVPixelBufferGetHeight(outputBuffer)), colorSpace: CGColorSpaceCreateDeviceRGB())
               //
                print("rgbPixelBuffer dimensions: \(CVPixelBufferGetWidth(rgbPixelBuffer)), \(CVPixelBufferGetHeight(rgbPixelBuffer))\n")
                print("outputBuffer dimensions: \(CVPixelBufferGetWidth(outputBuffer)), \(CVPixelBufferGetHeight(outputBuffer))\n")
                print("Transform: \(transform)\n")

                pixelBufferAdapter?.append(outputBuffer, withPresentationTime: currentTime)

                CVPixelBufferUnlockBaseAddress(outputBuffer, [])
                CVPixelBufferUnlockBaseAddress(rgbPixelBuffer, .readOnly)
            }
        }

        if depthVideoInput?.isReadyForMoreMediaData == true {
            guard let depthPixelBuffer = currentFrame.sceneDepth?.depthMap else { return }
            
            // Safely unwrap the pixel buffer pool
            guard let pixelBufferPool = depthPixelBufferAdapter?.pixelBufferPool else {
                print("Depth pixel buffer pool is nil.")
                return
            }
            
            // Create a new pixel buffer for depth that is the correct size
            var outputBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &outputBuffer)
            guard status == kCVReturnSuccess, let depthOutputBuffer = outputBuffer else {
                print("Unable to create output pixel buffer for depth.")
                return
            }
            
            CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
            CVPixelBufferLockBaseAddress(depthOutputBuffer, [])
            
            // Prepare Core Image context
            let ciImage = CIImage(cvPixelBuffer: depthPixelBuffer).transformed(by: CGAffineTransform(scaleX: CGFloat(CVPixelBufferGetWidth(depthOutputBuffer)) / CGFloat(CVPixelBufferGetWidth(depthPixelBuffer)), y: CGFloat(CVPixelBufferGetHeight(depthOutputBuffer)) / CGFloat(CVPixelBufferGetHeight(depthPixelBuffer))))
            
            let depthFilter = CIFilter(name: "CIColorControls")!
            depthFilter.setValue(ciImage, forKey: kCIInputImageKey)
            depthFilter.setValue(2.0, forKey: kCIInputSaturationKey) // Keep saturation
            depthFilter.setValue(0.0, forKey: kCIInputBrightnessKey) // Adjust brightness
            depthFilter.setValue(3.0, forKey: kCIInputContrastKey) // Increase contrast for clarity
            
            guard let ciImageAfterFiltered = depthFilter.outputImage else {
                print("Failed to get output image from color controls filter.")
                return
            }
            
            // Render depth image directly to output buffer with the full size
            let context = CIContext()
            context.render(ciImageAfterFiltered, to: depthOutputBuffer, bounds: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(depthOutputBuffer), height: CVPixelBufferGetHeight(depthOutputBuffer)), colorSpace: CGColorSpaceCreateDeviceGray())
            
            // Append the depth video frame
            depthPixelBufferAdapter?.append(depthOutputBuffer, withPresentationTime: currentTime)
            
            CVPixelBufferUnlockBaseAddress(depthOutputBuffer, [])
            CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
        }

    }
    
    /*
    private func createRGBDFrame(rgb: CVPixelBuffer, depth: CVPixelBuffer) -> CVPixelBuffer? {
        guard CVPixelBufferLockBaseAddress(rgb, .readOnly) == kCVReturnSuccess else {
            print("Failed to lock base address for RGB buffer")
            return nil
        }
        guard CVPixelBufferLockBaseAddress(depth, .readOnly) == kCVReturnSuccess else {
            print("Failed to lock base address for depth buffer")
            CVPixelBufferUnlockBaseAddress(rgb, .readOnly)
            return nil
        }
        
        let rgbWidth = CVPixelBufferGetWidth(rgb)
        let rgbHeight = CVPixelBufferGetHeight(rgb)
        
        let depthWidth = CVPixelBufferGetWidth(depth)
        let depthHeight = CVPixelBufferGetHeight(depth)
        
        guard depthWidth > 0, depthHeight > 0 else {
            print("Depth buffer dimensions are invalid")
            CVPixelBufferUnlockBaseAddress(rgb, .readOnly)
            CVPixelBufferUnlockBaseAddress(depth, .readOnly)
            return nil
        }
        
        let rgbdWidth = rgbWidth * 2
        let rgbdHeight = rgbHeight
        
        var rgbdPixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: rgbdWidth,
            kCVPixelBufferHeightKey as String: rgbdHeight
        ] as CFDictionary
        
        guard CVPixelBufferCreate(kCFAllocatorDefault, rgbdWidth, rgbdHeight, kCMPixelFormat_32BGRA, attributes, &rgbdPixelBuffer) == kCVReturnSuccess,
              let rgbdBuffer = rgbdPixelBuffer,
              CVPixelBufferLockBaseAddress(rgbdBuffer, []) == kCVReturnSuccess else {
            print("Failed to create or lock base address for RGBD buffer")
            CVPixelBufferUnlockBaseAddress(rgb, .readOnly)
            CVPixelBufferUnlockBaseAddress(depth, .readOnly)
            return nil
        }
        
        let rgbBaseAddress = CVPixelBufferGetBaseAddress(rgb)!
        let depthBaseAddress = CVPixelBufferGetBaseAddress(depth)!
        let rgbdBaseAddress = CVPixelBufferGetBaseAddress(rgbdBuffer)!
        
        let bytesPerRowRGB = CVPixelBufferGetBytesPerRow(rgb)
        let bytesPerRowDepth = CVPixelBufferGetBytesPerRow(depth)
        let bytesPerRowRGBD = CVPixelBufferGetBytesPerRow(rgbdBuffer)
        
        // Write RGB data to the left half
        for y in 0..<rgbHeight {
            let dest = rgbdBaseAddress.advanced(by: y * bytesPerRowRGBD)
            let src = rgbBaseAddress.advanced(by: y * bytesPerRowRGB)
            memcpy(dest, src, bytesPerRowRGB)
        }
        
        // Scale depth data and write it to the right half
        for y in 0..<rgbdHeight {
            let depthY = min((y * depthHeight) / rgbHeight, depthHeight - 1)
            let depthRowBase = depthBaseAddress.advanced(by: depthY * bytesPerRowDepth)
            for x in 0..<rgbWidth {
                let depthX = min((x * depthWidth) / rgbWidth, depthWidth - 1)
                let depthPixelPointer = depthRowBase.advanced(by: depthX * MemoryLayout<Float>.size)
                let rgbdPixelPointer = rgbdBaseAddress.advanced(by: (y * bytesPerRowRGBD) + ((x + rgbWidth) * 4)) // 4 bytes for BGRA
                
                let depthValue = depthPixelPointer.load(fromByteOffset: 0, as: Float.self)
                let isDepthValueValid = !depthValue.isNaN && !depthValue.isInfinite
                
                // Map depth to grayscale
                let normalizedDepthValue = isDepthValueValid ? min(max(depthValue, 0.0), 5.0) : 0.0
                let grayValue = UInt8(255 * (1 - (normalizedDepthValue / 5.0)))
                
                rgbdPixelPointer.storeBytes(of: grayValue, as: UInt8.self) // Blue
                rgbdPixelPointer.advanced(by: 1).storeBytes(of: grayValue, as: UInt8.self) // Green
                rgbdPixelPointer.advanced(by: 2).storeBytes(of: grayValue, as: UInt8.self) // Red
                rgbdPixelPointer.advanced(by: 3).storeBytes(of: 255, as: UInt8.self) // Alpha
            }
        }
        
        CVPixelBufferUnlockBaseAddress(rgb, .readOnly)
        CVPixelBufferUnlockBaseAddress(depth, .readOnly)
        CVPixelBufferUnlockBaseAddress(rgbdBuffer, [])
        
        return rgbdPixelBuffer
    }

*/

    func stopRecording(){
        videoInput?.markAsFinished()
        assetWriter?.finishWriting {
            print("RGB Video recording finished.")
        }
        
        depthVideoInput?.markAsFinished()
        depthAssetWriter?.finishWriting {
            print("Depth Video recording finished.")
        }
    }
    
    private func updateData(){
        captureVideoFrame()
        /*
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
         */
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
    
    func switchCamera(){
        if isOpen {
            guard var currenConfig = session.configuration else{
                fatalError("Unexpectedly failed to get the configuration.")
            }
            
            switch currenConfig {
                    case is ARWorldTrackingConfiguration:
                        currenConfig = ARFaceTrackingConfiguration()
                    case is ARFaceTrackingConfiguration:
                        currenConfig = ARWorldTrackingConfiguration()
                    default:
                        currenConfig = ARWorldTrackingConfiguration()
                    }
                    
            session.run(currenConfig)
        }
        print("AR session not started yet")
    }
}
