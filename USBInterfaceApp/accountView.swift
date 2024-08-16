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
            Section{
                Text("Animation Rate")
                    .padding(.trailing, 245.0)
                    .padding(.bottom, 380.0)
                
            }
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
            .padding(.bottom, 280.0)
            Button(action: {appStatus.ifGoToNextPage = 0}){
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
