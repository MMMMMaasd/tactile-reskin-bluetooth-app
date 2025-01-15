//
//  accountView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/27.
//

import SwiftUI

struct SettingsView : View{
    @EnvironmentObject var appStatus: AppInformation
    
    let frequencyOptions = ["0.1", "0.05", "0.033", "0.02", "0.017", "0.01"] // Frequency options
    
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
                    let binding = Binding<StreamingMode>(
                        get: { appStatus.rgbdVideoStreaming },
                        set: { newValue in
                            if newValue != StreamingMode.wifi { // Disable Option wifi
                                appStatus.rgbdVideoStreaming = newValue
                            }
                        }
                    )
//                    Picker("Streaming Options", selection: $appStatus.rgbdVideoStreaming) { // This can be used when we don't need to disable option
                    Picker("Streaming Options", selection: binding) { // Temporary fix to keep wifi option but disable it
                        Text("Wi-Fi").tag(StreamingMode.wifi).opacity(0.5)
                        Text("USB").tag(StreamingMode.usb)
                        Text("Off").tag(StreamingMode.off)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 125) // Adjust width for the picker
                }
                .padding(.vertical, 5)
            
                // Tactile Data Reading Frequency Picker
//                HStack {
//                    VStack(alignment: .leading, spacing: 8) {
//                        // Title and caption
//                        Text("Tactile Data Time Interval")
//                            .font(.body)
//                            .foregroundColor(.primary)
//                        Text("Time Period for tactile data reading")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                    // Picker in an HStack
//                    Spacer()
//                    Picker("", selection: $appStatus.tactileRecordTimeInterval) {
//                        ForEach(frequencyOptions, id: \.self) { option in
//                            Text(option)
//                        }
//                    }
//                    .pickerStyle(MenuPickerStyle()) // Dropdown style
//                    .frame(width:80)
//                }
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
}

enum StreamingMode: String {
    case off = "Off"
    case wifi = "Wi-Fi"
    case usb = "USB"
}

#Preview {
    SettingsView()
        .environmentObject(AppInformation())
}
