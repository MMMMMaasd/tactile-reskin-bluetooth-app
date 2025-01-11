//
//  accountView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/27.
//

import SwiftUI

struct SettingsView : View{
    @EnvironmentObject var appStatus: AppInformation
    
    let streamingOptions = ["Wi-Fi", "USB", "Off"] // Streaming options
    let frequencyOptions = ["10Hz", "20Hz", "30Hz", "50Hz", "60Hz", "100Hz"] // Frequency options
    
    var body : some View{
        Form{
            Section(header: Text("GENERAL")) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        // Title and caption
                        Text("Live RGBD Streaming")
                            .font(.body) // Regular font
                            .foregroundColor(.primary)
                        Text("Stream to your computer")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Picker("Streaming Options", selection: $appStatus.rgbdVideoStreaming) {
                        ForEach(streamingOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 125) // Adjust width for the picker
                }
                .padding(.vertical, 5)
            
                // Tactile Data Reading Frequency Picker
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        // Title and caption
                        Text("Tactile Data Frequency")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("Frequency for tactile data reading")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    // Picker in an HStack
                    Spacer()
                    Picker("", selection: $appStatus.tactileRecordTimeInterval) {
                        ForEach(frequencyOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // Dropdown style
                    .frame(width:80)
                }
                .padding(.vertical, 5)
                HStack{
                        Text("Buttons haptic feedback")
                        .font(.body)
                        .foregroundColor(.primary)
//                        .padding(.leading, 20)
                        Spacer()
                        Picker("", selection: $appStatus.hapticFeedbackLevel) {
                            Text("medium").tag("medium")
                            Text("heavy").tag("heavy")
                            Text("light").tag("light")
                            Text("none").tag("none")
                        }
                        .pickerStyle(MenuPickerStyle()) // Dropdown style
                        .frame(width: 110)
//                    .padding(.leading, 75)
                }
                .padding(.vertical, 5)
                
            }
        }
    }
    
    
//    var body : some View{
//        ZStack{
//           // Text("Account View")
//            Text("Settings")
//                .fontWeight(.black)
//                .foregroundColor(Color.black)
//                .frame(width: 500.0, height: 140)
//                .ignoresSafeArea()
//                .background(.tabBackground)
//                .padding(.bottom, 600)
//            Text("General")
//                .fontWeight(.light)
//                .foregroundColor(Color.black)
//                .padding(.bottom, 435)
//                .padding(.trailing, 305)
//            
//            HStack{
//                    Text("Tactile data reading frequency")
//                    
//                    TextField("second", value: $appStatus.tactileRecordTimeInterval, format: .number)
//                        .frame(width: 60.0, height: 35)
//                        .textFieldStyle(.roundedBorder)
//                        .padding(.leading, 60)
//
//            }
//            .frame(width: 400.0, height: 40.0)
//            .background(.tabBackground)
//            .padding(.trailing, 5)
//            .padding(.bottom, 370.0)
//            
//            HStack{
//                    Text("Buttons haptic feedback")
//                    .padding(.leading, 20)
//                    
//                    
//                Picker("Style", selection: $appStatus.hapticFeedbackLevel) {
//                    Text("medium").tag("medium")
//                    Text("heavy").tag("heavy")
//                    Text("light").tag("light")
//                    Text("none").tag("none")
//                }
//                .frame(width: 110)
//                .padding(.leading, 75)
//
//            }
//            .frame(width: 400.0, height: 40.0)
//            .background(.tabBackground)
//            .padding(.trailing, 5)
//            .padding(.bottom, 280.0)
//            
//            HStack{
//                Text("Live RGBD Video Streaming")
//            }
//            
//            Text("Extra-Features")
//                .fontWeight(.light)
//                .foregroundColor(Color.black)
//                .padding(.top, 100)
//                .padding(.trailing, 255)
//            
//            HStack{
//                    Text("Render with colormap")
//                    .padding(.trailing, 3)
//                    
//                Picker("Style", selection: $appStatus.colorMapTrigger) {
//                    Text("Yes").tag(true)
//                    Text("No").tag(false)
//                }
//                .frame(width: 110)
//                .padding(.leading, 75)
//                .pickerStyle(.segmented)
//
//            }
//            .frame(width: 400.0, height: 40.0)
//            .background(.tabBackground)
//            .padding(.trailing, 5)
//            .padding(.top, 160.0)
//        
//            Button(action: {
//                appStatus.ifGoToNextPage = 0
//                if(appStatus.hapticFeedbackLevel == "medium") {
//                    let impact = UIImpactFeedbackGenerator(style: .medium)
//                    impact.impactOccurred()
//                } else if (appStatus.hapticFeedbackLevel == "heavy") {
//                    let impact = UIImpactFeedbackGenerator(style: .heavy)
//                    impact.impactOccurred()
//                } else if (appStatus.hapticFeedbackLevel == "light") {
//                    let impact = UIImpactFeedbackGenerator(style: .light)
//                    impact.impactOccurred()
//                }
//            }){
//                Text("Log out")
//                    .foregroundColor(.red)
//            }
//            .frame(width: 300.0, height: 40.0)
//            .background(.tabBackground)
//            .cornerRadius(10)
//            .padding(.top, 700.0)
//            
//            /*
//            Button(action: {print(appStatus.tactileRecordTimeInterval)}){
//                Text("yes")
//            }
//            .padding(.top, 100.0)
//             */
//
//        }
//        .padding(.bottom, 100.0)
//    }
}

#Preview {
    SettingsView()
        .environmentObject(AppInformation())
}
