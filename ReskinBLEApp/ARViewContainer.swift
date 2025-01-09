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
        configuration.planeDetection = []
        configuration.environmentTexturing = .none  // No environment texturing
        configuration.sceneReconstruction = []  // No scene reconstruction
        configuration.isAutoFocusEnabled = false
        
        // Run the session with the configuration
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arView.environment.sceneUnderstanding.options = [] // No extra scene understanding
        
        
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

    public var userFPS: Double?
    public var isColorMapOpened = false
    //private var backgroundRecordingID: UUID?
    private var orientation: UIInterfaceOrientation = .portrait
    
    // Control the destination of rgb and depth video file
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    private var depthAssetWriter: AVAssetWriter?
    private var depthVideoInput: AVAssetWriterInput?
    private var depthPixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
//    private var coloredAssetWriter: AVAssetWriter?
//    private var coloredVideoInput: AVAssetWriterInput?
//    private var coloredPixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    private var viewPortSize = CGSize(width: 720, height: 960)
    private var combinedRGBTransform: CGAffineTransform?
    private var combinedDepthTransform: CGAffineTransform?
    
    private var poseFileHandle: FileHandle?
    
//    @Published var rgbValue: String = "N/A"
//    @Published var depthValue: String = "N/A"
//    @Published var position: String = "N/A"
//    @Published var orientation: String = "N/A"
    @Published var isOpen : Bool = false
    
    // Control the destination of rgb images directory and depth images directory
    private var rgbDirect: URL = URL(fileURLWithPath: "")
    private var depthDirect: URL = URL(fileURLWithPath: "")
    // Control the destination of pose data text file
    private var poseURL: URL = URL(fileURLWithPath: "")
    private var generalURL: URL = URL(fileURLWithPath: "")
    private var globalPoseFileName: String = ""
    
//    @Published var rgbDirect: URL = URL(fileURLWithPath: "")
//    @Published var depthDirect: URL = URL(fileURLWithPath: "")
//    // Control the destination of pose data text file
//    @Published var poseURL: URL = URL(fileURLWithPath: "")
//    @Published var generalURL: URL = URL(fileURLWithPath: "")
//    @Published var globalPoseFileName: String = ""
    
    public var rgbImageCount: Int = 0
    public var depthImageCount: Int = 0
    public var timeCount: Double = 0.0
    public var recordTimestamp: Double = 0.0
    
    private var timer: Timer?
    private var startTime: CMTime?
    private let ciContext: CIContext
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    
    private var rgbImagesToSave: [CVPixelBuffer] = []
    private var depthImagesToSave: [CVPixelBuffer] = []
    private let batchSize = 10
    private let assetWritingSemaphore = DispatchSemaphore(value: 1)
    
    private var lastFrameTimestamp: TimeInterval = 0
    
    init() {
        self.ciContext = CIContext()
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if let currentFrame = self.session.currentFrame {
                timer.invalidate() // Stop the timer once the frame is available
                let rgbPixelBuffer = currentFrame.capturedImage
                
                let rgbSize = CGSize(width: CVPixelBufferGetWidth(rgbPixelBuffer), height: CVPixelBufferGetHeight(rgbPixelBuffer))
                var normalizeTransform = CGAffineTransform(scaleX: 1.0/rgbSize.width, y: 1.0/rgbSize.height)
                let flipTransform = (self.orientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity
                let displayTransform = currentFrame.displayTransform(for: self.orientation, viewportSize: self.viewPortSize)
                let toViewPortTransform = CGAffineTransform(scaleX: self.viewPortSize.width, y: self.viewPortSize.height)

                self.combinedRGBTransform = normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)
                
                guard let depthPixelBuffer = currentFrame.sceneDepth?.depthMap else { return }
                let depthSize = CGSize(width: CVPixelBufferGetWidth(depthPixelBuffer), height: CVPixelBufferGetHeight(depthPixelBuffer))
                normalizeTransform = CGAffineTransform(scaleX: 1.0/depthSize.width, y: 1.0/depthSize.height)
                
                self.combinedDepthTransform = normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)
            }
        }
        print("Finished setting up transforms")
    }

    func startSession() -> Array<String>{

        rgbImageCount = 0
        depthImageCount = 0
        timeCount = 0.0
        recordTimestamp = 0.0
        
        /*
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.frameSemantics = [.sceneDepth]
        session.run(configuration)
        */
        
        let saveFileNames = setupRecording()
        lastFrameTimestamp = 0
//        var last_ts = 0.0
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: Float(self.userFPS!), maximum: Float(self.userFPS!), preferred: Float(self.userFPS!))
        displayLink?.add(to: .main, forMode: .common)
        
        isOpen = true
        return saveFileNames
    }
    
    @objc private func updateFrame(link: CADisplayLink) {
        guard lastTimestamp > 0 else {
            // Initialize timestamp on the first call
            lastTimestamp = link.timestamp
            return
        }
        
//        let deltaTime = link.timestamp - lastTimestamp
//        lastTimestamp = link.timestamp

        captureVideoFrame()
        timeCount += 1.0
    }
    
    func pauseSession(){
        //session.pause()
//        timer?.invalidate()
//        timer = nil
        displayLink?.invalidate()
        displayLink = nil
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
            
            let depthAttributes: [String: Any]
            if isColorMapOpened {
                depthAttributes = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: 720,
                    kCVPixelBufferHeightKey as String: 960
                ]
            } else {
                depthAttributes = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_OneComponent8,
                    kCVPixelBufferWidthKey as String: 720,
                    kCVPixelBufferHeightKey as String: 960
                ]
            }
            
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
            
            poseFileHandle = try FileHandle(forWritingTo: poseTextURL)
            try poseFileHandle?.seekToEnd()
        } catch {
            print("Failed to setup recording: \(error)")
        }
        
        
        
        return [rgbFileName, depthFileName, currentDateTime, rgbImagesDirectName, depthImagesDirectName, poseFileName, generalDataRecordDirectName, tactileDataFileName]
    }
    
    func captureVideoFrame() {
//        let preRecvFrameTimestamp = CACurrentMediaTime()
//        print("Time at start: ", preRecvFrameTimestamp - lastFrameTimestamp)
        guard let currentFrame = session.currentFrame else {return}

        var imgSuccessFlag = true

        let currentTime = CMTimeMake(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000)
    
        let rgbPixelBuffer = currentFrame.capturedImage
        guard let depthPixelBuffer = currentFrame.sceneDepth?.depthMap else { return }
        let cropRect = CGRect(
            x: 0, y: 0, width: self.viewPortSize.width, height: self.viewPortSize.height
        )
        
    
        //guard let rgbdPixelBuffer = createRGBDFrame(rgb: rgbPixelBuffer, depth: depthPixelBuffer) else {return}
//        let preImgTimestamp = CACurrentMediaTime()
//        print("Post settings duration: ", preImgTimestamp - postSceneTimestamp)
        DispatchQueue.global(qos: .userInitiated).async {
            
            if let videoInput = self.videoInput, videoInput.isReadyForMoreMediaData == true {
                guard let outputPixelBufferPool = self.pixelBufferAdapter?.pixelBufferPool else { return }
                var outputPixelBuffer: CVPixelBuffer?
                let status = CVPixelBufferPoolCreatePixelBuffer(nil, outputPixelBufferPool, &outputPixelBuffer)
                if status == kCVReturnSuccess, let outputBuffer = outputPixelBuffer {
                    CVPixelBufferLockBaseAddress(rgbPixelBuffer, .readOnly)
                    CVPixelBufferLockBaseAddress(outputBuffer, [])
                    
                    let ciImage = CIImage(cvPixelBuffer: rgbPixelBuffer)
//                    let normalizeTransform = CGAffineTransform(scaleX: 1.0/rgbSize.width, y: 1.0/rgbSize.height)
//                    let flipTransform = CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)
//                    let displayTransform = currentFrame.displayTransform(for: self.orientation, viewportSize: viewPortSize)
//                    let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
                    
//                    let transformedImage = ciImage.transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)).cropped(to: cropRect)
                    let transformedImage = ciImage.transformed(by: self.combinedRGBTransform!).cropped(to: cropRect)
                    self.ciContext.render(transformedImage, to: outputBuffer, bounds: cropRect, colorSpace: CGColorSpaceCreateDeviceRGB())
                    
//                    self.assetWritingSemaphore.wait()
//                    defer { self.assetWritingSemaphore.signal() }
                    
                    if let success = self.pixelBufferAdapter?.append(outputBuffer, withPresentationTime: currentTime) {
                        if !success {
                            print("Failed to append RGB pixel buffer. Pixel buffer adapter state: \(self.pixelBufferAdapter?.assetWriterInput.isReadyForMoreMediaData), Time: \(currentTime)")
                            print(self.assetWriter?.error);
                            imgSuccessFlag = false
                        }
                    } else {
                        print("Failed to append RGB pixel buffer: Pixel buffer adapter is nil.")
                        imgSuccessFlag = false
                    }

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
                
//                Save metric depth data as binary file
                let width = CVPixelBufferGetWidth(depthPixelBuffer)
                let height = CVPixelBufferGetHeight(depthPixelBuffer)
                let bytesPerRow = CVPixelBufferGetBytesPerRow(depthPixelBuffer)
                
                guard let baseAddress = CVPixelBufferGetBaseAddress(depthPixelBuffer) else {
                    CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
                    return
                }
                
                let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
                let dataSize = width * height * MemoryLayout<Float32>.size
                let data = Data(bytes: floatBuffer, count: dataSize)
                
                // Save binary data to a file
                let fileURL = self.depthDirect.appendingPathComponent("\(self.depthImageCount).bin")
                do {
                    try data.write(to: fileURL)
//                    print("Saved depth data to \(fileURL)")
                } catch {
                    print("Error saving binary file: \(error)")
                }
                self.depthImageCount += 1
                
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
                
                
                var ciImageToRender = ciImageAfterFiltered
                
                if(self.isColorMapOpened){
                    let falseColorFilter = CIFilter.falseColor()
                    falseColorFilter.color0 = CIColor(red: 1, green: 1, blue: 0)
                    falseColorFilter.color1 = CIColor(red: 0, green: 0, blue: 1)
                    falseColorFilter.inputImage = ciImageAfterFiltered
                    ciImageToRender = falseColorFilter.outputImage!
                }
                
                
//                let normalizeTransform = CGAffineTransform(scaleX: 1.0/depthSize.width, y: 1.0/depthSize.height)
//                let flipTransform = CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)
//                let displayTransform = currentFrame.displayTransform(for: self.orientation, viewportSize: viewPortSize)
//                let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
//                let cropRect = CGRect(
//                    x: 0, y: 0, width: viewPortSize.width, height: viewPortSize.height
//                )
//                let transformedImage = ciImageToRender.transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)).cropped(to: cropRect)
                let transformedImage = ciImageToRender.transformed(by: self.combinedDepthTransform!).cropped(to: cropRect)
                
                if(self.isColorMapOpened) {
                    self.ciContext.render(transformedImage, to: depthOutputBuffer, bounds: CGRect(x: 0, y: 0, width: self.viewPortSize.width, height: self.viewPortSize.height), colorSpace: CGColorSpaceCreateDeviceRGB())
                } else {
                    self.ciContext.render(transformedImage, to: depthOutputBuffer, bounds: CGRect(x: 0, y: 0, width: self.viewPortSize.width, height: self.viewPortSize.height), colorSpace: CGColorSpaceCreateDeviceGray())
                }
                
                if let success = self.depthPixelBufferAdapter?.append(depthOutputBuffer, withPresentationTime: currentTime) {
                    if !success {
                        print("Failed to append depth pixel buffer. Pixel buffer adapter state: \(self.pixelBufferAdapter?.assetWriterInput.isReadyForMoreMediaData), Time: \(currentTime)")
                        print(self.assetWriter?.error);
                        imgSuccessFlag = false
                    }
                } else {
                    print("Failed to append depth pixel buffer: Pixel buffer adapter is nil.")
                    imgSuccessFlag = false
                }
                
                CVPixelBufferUnlockBaseAddress(depthOutputBuffer, [])
                CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
            }
            
                        
        }
//        let postImgTimestamp = CACurrentMediaTime()
//        print("Image retrieval time:", postImgTimestamp - preImgTimestamp)
        if !imgSuccessFlag {return}
//        print("Did not return", imgSuccessFlag)
        let cameraTransform = currentFrame.camera.transform

        // Transform the orientation matrix to unit quaternion
        let quaternion = simd_quaternion(cameraTransform)

        // Extract the value
        let orientationX = quaternion.vector.x
        let orientationY = quaternion.vector.y
        let orientationZ = quaternion.vector.z
        let orientationW = quaternion.vector.w
        
        // Use the last column's vlaue, which is the representation of translation
        let translationX = cameraTransform.columns.3.x
        let translationY = cameraTransform.columns.3.y
        let translationZ = cameraTransform.columns.3.z
        
        let currentTimer = Date()
        let dataReadTimeStamp = Int64(currentTimer.timeIntervalSince1970 * 1000)
        
        let poseWithTime = ["\"<\(dataReadTimeStamp)>\"", orientationX, orientationY, orientationZ, orientationW, translationX, translationY, translationZ] as [Any]
//        let postPoseTimestamp = CACurrentMediaTime()
//        print("Pose retrieval time:", postPoseTimestamp - postImgTimestamp)
        
        do {
            let line = poseWithTime.map { String(describing: $0)}.joined(separator: ",") + "\n"
            if let data = line.data(using: .utf8) {
                try self.poseFileHandle?.write(contentsOf: data)
            }
        } catch {
            print("Error when writing to the pose text file\n")
        }
        
//        let postWriteTimestamp = CACurrentMediaTime()
//        print("Saving time: ", postWriteTimestamp - postPoseTimestamp)
//        
//        let currentTimestamp = CACurrentMediaTime()
//        print("Iteration time: ", currentTimestamp - lastFrameTimestamp)
//
//        lastFrameTimestamp = currentTimestamp
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

        do {
            try poseFileHandle?.close()
        } catch {
            print("Error closing pose file")
        }

//        timer?.invalidate()
//        timer = nil
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
        return paths[0]
    }
    
    func createFile(targetURL: URL, fileName: String) throws {
            let fileURL = targetURL.appendingPathComponent(fileName)
            try FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    }
    
}
