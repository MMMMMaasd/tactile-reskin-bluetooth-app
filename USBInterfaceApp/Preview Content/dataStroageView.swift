//
//  dataStroageView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/27.
//

import SwiftUI
import UniformTypeIdentifiers

struct RecordView : View{
    @State var showingExporter = false
    @EnvironmentObject var appStatus : AppInformation
    var body : some View{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        NavigationView{
            VStack{
                /*
                Text("Record View")
                    .onTapGesture {
                        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                        print(paths[0].path)
                        do{
                            let input = try String(contentsOf: paths[0].appendingPathComponent("data.txt"))
                            print(input)
                        }catch{
                            print(error.localizedDescription)
                        }
                    }
                 */
                VStack{
                    NavigationLink(destination: DataViewView()){
                        HStack{
                            Text("View your data")
                            Image(systemName: "doc.text")
                        }
                        .frame(width: 150.0, height: 45)
                        .background(.viewButton)
                        .cornerRadius(5)
                    }
                    Button(action: {showingExporter.toggle()}, label: {
                        Text("Export Data")
                        Image(systemName: "square.and.arrow.up.on.square")
                    })
                    .buttonStyle(.bordered)
                }
                .padding(.top, 300.0)
                VStack{
                    Text("Need helps for understanding?")
                        .font(.headline)
                        .padding(.top, 150)
                        .bold()
                    Link(destination: URL(string: "https://reskin.dev/")!, label: {
                        HStack{
                            Text("More about Reskin -> ")
                                .bold()
                            Image("ReskinPicture")
                                .resizable()
                                .frame(width: 40.0, height: 40.0)
                                .cornerRadius(20)
                                
                        }
                        .frame(width: 280, height: 50)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(12)
                    })
                    Link(destination: URL(string: "https://github.com/raunaqbhirangi/reskin_sensor")!, label: {
                        HStack{
                            Text("Reskin Library -> ")
                                .bold()
                            Image("GithubLogo")
                                .resizable()
                                .padding(.bottom, 3.0)
                                .frame(width: 50.0, height: 50.0)
                                .cornerRadius(12)
                        }
                        .frame(width: 280, height: 50)
                        .foregroundColor(.white)
                        .background(Color.black)
                        .cornerRadius(12)
                    })
                }
                .padding(.top, 10.0)
                .padding(.bottom, 100)
            }
            .fileExporter(isPresented: $showingExporter, document: TextFile(url: (paths[0].appendingPathComponent("data.txt")).path), contentType: .plainText) { result in
                switch result {
                case .success(let url):
                    print("Saved to \(url)")
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        }
    /*
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
        return paths[0]
    }
     */
}

struct TextFile: FileDocument {
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
    RecordView()
        .environmentObject(AppInformation())
}
