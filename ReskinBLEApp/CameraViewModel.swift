//
//  CameraViewModel.swift
//  USBInterfaceApp
//
//  Created by Michael on 2024/7/25.
//


import SwiftUI
import AVFoundation
import UIKit

class CameraViewModel : NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate{
    //@Published var isTaken = true
    @Published var sesson = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCaptureMovieFileOutput()
    @Published var preview : AVCaptureVideoPreviewLayer!
    //@Published var isSaved = false
    //@Published var picData = Data(count: 0)
    
    @Published var isRecording : Bool = false
    @Published var recordedURLS : [URL] = []
    @Published var previewURL : URL?
    @Published var showPreview : Bool = false
    
    func checkPermission(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video){ (status) in
                if status{
                    self.setUp()
                }
                        
            }
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
        }
    }
    
    func setUp(){
        do{
            self.sesson.beginConfiguration()
            let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let videoInput = try AVCaptureDeviceInput(device: cameraDevice!)
            
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            
            if self.sesson.canAddInput(videoInput) && self.sesson.canAddInput(audioInput){
                self.sesson.addInput(videoInput)
                self.sesson.addInput(audioInput)
            }
            if self.sesson.canAddOutput(self.output){
                self.sesson.addOutput(self.output)
            }
            self.sesson.commitConfiguration()
        }
        catch{
            print(error.localizedDescription)
        }
    }
    /*
    func takePic(){
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            self.sesson.stopRunning()
            
            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
            }
        }
    }
    
    func reTake(){
        DispatchQueue.global(qos: .background).async {
            self.sesson.startRunning()
            
            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
                self.isSaved = false
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil{
            return
        }
        
        print("pic taken...")
        
        guard let imageData = photo.fileDataRepresentation() else{return}
        
        self.picData = imageData
        
    }
    
    func savePic(){
        let image = UIImage(data: self.picData)!
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.isSaved = true
        
        print("saved successfully...")
        
    }
     */
    func startRecording(){
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        output.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        isRecording = true
    }
    
    func stopRecording(){
        output.stopRecording()
        isRecording = false
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error{
            print(error.localizedDescription)
            return
        }
        
        print(outputFileURL)
    
        let videoPath = outputFileURL.path
        
        let videoPathString = String(videoPath)
                
        UISaveVideoAtPathToSavedPhotosAlbum(videoPathString as String, nil, nil, nil)
        print("saved successfully...")
    }
    
}
