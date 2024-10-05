//
//  ContentView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStatus : AppInformation
    var body: some View {
        if appStatus.ifGoToNextPage == 0{
            VStack {
                Image("NYU_Logo")
                    .resizable()
                    .frame(width:340.0, height: 200.0)
                Text("ReSkin Interaction APP")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .bold()
                Button(action: {
                    appStatus.ifGoToNextPage = 1
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
                }) {
                    Image("StartButton")
                        .resizable()
                        .frame(width: 150, height: 150)
                }
                .padding(.top, 10.0)
                .background(.white)
                /*
                NavigationLink(destination: MainPage()){
                    Image("StartButton")
                        .resizable(capInsets: EdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
                        .padding(.top, 10.0)
                        .frame(width: 150.0, height: 150.0)
                        .background(.white)
                }
                */
            }
        }else{
            MainPage()
        }
        /*
        NavigationView{
            VStack {
                Image("NYU_Logo")
                    .resizable()
                    .frame(width:340.0, height: 200.0)
                Text("ReSkin Interaction APP")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .bold()
                NavigationLink(destination: MainPage()){
                    Image("StartButton")
                        .resizable(capInsets: EdgeInsets(top: 0.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
                        .padding(.top, 10.0)
                        .frame(width: 150.0, height: 150.0)
                        .background(.white)
                }
            }
        }
         */
    }
    func launch(){
        print("launch to the operation page")
    }
}


class AppInformation : ObservableObject{
    @Published var ifGoToNextPage = 0
    @Published var SharedDataString = ""
    @Published var ifAllowedRead = 0
    @Published var sharedBluetoothManager =  BluetoothManager()
    @Published var tactileRecordTimeInterval: Double = 0.1
    @Published var animationFPS: Double = 60.0
    @Published var hapticFeedbackLevel: String = "medium"
    @Published var colorMapTrigger: Bool = false
}


#Preview {
    ContentView()
        .environmentObject(AppInformation())
}


