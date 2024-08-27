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
import CoreImage
import UIKit

struct ARViewContainer : UIViewRepresentable{
    var session: ARSession
    typealias UIViewType = ARView
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        //let arView = ARView(frame: .zero)
        arView.session = session
        configureCamera(arView: arView)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.frameSemantics = [.sceneDepth]
        configuration.isAutoFocusEnabled = false
        session.run(configuration)
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
    // 100 FPS: 0.01 (Not sure if its possible)
    // 60 FPS: 0.017 : (1.0/60.0)
    // 30 FPS: 0.033 : (1.0/30.0)
    // 25 FPS: 0.04

    public var timeInterval = (1.0/60.0)
    public var userFPS = 60.0
    //private var backgroundRecordingID: UUID?
    
    // Control the destination of rgb and depth video file
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
    
    // Control the destination of rgb images directory and depth images directory
    @Published var rgbDirect: URL = URL(fileURLWithPath: "")
    @Published var depthDirect: URL = URL(fileURLWithPath: "")
    // Control the destination of pose data text file
    @Published var poseURL: URL = URL(fileURLWithPath: "")
    @Published var globalPoseFileName: String = ""
    
    public var rgbImageCount: Int = 0
    public var depthImageCount: Int = 0
    public var timeCount: Double = 0.0
    
    private var timer: Timer?
    private var startTime: CMTime?
    
    /*
    func startCountdown(arView: ARView, completion: @escaping () -> Array<String>) {
            var countdown = 3
            let countdownLabel = UILabel()
            countdownLabel.font = UIFont.boldSystemFont(ofSize: 100)
            countdownLabel.textColor = .white
            countdownLabel.textAlignment = .center
            countdownLabel.frame = arView.bounds
            arView.addSubview(countdownLabel)
        
            func showCountdown(number: Int) {
                countdownLabel.text = "\(number)"
            }

            func removeCountdown() {
                countdownLabel.removeFromSuperview()
            }

            let countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                showCountdown(number: countdown)
                if countdown == 0 {
                    timer.invalidate()
                    removeCountdown()
                    completion() // Start the recording after countdown
                } else {
                    countdown -= 1
                }
            }
            
            countdownTimer.fire()
        }
    func startSession(arView: ARView) -> Array<String>{
          startCountdown(arView: arView) { [weak self] in
              return self?.beginRecording() ?? ["", "", "", "", "", ""]
          }
        return ["", "", "", "", "", ""]
      }
*/
    func startSession() -> Array<String>{

        rgbImageCount = 0
        depthImageCount = 0
        timeCount = 0.0
        
        /*
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.frameSemantics = [.sceneDepth]
        session.run(configuration)
        */
        
        let saveFileNames = setupRecording()
        
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true){ [weak self] _ in
            self?.updateData()
            self?.timeCount += 1.0
            print(self?.timeCount)
        }
        isOpen = true
        return saveFileNames
    }
    
    func pauseSession(){
        //session.pause()
        timer?.invalidate()
        isOpen = false
        stopRecording()
    }
    
    func setupRecording() -> Array<String>{
        // Determine all the destinated file saving URL or this recording by its start time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        let currentDateTime = dateFormatter.string(from: Date())
        let rgbFileName = "AR_RGB_\(currentDateTime).mp4"
        let depthFileName = "AR_Depth_\(currentDateTime).mp4"
        let rgbImagesDirectName = "RGB_Images_Frames \(currentDateTime)"
        let depthImagesDirectName = "Depth_Images_Frames_\(currentDateTime)"
        let poseFileName = "AR_Pose_\(currentDateTime).txt"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let rgbVideoURL = url[0].appendingPathComponent(rgbFileName)
        let depthVideoURL = url[0].appendingPathComponent(depthFileName)
        let rgbImagesDirect = url[0].appendingPathComponent(rgbImagesDirectName)
        let depthImagesDirect = url[0].appendingPathComponent(depthImagesDirectName)
        let poseTextURL = url[0].appendingPathComponent(poseFileName)
        print(rgbVideoURL)
        print(depthVideoURL)
        
        do {
            try FileManager.default.createDirectory(at: rgbImagesDirect, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: depthImagesDirect, withIntermediateDirectories: true, attributes: nil)
            try createFile(fileName: poseFileName)
            try FileManager.default.removeItem(at: rgbVideoURL)
            try FileManager.default.removeItem(at: depthVideoURL)
        } catch {
            print("Error")
        }
        
        rgbDirect = rgbImagesDirect
        depthDirect = depthImagesDirect
        poseURL = poseTextURL
        globalPoseFileName = poseFileName
        
        do {
            // Determine which video file url the assetWriter will write into
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
        
        return [rgbFileName, depthFileName, currentDateTime, rgbImagesDirectName, depthImagesDirectName, poseFileName]
    }
    
    private func saveImage(from pixelBuffer: CVPixelBuffer, directory: URL, isDepth: Bool = false){
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
            let uiImage = UIImage(cgImage: cgImage)
            
            if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                var fileName = ""
                if(isDepth){
                    fileName = "Depth_Image_\(depthImageCount).jpg"
                    depthImageCount += 1
                }else{
                    fileName = "RGB_Image_\(rgbImageCount).jpg"
                    rgbImageCount += 1
                }
                //let fileName = isDepth ? "Depth Image \(depthImageCount).jpg" : "RGB Image \(rgbImageCount).jpg"
                let fileUrl = directory.appendingPathComponent(fileName)
                print("File URL: \(fileUrl)\n")
                do {
                    try jpegData.write(to: fileUrl)
                }catch{
                    print(error.localizedDescription)
                }
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

    }
    func captureVideoFrame() {
        guard let currentFrame = session.currentFrame,
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        let orientation = windowScene.interfaceOrientation
        
        let currentTime = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
    
        let rgbPixelBuffer = currentFrame.capturedImage
        guard let depthPixelBuffer = currentFrame.sceneDepth?.depthMap else { return }
        
        /*
        if(timeCount.truncatingRemainder(dividingBy: 0.03) == 0.0){
            saveImage(from: rgbPixelBuffer, directory: rgbDirect)
            saveImage(from: depthPixelBuffer, directory: depthDirect)
        }
        */
        
        let rgbSize = CGSize(width: CVPixelBufferGetWidth(rgbPixelBuffer), height: CVPixelBufferGetHeight(rgbPixelBuffer))
        let depthSize = CGSize(width: CVPixelBufferGetWidth(depthPixelBuffer), height: CVPixelBufferGetHeight(depthPixelBuffer))
        // let viewPort = windowScene.bounds
        //let viewPortSize = windowScene.bounds.size
        let viewPortSize = CGSize(width: 720, height: 1280)
        
        //guard let rgbdPixelBuffer = createRGBDFrame(rgb: rgbPixelBuffer, depth: depthPixelBuffer) else {return}
        if let videoInput = videoInput, videoInput.isReadyForMoreMediaData == true {
            guard let outputPixelBufferPool = pixelBufferAdapter?.pixelBufferPool else { return }
            var outputPixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(nil, outputPixelBufferPool, &outputPixelBuffer)
            if status == kCVReturnSuccess, let outputBuffer = outputPixelBuffer {
                CVPixelBufferLockBaseAddress(rgbPixelBuffer, .readOnly)
                CVPixelBufferLockBaseAddress(outputBuffer, [])
                
                let ciImage = CIImage(cvPixelBuffer: rgbPixelBuffer)
                let normalizeTransform = CGAffineTransform(scaleX: 1.0/rgbSize.width, y: 1.0/rgbSize.height)
                let flipTransform = (orientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity
                let displayTransform = currentFrame.displayTransform(for: orientation, viewportSize: viewPortSize)
                let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
                let cropRect = CGRect(
                    x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height
                    )
                let transformedImage = ciImage.transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)).cropped(to: cropRect)
            
                /*
                let transform = CGAffineTransform(rotationAngle: -.pi / 2)
                    .translatedBy(x: -ciImage.extent.height, y: 0)
                 
                let transformedCiImage = ciImage.transformed(by: transform)
       
                //let scaledWidth = viewportSize.width / transformedCiImage.extent.width
                let scaleHeight = viewportSize.height / transformedCiImage.extent.height
                //let finalScale = min(scaledWidth, scaleHeight)
                let scaledTransformedCiImage = transformedCiImage.transformed(by: CGAffineTransform(scaleX: scaleHeight, y: scaleHeight))
                
                let cropRect = CGRect(
                    x: (scaledTransformedCiImage.extent.width - viewportSize.width) / 2, y: 0, width: viewportSize.width, height: viewportSize.height
                    )
            
                
                transformedCiImage = scaledTransformedCiImage.cropped(to: cropRect)
            */
               // let transformedCiImage = ciImage.transformed(by: transform)
                let context = CIContext()

                context.render(transformedImage, to: outputBuffer, bounds: CGRect(x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height), colorSpace: CGColorSpaceCreateDeviceRGB())
                
                print(timeCount.truncatingRemainder(dividingBy: (userFPS/30)))
                if(timeCount.truncatingRemainder(dividingBy: (userFPS/30)) == 0.0){
                    print("YEsssssssssss")
                    saveImage(from: outputBuffer, directory: rgbDirect)
                }
               //
                print("rgbPixelBuffer dimensions: \(CVPixelBufferGetWidth(rgbPixelBuffer)), \(CVPixelBufferGetHeight(rgbPixelBuffer))\n")
                print("transformedCiImage dimensions: \(transformedImage.extent.width), \(transformedImage.extent.height)\n")
                print("outputBuffer dimensions: \(CVPixelBufferGetWidth(outputBuffer)), \(CVPixelBufferGetHeight(outputBuffer))\n")
                //print("Transform: \(transform)\n")

                pixelBufferAdapter?.append(outputBuffer, withPresentationTime: currentTime)

                CVPixelBufferUnlockBaseAddress(outputBuffer, [])
                CVPixelBufferUnlockBaseAddress(rgbPixelBuffer, .readOnly)
            }
        }
        


        if depthVideoInput?.isReadyForMoreMediaData == true {
            
            guard let pixelBufferPool = depthPixelBufferAdapter?.pixelBufferPool else {
                print("Depth pixel buffer pool is nil.")
                return
            }
            var outputPixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &outputPixelBuffer)
            guard status == kCVReturnSuccess, let depthOutputBuffer = outputPixelBuffer else {
                print("Unable to create output pixel buffer for depth.")
                return
            }
            
            CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
            CVPixelBufferLockBaseAddress(depthOutputBuffer, [])
            
            let ciImage = CIImage(cvPixelBuffer: depthPixelBuffer)
            
            let depthFilter = CIFilter(name: "CIColorControls")!
            depthFilter.setValue(ciImage, forKey: kCIInputImageKey)
            depthFilter.setValue(2.0, forKey: kCIInputSaturationKey) // Keep saturation
            depthFilter.setValue(0.0, forKey: kCIInputBrightnessKey) // Adjust brightness
            depthFilter.setValue(3.0, forKey: kCIInputContrastKey) // Increase contrast for clarity
            
            guard let ciImageAfterFiltered = depthFilter.outputImage else {
                print("Failed to get output image from color controls filter.")
                return
            }
            
            let normalizeTransform = CGAffineTransform(scaleX: 1.0/depthSize.width, y: 1.0/depthSize.height)
            let flipTransform = (orientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity
            let displayTransform = currentFrame.displayTransform(for: orientation, viewportSize: viewPortSize)
            let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
            let cropRect = CGRect(
                x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height
            )
            let transformedImage = ciImageAfterFiltered.transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)).cropped(to: cropRect)
            
            let context = CIContext()
                context.render(transformedImage, to: depthOutputBuffer, bounds: CGRect(x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height), colorSpace: CGColorSpaceCreateDeviceGray())
            
            if(timeCount.truncatingRemainder(dividingBy: 3.0) == 0.0){
                saveImage(from: depthOutputBuffer, directory: depthDirect, isDepth: true)
            }
            
            print("depthPixelBuffer dimensions: \(CVPixelBufferGetWidth(depthPixelBuffer)), \(CVPixelBufferGetHeight(depthPixelBuffer))\n")
            print("transformedCiImage dimensions: \(transformedImage.extent.width), \(transformedImage.extent.height)\n")
            print("depthOutputBuffer dimensions: \(CVPixelBufferGetWidth(depthOutputBuffer)), \(CVPixelBufferGetHeight(depthOutputBuffer))\n")
            
            depthPixelBufferAdapter?.append(depthOutputBuffer, withPresentationTime: currentTime)
            
            CVPixelBufferUnlockBaseAddress(depthOutputBuffer, [])
            CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
        }

    }
    

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
        guard let currentFrame = session.currentFrame else {return}
        let cameraTransform = currentFrame.camera.transform
        // Get the orientation matrix
        let rotationMatrx = matrix_float3x3(SIMD3<Float>(cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z),
                                            SIMD3<Float>(cameraTransform.columns.1.x, cameraTransform.columns.1.y, cameraTransform.columns.1.z),
                                            SIMD3<Float>(cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z))
        // Transform the orientation matrix to unit quaternion
        let quaternion = simd_quaternion(rotationMatrx)
        // Extract the value
        let orientationX = quaternion.vector.x
        let orientationY = quaternion.vector.y
        let orientationZ = quaternion.vector.z
        let orientationW = quaternion.vector.w
        // Use the last column's vlaue, which is the representation of translation
        let translationX = cameraTransform.columns.3.x
        let translationY = cameraTransform.columns.3.y
        let translationZ = cameraTransform.columns.3.z
        
        let pose = [orientationX, orientationY, orientationZ, orientationW, translationX, translationY, translationZ]
        
        if let exisitingFileData = readDataFromTextFile(fileName: globalPoseFileName) {
            do {
                let newAppendingPoseData = exisitingFileData + pose.description + "\n"
                try newAppendingPoseData.description.write(to: poseURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error when writing to the pose text file\n")
            }
        } else {
            print("Error when reading existed pose data file\n")
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
    
    func switchCamera(){
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
        //print("AR session not started yet")
    }
}
