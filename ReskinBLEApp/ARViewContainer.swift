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
import CoreImage.CIFilterBuiltins



struct ARViewContainer: UIViewRepresentable {
    var session: ARSession
    typealias UIViewType = ARView
    
    func makeUIView(context: Context) -> ARView {
        // Initialize the ARView
        let arView = ARView(frame: .zero, cameraMode: .ar)
        arView.session = session
        
        // Create and configure the AR session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Loop through available video formats and select the wide-angle camera format
        for videoFormat in ARWorldTrackingConfiguration.supportedVideoFormats {
            if videoFormat.captureDeviceType == .builtInWideAngleCamera {
                print("Wide-angle camera selected: \(videoFormat)")
                configuration.videoFormat = videoFormat
                break
            } else {
                print("Unsupported video format: \(videoFormat.captureDeviceType)")
            }
        }
        
        // Set the session configuration properties
        configuration.frameSemantics = .sceneDepth
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isAutoFocusEnabled = false
        
        // Run the session with the configuration
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func destroyUIView(_ uiView: ARView, context: Context) {
            uiView.session.pause()
    }
    
    
}

class ARViewModel: ObservableObject{
    var session = ARSession()
    // 100 FPS: 0.01 (Not sure if its possible)
    // 60 FPS: 0.017 : (1.0/60.0)
    // 30 FPS: 0.033 : (1.0/30.0)
    // 25 FPS: 0.04

    public var timeInterval = (1.0/60.0)
    public var userFPS = 60.0
    public var isColorMapOpened = false
    //private var backgroundRecordingID: UUID?
    
    // Control the destination of rgb and depth video file
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    private var depthAssetWriter: AVAssetWriter?
    private var depthVideoInput: AVAssetWriterInput?
    private var depthPixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    private var coloredAssetWriter: AVAssetWriter?
    private var coloredVideoInput: AVAssetWriterInput?
    private var coloredPixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    
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
    @Published var generalURL: URL = URL(fileURLWithPath: "")
    @Published var globalPoseFileName: String = ""
    
    public var rgbImageCount: Int = 0
    public var depthImageCount: Int = 0
    public var timeCount: Double = 0.0
    public var recordTimestamp: Double = 0.0
    
    private var timer: Timer?
    private var startTime: CMTime?
    private let ciContext: CIContext
    
    private var rgbImagesToSave: [CVPixelBuffer] = []
    private var depthImagesToSave: [CVPixelBuffer] = []
    private let batchSize = 10
    private let assetWritingSemaphore = DispatchSemaphore(value: 1)
    
    private var lastFrameTimestamp: TimeInterval = 0
    @Published var recordFrameRate: String = "Unknown"
    @Published var totalFramesCounter: Double = 0
    
    
    init() {
        self.ciContext = CIContext()
    }
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
        recordTimestamp = 0.0
        totalFramesCounter = 0.0
        
        /*
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.frameSemantics = [.sceneDepth]
        session.run(configuration)
        */
        
        let saveFileNames = setupRecording()
        lastFrameTimestamp = 0
        timer = Timer.scheduledTimer(withTimeInterval: self.timeInterval, repeats: true){ [weak self] _ in
            self?.captureVideoFrame()
            self?.recordTimestamp += self?.timeInterval ?? 0.0
            self?.timeCount += self?.timeInterval ?? 0.0
            print(self?.timeCount)
        }
        isOpen = true
        return saveFileNames
    }
    
    func pauseSession(){
        //session.pause()
        timer?.invalidate()
        timer = nil
        isOpen = false
        stopRecording()
    }
    
    func setupRecording() -> Array<String>{
        // Determine all the destinated file saving URL or this recording by its start time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH_mm_ss"
        let currentDateTime = dateFormatter.string(from: Date())
        let rgbFileName = "RGB_\(currentDateTime).mp4"
        let depthFileName = "Depth_\(currentDateTime).mp4"
        // let colorMapFileName = "AR_Colored_\(currentDateTime).mp4"
        let rgbImagesDirectName = "RGB_Images_\(currentDateTime)"
        var depthImagesDirectName = "Depth_Images_\(currentDateTime)"
        if isColorMapOpened {
            depthImagesDirectName = "Depth_Colored_Images_\(currentDateTime)"
        }
        let poseFileName = "AR_Pose_\(currentDateTime).txt"
        let generalDataRecordDirectName = "\(currentDateTime)"
        let tactileDataFileName = "Tactile_\(currentDateTime).txt"
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let generalDataRecordDirectURL = url[0].appendingPathComponent(generalDataRecordDirectName)
        let rgbVideoURL = generalDataRecordDirectURL.appendingPathComponent(rgbFileName)
        let depthVideoURL = generalDataRecordDirectURL.appendingPathComponent(depthFileName)
        // let coloredVideoURL = generalDataRecordDirectURL.appendingPathComponent(colorMapFileName)
        let rgbImagesDirect = generalDataRecordDirectURL.appendingPathComponent(rgbImagesDirectName)
        let depthImagesDirect = generalDataRecordDirectURL.appendingPathComponent(depthImagesDirectName)
        let poseTextURL = generalDataRecordDirectURL.appendingPathComponent(poseFileName)
        let tactileDataFileURL = generalDataRecordDirectURL.appendingPathComponent(tactileDataFileName)
        print(rgbVideoURL)
        print(depthVideoURL)
        
        do {
            try FileManager.default.createDirectory(at: generalDataRecordDirectURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: rgbImagesDirect, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: depthImagesDirect, withIntermediateDirectories: true, attributes: nil)
            try createFile(targetURL: generalDataRecordDirectURL, fileName: poseFileName)
            try createFile(targetURL: generalDataRecordDirectURL, fileName: tactileDataFileName)
            /*
            try FileManager.default.removeItem(at: rgbVideoURL)
            try FileManager.default.removeItem(at: depthVideoURL)
             */
            // try FileManager.default.removeItem(at: coloredVideoURL)
            
        } catch {
            print("Error")
        }
        
        rgbDirect = rgbImagesDirect
        depthDirect = depthImagesDirect
        poseURL = poseTextURL
        globalPoseFileName = poseFileName
        generalURL = generalDataRecordDirectURL
        
        do {
            // Determine which video file url the assetWriter will write into
            
            // RGB
            assetWriter = try AVAssetWriter(outputURL: rgbVideoURL, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 720,
                AVVideoHeightKey: 960,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                /*
                AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 2000000,
                        AVVideoMaxKeyFrameIntervalKey: 30
                ]
                 */
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            assetWriter?.add(videoInput!)
            
            let rgbAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: 720,
                kCVPixelBufferHeightKey as String: 960
                
            ]
            pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput!, sourcePixelBufferAttributes: rgbAttributes)
            assetWriter?.startWriting()
            startTime = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
            assetWriter?.startSession(atSourceTime: startTime!)
            
            // Depth
            depthAssetWriter = try AVAssetWriter(outputURL: depthVideoURL, fileType: .mp4)
            depthVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            depthVideoInput?.expectsMediaDataInRealTime = true
            depthAssetWriter?.add(depthVideoInput!)
            
            let depthAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: 720,
                kCVPixelBufferHeightKey as String: 960
            ]
            
            depthPixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: depthVideoInput!, sourcePixelBufferAttributes: depthAttributes)
            
            depthAssetWriter?.startWriting()
            depthAssetWriter?.startSession(atSourceTime: startTime!)
            
            // Colormap
            /*
            coloredAssetWriter = try AVAssetWriter(outputURL: coloredVideoURL, fileType: .mp4)
            coloredVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            coloredVideoInput?.expectsMediaDataInRealTime = true
            coloredAssetWriter?.add(coloredVideoInput!)
            
            let coloredAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: 720,
                kCVPixelBufferHeightKey as String: 960
            ]
            
            coloredPixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: coloredVideoInput!, sourcePixelBufferAttributes: coloredAttributes)
            
            coloredAssetWriter?.startWriting()
            coloredAssetWriter?.startSession(atSourceTime: startTime!)
            */
        } catch {
            print("Failed to setup recording: \(error)")
        }
        
        return [rgbFileName, depthFileName, currentDateTime, rgbImagesDirectName, depthImagesDirectName, poseFileName, generalDataRecordDirectName, tactileDataFileName]
    }
    
    
    let imageSavingQueue = DispatchQueue(label: "imageSavingQueue")
    private var isSavingImages = false

    private func saveImage(from pixelBuffer: CVPixelBuffer, isDepth: Bool = false) {
        imageSavingQueue.async { [weak self] in
            guard let self = self else { return }

            if isDepth {
                self.depthImagesToSave.append(pixelBuffer)
                if self.depthImagesToSave.count >= self.batchSize {
                    self.saveBatch(of: self.depthImagesToSave, isDepth: true)
                }
            } else {
                self.rgbImagesToSave.append(pixelBuffer)
                if self.rgbImagesToSave.count >= self.batchSize {
                    self.saveBatch(of: self.rgbImagesToSave, isDepth: false)
                }
            }
        }
    }

    private func saveBatch(of images: [CVPixelBuffer], isDepth: Bool) {
        let directory = isDepth ? depthDirect : rgbDirect
        let totalImages = images.count

        for (index, pixelBuffer) in images.enumerated() {
            // Lock the base address
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }


            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
                print("Failed to create CGImage from CIImage.")
                continue
            }

            let uiImage = UIImage(cgImage: cgImage)
            guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
                print("Failed to convert UIImage to JPEG data.")
                continue
            }

            let fileName = isDepth ? "\(depthImageCount).jpg" : "\(rgbImageCount).jpg"
            let fileUrl = directory.appendingPathComponent(fileName)

            do {
                try jpegData.write(to: fileUrl)
                if isDepth {
                    depthImageCount += 1
                } else {
                    rgbImageCount += 1
                }
            } catch {
                print("Error saving image: \(error.localizedDescription)")
            }

            // Free memory by niling out references
            if index % 10 == 0 { // Adjust the index check for more aggressive cleanup
                self.depthImagesToSave.removeAll()
                self.rgbImagesToSave.removeAll()
            }
        }

        // Clear the array after processing
        if isDepth {
            depthImagesToSave.removeAll()
        } else {
            rgbImagesToSave.removeAll()
        }
    }

    private func flushRemainingImages() {
        // Flush any remaining images if not empty
        if !rgbImagesToSave.isEmpty {
            saveBatch(of: rgbImagesToSave, isDepth: false)
        }
        if !depthImagesToSave.isEmpty {
            saveBatch(of: depthImagesToSave, isDepth: true)
        }
    }
    
    func captureVideoFrame() {
        self.totalFramesCounter += 1
//        let targetFrameRate: TimeInterval = 1.0 / 60.0
        guard let currentFrame = session.currentFrame else {return}
        
//        let currentTimestamp = CACurrentMediaTime()
//            if currentTimestamp - lastFrameTimestamp < targetFrameRate {
//                return
//        }
//        print(currentTimestamp)
//        lastFrameTimestamp = currentTimestamp
        var imgSuccessFlag = true
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
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
        let viewPortSize = CGSize(width: 720, height: 960)
    
        //guard let rgbdPixelBuffer = createRGBDFrame(rgb: rgbPixelBuffer, depth: depthPixelBuffer) else {return}
        DispatchQueue.global(qos: .userInitiated).async {
            
            if let videoInput = self.videoInput, videoInput.isReadyForMoreMediaData == true {
                guard let outputPixelBufferPool = self.pixelBufferAdapter?.pixelBufferPool else { return }
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
                    
                    self.ciContext.render(transformedImage, to: outputBuffer, bounds: CGRect(x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height), colorSpace: CGColorSpaceCreateDeviceRGB())
                    /*
                     print(timeCount.truncatingRemainder(dividingBy: (userFPS/30)))
                     if(timeCount.truncatingRemainder(dividingBy: (userFPS/30)) == 0.0){
                     print("YEsssssssssss")
                     saveImage(from: outputBuffer, directory: rgbDirect)
                     }
                     */
                    
                    self.assetWritingSemaphore.wait()
                    defer { self.assetWritingSemaphore.signal() }
                    
                    //
//                    print("rgbPixelBuffer dimensions: \(CVPixelBufferGetWidth(rgbPixelBuffer)), \(CVPixelBufferGetHeight(rgbPixelBuffer))\n")
//                    print("transformedCiImage dimensions: \(transformedImage.extent.width), \(transformedImage.extent.height)\n")
//                    print("outputBuffer dimensions: \(CVPixelBufferGetWidth(outputBuffer)), \(CVPixelBufferGetHeight(outputBuffer))\n")
                    //print("Transform: \(transform)\n")

                    
                    if let success = self.pixelBufferAdapter?.append(outputBuffer, withPresentationTime: currentTime) {
                        if !success {
                            print("Failed to append pixel buffer. Pixel buffer adapter state: \(self.pixelBufferAdapter?.assetWriterInput.isReadyForMoreMediaData), Time: \(currentTime)")
                            print(self.assetWriter?.error);
                            imgSuccessFlag = false
                        }
                    } else {
                        print("Failed to append pixel buffer: Pixel buffer adapter is nil.")
                        imgSuccessFlag = false
                    }
                    
                    // self.saveImage(from: outputBuffer, isDepth: false)
                    
                    CVPixelBufferUnlockBaseAddress(outputBuffer, [])
                    CVPixelBufferUnlockBaseAddress(rgbPixelBuffer, .readOnly)
                }
            }
            
            
            
            if self.depthVideoInput?.isReadyForMoreMediaData == true {
                
                guard let pixelBufferPool = self.depthPixelBufferAdapter?.pixelBufferPool else {
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
                
                /*
                 let gradientFilter = CIFilter.linearGradient()
                 gradientFilter.point0 = CGPoint(x: 0, y: 0)
                 gradientFilter.point1 = CGPoint(x: depthSize.width, y: depthSize.height)
                 gradientFilter.color0 = CIColor(red: 1, green: 1, blue: 0)
                 gradientFilter.color1 = CIColor(red: 0, green: 0, blue: 1)
                 guard let gradientImage = gradientFilter.outputImage else {
                 print("Failed to get output image from gradient filter.")
                 return
                 }
                 
                 let colorMapFilter = CIFilter.colorMap()
                 colorMapFilter.inputImage = ciImageAfterFiltered
                 colorMapFilter.gradientImage = gradientImage
                 guard let ciImageAfterMapped = colorMapFilter.outputImage else {
                 print("Failed to get output image from color map filter.")
                 return
                 }
                 */
                
                var ciImageToRender = ciImageAfterFiltered
                
                if(self.isColorMapOpened){
                    let falseColorFilter = CIFilter.falseColor()
                    falseColorFilter.color0 = CIColor(red: 1, green: 1, blue: 0)
                    falseColorFilter.color1 = CIColor(red: 0, green: 0, blue: 1)
                    falseColorFilter.inputImage = ciImageAfterFiltered
                    ciImageToRender = falseColorFilter.outputImage!
                }
                
                
                let normalizeTransform = CGAffineTransform(scaleX: 1.0/depthSize.width, y: 1.0/depthSize.height)
                let flipTransform = (orientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity
                let displayTransform = currentFrame.displayTransform(for: orientation, viewportSize: viewPortSize)
                let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
                let cropRect = CGRect(
                    x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height
                )
                let transformedImage = ciImageToRender.transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)).cropped(to: cropRect)
                
                if(self.isColorMapOpened) {
                    self.ciContext.render(transformedImage, to: depthOutputBuffer, bounds: CGRect(x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height), colorSpace: CGColorSpaceCreateDeviceRGB())
                } else {
                    self.ciContext.render(transformedImage, to: depthOutputBuffer, bounds: CGRect(x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height), colorSpace: CGColorSpaceCreateDeviceGray())
                }
                
                /*
                 if(timeCount.truncatingRemainder(dividingBy: (userFPS/30)) == 0.0){
                 saveImage(from: depthOutputBuffer, directory: depthDirect, isDepth: true)
                 }
                 */
                // self.saveImage(from: depthOutputBuffer, isDepth: true)
                
//                print("depthPixelBuffer dimensions: \(CVPixelBufferGetWidth(depthPixelBuffer)), \(CVPixelBufferGetHeight(depthPixelBuffer))\n")
//                print("transformedCiImage dimensions: \(transformedImage.extent.width), \(transformedImage.extent.height)\n")
//                print("depthOutputBuffer dimensions: \(CVPixelBufferGetWidth(depthOutputBuffer)), \(CVPixelBufferGetHeight(depthOutputBuffer))\n")
                
                self.depthPixelBufferAdapter?.append(depthOutputBuffer, withPresentationTime: currentTime)
                
                CVPixelBufferUnlockBaseAddress(depthOutputBuffer, [])
                CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
            }
            
            // Processing Colormap Depth Frame
                        
        }
        if !imgSuccessFlag {return}
        print("Did not return", imgSuccessFlag)
        let cameraTransform = currentFrame.camera.transform
//        print(cameraTransform.columns.3)
        // Get the orientation matrix
        let rotationMatrx = matrix_float3x3(SIMD3<Float>(cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z),
                                            SIMD3<Float>(cameraTransform.columns.1.x, cameraTransform.columns.1.y, cameraTransform.columns.1.z),
                                            SIMD3<Float>(cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z))
//        print(cameraTransform)
//        print(rotationMatrx)
//        print(cameraTransform.columns.3)
        // Transform the orientation matrix to unit quaternion
        let quaternion = simd_quaternion(rotationMatrx)
        print(quaternion)
        // Extract the value
        let orientationY = quaternion.vector.y
        let orientationX = (quaternion.vector.x)
        let orientationW = quaternion.vector.w
        let orientationZ = (quaternion.vector.z)
        
//        let orientationY = quaternion.vector.x
//        let orientationX = -(quaternion.vector.y)
//        let orientationW = quaternion.vector.z
//        let orientationZ = -(quaternion.vector.w)
        // Use the last column's vlaue, which is the representation of translation
        let translationX = cameraTransform.columns.3.x
        let translationY = cameraTransform.columns.3.y
        let translationZ = cameraTransform.columns.3.z
        
        let currentTimer = Date()
        let dataReadTimeStamp = Int64(currentTimer.timeIntervalSince1970 * 1000)
        
        let poseWithTime = ["<\(dataReadTimeStamp)>", orientationX, orientationY, orientationZ, orientationW, translationX, translationY, translationZ] as [Any]
//        TODO: Fix appending to file
        
        if let exisitingFileData = readDataFromTextFile(targetURL: generalURL, fileName: globalPoseFileName) {
            do {
                let newAppendingPoseData = exisitingFileData + poseWithTime.description + "\n"
                try newAppendingPoseData.description.write(to: poseURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error when writing to the pose text file\n")
            }
        } else {
            print("Error when reading existed pose data file\n")
        }
        
        let currentTimestamp = CACurrentMediaTime()
        let dur = currentTimestamp - lastFrameTimestamp
//        print("Duration: ", dur, currentTimestamp)
//        if currentTimestamp - lastFrameTimestamp < targetFrameRate {
//            sleep(sleep(forTimeInterval: targetFrameRate - dur))
//        }
        //        print(currentTimestamp)
        lastFrameTimestamp = currentTimestamp
    }
    

    func stopRecording(){
        videoInput?.markAsFinished()
        assetWriter?.finishWriting {
            self.assetWriter = nil
            print("RGB Video recording finished.")
        }
        
        depthVideoInput?.markAsFinished()
        depthAssetWriter?.finishWriting {
            self.depthAssetWriter = nil
            print("Depth Video recording finished.")
        }
        
        timer?.invalidate()
        timer = nil
        self.recordFrameRate = String(Double(round(10*(self.totalFramesCounter / self.timeCount))/10))
    }
    
    /*
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
        let orientationY = quaternion.vector.x
        let orientationX = -(quaternion.vector.y)
        let orientationW = quaternion.vector.z
        let orientationZ = -(quaternion.vector.w)
        // Use the last column's vlaue, which is the representation of translation
        let translationX = cameraTransform.columns.3.x
        let translationY = cameraTransform.columns.3.y
        let translationZ = cameraTransform.columns.3.z
        
        let currentTimer = Date()
        let dataReadTimeStamp = Int64(currentTimer.timeIntervalSince1970 * 1000)
        
        let poseWithTime = ["<\(dataReadTimeStamp)>", orientationX, orientationY, orientationZ, orientationW, translationX, translationY, translationZ] as [Any]
        
        if let exisitingFileData = readDataFromTextFile(targetURL: generalURL, fileName: globalPoseFileName) {
            do {
                let newAppendingPoseData = exisitingFileData + poseWithTime.description + "\n"
                try newAppendingPoseData.description.write(to: poseURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error when writing to the pose text file\n")
            }
        } else {
            print("Error when reading existed pose data file\n")
        }
    }
    */
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
        return paths[0]
    }
    
    func createFile(targetURL: URL, fileName: String) throws {
            let fileURL = targetURL.appendingPathComponent(fileName)
            try FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    }
    
    func readDataFromTextFile(targetURL: URL, fileName : String) -> String? {
        do {
            let url = targetURL.appendingPathComponent(fileName)
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
