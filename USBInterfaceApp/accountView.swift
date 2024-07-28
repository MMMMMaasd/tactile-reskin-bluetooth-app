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
            Text("Account View")
            Button(action: {appStatus.ifGoToNextPage = 0}){
                Text("Log out")
                    .foregroundColor(.red)
            }
            .padding(.top, 200.0)
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AppInformation())
}
