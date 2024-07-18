//
//  DataViewView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/29.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation


struct DataViewView: View {
    @EnvironmentObject var appStatus : AppInformation
    @State var showingExporter = false
    @State private var fileName = ""
    @State private var clearRefresh = false
    var body: some View {
        VStack{
            if(clearRefresh){
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
            }else{
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
            Button(action: {
                /*
                let data_file_url = getDocumentsDirect().appendingPathComponent("data.txt")
                 */
                let emptyString = ""
                appStatus.SharedDataString = emptyString
                /*
                do{
                    try emptyString.write(to: data_file_url , atomically: true, encoding: .utf8)
                }catch {
                    print("Error appending to file: \(error)")
                }
                 */
                self.clearRefresh.toggle()
            },
                   label:{
                Text("Clear read data")
                Image(systemName: "eraser")
                
            }
            ).padding(.top, 20.0).buttonStyle(.bordered)
        }
        .padding(.bottom, 40)
        VStack{
            Text("File name format: ")
                .bold()
            Text("YYYY-MM-DD-hh/mm/ss.txt (current time)")
                .bold()
                .foregroundColor(.blue)
            Button(action: {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
                let currentDateTime = dateFormatter.string(from: Date())
                fileName = "\(currentDateTime).txt"
                do {
                    try createFile(fileName: fileName)
                    print("File saved successfully at \(fileName)")
                    let url = getDocumentsDirect().appendingPathComponent(fileName)
                    /*
                    if let existingContent = readDataFromTextFile() {
                        do {
                            try existingContent.write(to: url, atomically: true, encoding: .utf8)
                        } catch {
                            print("Error appending to file: \(error)")
                        }
                    }
                     */
                    do{
                        try appStatus.SharedDataString.write(to: url, atomically: true, encoding: .utf8)
                    }catch{
                        print("Error appending to file: \(error)")
                    }
                } catch {
                    print("Error saving file: \(error)")
                }
                showingExporter.toggle()
            }, label: {
                Text("Export data")
                Image(systemName: "square.and.arrow.up.on.square")
            })
            .buttonStyle(.bordered)
        }
        .fileExporter(isPresented: $showingExporter, document: TextFileInView(url: (getDocumentsDirect().appendingPathComponent(fileName)).path), contentType: .plainText) { result in
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
    
    func readDataFromTextFile() -> String? {
        let url = getDocumentsDirect().appendingPathComponent("data.txt")
        do {
            let contents = try String(contentsOf: url, encoding: .utf8)
            return contents
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
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
    
    func createFile(fileName: String) throws {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = documentsURL[0].appendingPathComponent(fileName)
            try FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
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
