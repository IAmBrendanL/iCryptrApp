//
//  ContentView.swift
//  Shared
//
//  Created by Brendan Lindsey on 8/17/21.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PhotosUI

struct ContentView: View {
    @State var pickedURL: URL?
    @State var pickedPhoto: PhotosPickerItem?
    @State var fileTypes: [UTType] = []
    @State var presentFileImporter = false
    @State var presentEncryptionView = false
    @State private var showHelp = false
    @State private var navPath = NavigationPath()
    
    func fileImporterOnCompletion(result: Result<URL, Error>) {
        if case .success(let url) = result {
            pickedURL = url
            print("pickedURL: \(pickedURL!)")
        }
    }
    
    func handleButtonPress(for action: EncryptionMode) {
        if action == .encrypt {
            fileTypes = [.data]
        } else {
            let iCryptrFileType = UTType(filenameExtension: "icryptr") ?? UTType.data
            fileTypes = [iCryptrFileType]
        }
        presentFileImporter = true
    }
    
    func photoPickerCompletionHandler() {
        if pickedPhoto != nil {
            getURL(item: pickedPhoto!) { result in
                switch result {
                case .success(let photoURL):
                    self.pickedURL = photoURL
                case .failure(let failure):
                    print("Failed to import item", failure)
                    // TODO: Display import error
                }
            }
        }
    }
    
    
    // TODO: change this to swift concurrency
    func getURL(item: PhotosPickerItem, completionHandler: @escaping (_ result: Result<URL, Error>) -> Void) {
        // Step 1: Load as Data object.
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let contentType = item.supportedContentTypes.first {
                    // Step 2: make the URL file name and a get a file extention.
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let url = documentsDirectory.appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")")
                    if let data = data {
                        do {
                            // Step 3: write to temp App file directory and return in completionHandler
                            try data.write(to: url)
                            completionHandler(.success(url))
                        } catch {
                            completionHandler(.failure(error))
                        }
                    }
                }
            case .failure(let failure):
                completionHandler(.failure(failure))
            }
        }
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Button(action: {() -> () in handleButtonPress(for: .encrypt)}, label: {
                        Text("  Encrypt File  ")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10.0)
                    })
                    Spacer().frame(height: 20.0)
                    PhotosPicker(selection: $pickedPhoto, label: {
                        Text("Encrypt Photo")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10.0)
                    })
                    Spacer().frame(height: 20.0)
                    Button(action: {() -> () in handleButtonPress(for: .decrypt)}, label: {
                        Text(" Decrypt File  ")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10.0)
                        }
                    )
                }
                .onChange(of: pickedPhoto) {
                    if pickedPhoto != nil {
                        photoPickerCompletionHandler()
                    }
                }
                .onChange(of: pickedURL) {
                    if pickedURL != nil {
                        presentEncryptionView = true
                    }
                }
                .fileImporter(isPresented: $presentFileImporter, allowedContentTypes: fileTypes, onCompletion: fileImporterOnCompletion)
                .toolbar {
                    Button(action: { showHelp = true }) { 
                        Text("?")
                            .foregroundColor(Color.black)
                            .font(.title)
                            .padding(10)
                            .background(
                                Circle().stroke(.black, lineWidth: 2)
                                    .background(Color.white).cornerRadius(20)
                                    .opacity(0.5)
                            )
                    }
                }
                .sheet(isPresented: $showHelp) {
                    HelpView()
                }
            }
            .navigationDestination(isPresented: $presentEncryptionView) {
                EncryptActionView(fileURL: $pickedURL, shouldDeleteFileOnCompletion: $pickedPhoto.wrappedValue != nil)
                    .onAppear() {
                        self.pickedPhoto = nil // reset if a photo was selected
                    }
            }
            .navigationTitle("iCryptr")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 13 Pro")
    }
}
