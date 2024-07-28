//
//  cameraModelHome.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/7/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    
    @EnvironmentObject var cameraModel : CameraViewModel
    
    var body: some View {
        GeometryReader{proxy in
            let size = proxy.size
            
            CameraPreview(size:size)
                .environmentObject(cameraModel)
        }
        .onAppear(perform: cameraModel.checkPermission)
        .alert(isPresented: $cameraModel.alert){
            Alert(title: Text("Please Enable Camera and Microphoe Access"))
        }
    }
}

struct CameraPreview : UIViewRepresentable{
    
    @EnvironmentObject var cameraModel: CameraViewModel
    var size: CGSize
    
    func makeUIView(context: Context) ->  UIView {
        let view = UIView()
        
        cameraModel.preview = AVCaptureVideoPreviewLayer(session: cameraModel.sesson)
        cameraModel.preview.frame.size = size
        cameraModel.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraModel.preview)
        
        cameraModel.sesson.startRunning()
        
        return view
        
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
