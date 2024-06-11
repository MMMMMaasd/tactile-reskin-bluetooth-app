//
//  DataViewView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/29.
//

import SwiftUI
import UniformTypeIdentifiers

struct DataViewView: View {
    @EnvironmentObject var appStatus : AppInformation
    @State var showingExporter = false
    var body: some View {
        VStack{
            Text("Content of your reading data: ")
                .bold()
                .padding(.trailing, 100.0)
            HStack(alignment: .firstTextBaseline){
                let url = getDocumentsDirect()
                let content = getContent(new_url: url)
                Text(content)
                    .multilineTextAlignment(.leading)
                    .bold()
                    .foregroundColor(.white)
            
            }
            .frame(width: 300.0, height: 400.0)
            .background(Color.gray)
        }
        .padding(.bottom, 100)
        HStack{
            Text("File name: ")
                .bold()
            Text("data.txt")
                .bold()
                .foregroundColor(.blue)
            Button(action: {showingExporter.toggle()}, label: {
                Text("Export Data")
                Image(systemName: "square.and.arrow.up.on.square")
            })
            .buttonStyle(.bordered)
        }
        .fileExporter(isPresented: $showingExporter, document: TextFileInView(url: (getDocumentsDirect().appendingPathComponent("data.txt")).path), contentType: .plainText) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    func getContent(new_url:URL) -> String{
        do{
            let input = try String(contentsOf: new_url.appendingPathComponent("data.txt"))
            return input
        }catch{
            print(error.localizedDescription)
        }
        let str = "Error"
        return str
    }
}

struct TextFileInView: FileDocument {
    // tell the system we support only plain text
    static var readableContentTypes = [UTType.text]

    // by default our document is empty
    var text = ""
    var url : String

    init(url : String){
        self.url = url
    }
    /*
    
    // a simple initializer that creates new, empty documents
    init(initialText: String = "") {
        text = initialText
    }
     
    */

    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
        url = ""
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let file = try! FileWrapper(url: URL(fileURLWithPath: url), options: .immediate)
        /*
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
         */
        return file
    }
}

#Preview {
    DataViewView()
        .environmentObject(AppInformation())
}
