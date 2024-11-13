//
//  accountView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/27.
//

import SwiftUI

struct AccountView : View{
    @EnvironmentObject var appStatus: AppInformation
    var body : some View{
        ZStack{
           // Text("Account View")
            Text("Settings")
                .fontWeight(.black)
                .foregroundColor(Color.black)
                .frame(width: 500.0, height: 140)
                .ignoresSafeArea()
                .background(.tabBackground)
                .padding(.bottom, 600)
            Text("General")
                .fontWeight(.light)
                .foregroundColor(Color.black)
                .padding(.bottom, 435)
                .padding(.trailing, 305)
            
            HStack{
                    Text("Tactile data reading frequency")
                    
                    TextField("second", value: $appStatus.tactileRecordTimeInterval, format: .number)
                        .frame(width: 60.0, height: 35)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading, 60)

            }
            .frame(width: 400.0, height: 40.0)
            .background(.tabBackground)
            .padding(.trailing, 5)
            .padding(.bottom, 370.0)
            
            HStack{
                    Text("Buttons haptic feedback")
                    .padding(.leading, 20)
                    
                    
                Picker("Style", selection: $appStatus.hapticFeedbackLevel) {
                    Text("medium").tag("medium")
                    Text("heavy").tag("heavy")
                    Text("light").tag("light")
                    Text("none").tag("none")
                }
                .frame(width: 110)
                .padding(.leading, 75)

            }
            .frame(width: 400.0, height: 40.0)
            .background(.tabBackground)
            .padding(.trailing, 5)
            .padding(.bottom, 280.0)
            
            Text("Extra-Features")
                .fontWeight(.light)
                .foregroundColor(Color.black)
                .padding(.top, 100)
                .padding(.trailing, 255)
            
            HStack{
                    Text("Render with colormap")
                    .padding(.trailing, 3)
                    
                Picker("Style", selection: $appStatus.colorMapTrigger) {
                    Text("Yes").tag(true)
                    Text("No").tag(false)
                }
                .frame(width: 110)
                .padding(.leading, 75)
                .pickerStyle(.segmented)

            }
            .frame(width: 400.0, height: 40.0)
            .background(.tabBackground)
            .padding(.trailing, 5)
            .padding(.top, 160.0)
        
            Button(action: {
                appStatus.ifGoToNextPage = 0
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
            }){
                Text("Log out")
                    .foregroundColor(.red)
            }
            .frame(width: 300.0, height: 40.0)
            .background(.tabBackground)
            .cornerRadius(10)
            .padding(.top, 700.0)
            
            /*
            Button(action: {print(appStatus.tactileRecordTimeInterval)}){
                Text("yes")
            }
            .padding(.top, 100.0)
             */

        }
        .padding(.bottom, 100.0)
    }
}

#Preview {
    AccountView()
        .environmentObject(AppInformation())
}
