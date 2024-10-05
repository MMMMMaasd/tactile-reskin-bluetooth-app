//
//  dataStroageView.swift
//  USBInterfaceApp
//
//  Created by 卞泽宇 on 2024/5/27.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct RecordView : View{
    @State var showingExporter = false
    @EnvironmentObject var appStatus : AppInformation
    @State private var fileName = ""
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
                            Text("View recorded tactile data")
                            Image(systemName: "doc.text")
                        }
                        .frame(width: 250.0, height: 45)
                        .background(.viewButton)
                        .cornerRadius(5)
                    }
                    Button(action: {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
                        let currentDateTime = dateFormatter.string(from: Date())
                        fileName = "\(currentDateTime).txt"
                        do {
                            try createFile(fileName: fileName)
                            print("File saved successfully at \(fileName)")
                            let url = getDocumentsDirect().appendingPathComponent(fileName)
                            if let existingContent = readDataFromTextFile() {
                                do {
                                    try existingContent.write(to: url, atomically: true, encoding: .utf8)
                                } catch {
                                    print("Error appending to file: \(error)")
                                }
                            }
                            
                            /*
                            do{
                                try appStatus.SharedDataString.write(to: url, atomically: true, encoding: .utf8)
                            }catch{
                                print("Error appending to file: \(error)")
                            }
                             */
                        } catch {
                            print("Error saving file: \(error)")
                        }
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
                        showingExporter.toggle()
                    }, label: {
                        Text("Export recorded tactile data")
                        Image(systemName: "square.and.arrow.up.on.square")
                    })
                    .buttonStyle(.bordered)
                }
            }
            .fileExporter(isPresented: $showingExporter, document: TextFile(url: (paths[0].appendingPathComponent(fileName)).path), contentType: .plainText) { result in
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
    func createFile(fileName: String) throws {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileURL = documentsURL[0].appendingPathComponent(fileName)
            try FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
    }
    
    func getDocumentsDirect() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0].path)
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
    
}

struct TextFile: FileDocument {
    // tell the system we support only plain text
    static var readableContentTypes = [UTType.text]

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


    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let file = try! FileWrapper(url: URL(fileURLWithPath: url), options: .immediate)
        /*
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
         */
        return file
    }
}

struct VideoFile: FileDocument{
    var url: URL
    
    static var readableContentTypes: [UTType] { [.mpeg4Movie] }
    static var writableContentTypes: [UTType] { [.mpeg4Movie] }
        
    // Initialize with a given URL
    init(url: URL) {
        self.url = url
    }
        
    // This is called when the system wants to read the previously saved data
    init(configuration: ReadConfiguration) throws {
        /*
        if let data = configuration.file.regularFileContents {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
            try data.write(to: tempURL)
            self.url = tempURL
        } else {
            throw CocoaError(.fileReadUnknown)
        }
         */
        self.url = URL(fileURLWithPath: "")
    }
        
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            return try FileWrapper(url: url, options: .immediate)
    }
}

struct ImageFile: FileDocument {
    var url: URL
    
    static var readableContentTypes: [UTType] { [.jpeg] }
    static var writableContentTypes: [UTType] { [.jpeg] }
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        self.url = URL(fileURLWithPath: "")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            return try FileWrapper(url: url, options: .immediate)
    }
    
        
}
enum FileElement {
    case videoFile(VideoFile)
    case textFile(TextFile)
    case directory(SubLevelDirectory)
}

enum FileElementSub {
    case imageFile(ImageFile)
}

struct SubLevelDirectory: FileDocument{
    var url: URL
    var containedFiles: [FileElementSub]
    
    static var readableContentTypes: [UTType] { [.folder] }
    static var writableContentTypes: [UTType] { [.folder] }
    
    init(url: URL) {
        self.url = url
        self.containedFiles = []
        do{
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for content in contents{
                if content.pathExtension.lowercased() == "ipeg" || content.pathExtension.lowercased() == "jpg" {
                    self.containedFiles.append(.imageFile(ImageFile(url: content)))
                }
            }
        }catch{
            print("Error when extract and append files to export directory")
        }
    }
    
    init(configuration: ReadConfiguration) throws {
        self.url = URL(fileURLWithPath: "")
        self.containedFiles = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let dirWrapper = FileWrapper(directoryWithFileWrappers: [:])
        for file in containedFiles {
            switch file {
                /*
                 case .videoFile(let videoFile):
                 let fileWrapper = try videoFile.fileWrapper(configuration: configuration)
                 dirWrapper.addFileWrapper(fileWrapper)
                 case .textFile(let textFile):
                 let fileWrapper = try textFile.fileWrapper(configuration: configuration)
                 dirWrapper.addFileWrapper(fileWrapper)
                 case .directory(let subDirectory):
                 let subDirWrapper = try subDirectory.fileWrapper(configuration: configuration)
                 dirWrapper.addFileWrapper(subDirWrapper)
                 }
                 */ // Only support image file right now
        
            case .imageFile(let imageFile):
                let fileWrapper = try imageFile.fileWrapper(configuration: configuration)
                dirWrapper.addFileWrapper(fileWrapper)
            default:
                continue
            }
        }
        return dirWrapper
    }
}
    
    
    struct DocumentaryFolder: FileDocument {
        var files: [FileElement]
        
        
        static var readableContentTypes: [UTType] { [.folder] }
        static var writableContentTypes: [UTType] { [.folder] }
        
        
        init(files: [FileElement]) {
            self.files = files
        }
        
        
        init(configuration: ReadConfiguration) throws {
            self.files = []
            // Implement reading logic if needed
        }
        
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            let folderWrapper = FileWrapper(directoryWithFileWrappers: [:])
            
            
            for file in files {
                switch file {
                case .videoFile(let videoFile):
                    let fileWrapper = try videoFile.fileWrapper(configuration: configuration)
                    fileWrapper.preferredFilename = videoFile.url.lastPathComponent
                    folderWrapper.addFileWrapper(fileWrapper)
                case .textFile(let textFile):
                    let fileWrapper = try textFile.fileWrapper(configuration: configuration)
                    fileWrapper.preferredFilename = URL(fileURLWithPath: textFile.url).lastPathComponent
                    folderWrapper.addFileWrapper(fileWrapper)
                case .directory(let directory):
                    let directoryWrapper = try directory.fileWrapper(configuration: configuration)
                    directoryWrapper.preferredFilename = directory.url.lastPathComponent
                    folderWrapper.addFileWrapper(directoryWrapper)
                }
            }
            
            return folderWrapper
        }
    }




#Preview {
    RecordView()
        .environmentObject(AppInformation())
}
