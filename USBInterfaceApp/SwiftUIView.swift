//
//  SwiftUIView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/7/26.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        Button(action: {}){
            Text("save AR data")
                .padding()
        }
        .padding(.leading, 200.0)
        .padding(.top, 500.0)
        .buttonStyle(.bordered)
        
    }
}

#Preview {
    SwiftUIView()
}
