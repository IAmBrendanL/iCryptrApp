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
    @State var presentPhotoImporter = false
    @State var presentFileImporter = false
    
    
    func fileImporterOnCompletion(result: Result<URL, Error>) {
        if case .success(let url) = result {
            pickedURL = url
            print("pickedURL: \(pickedURL!)")
        }
    }
    
    func handleButtonPress(for action: HelperService.EncryptionMode) {
        if action == .encrypt {
            fileTypes = [.data]
        } else {
            let iCryptrFileType = UTType(filenameExtension: "icryptr") ?? UTType.data
            fileTypes = [iCryptrFileType]
        }
        presentFileImporter = true
    }
    
    var body: some View {
        NavigationStack{
            ZStack {
                Color.gray
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    PhotosPicker(selection: $pickedPhoto, label: {
                        Text("Encrypt Photo")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10.0)
                    })
                    Spacer().frame(height: 20.0)
                    Button(action: {() -> () in handleButtonPress(for: .encrypt)}, label: {
                        Text("  Encrypt File  ")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10.0)
                        }
                    )
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
                    print(pickedPhoto)
                }
                .onChange(of: pickedURL) {
                    print(pickedURL)
                }
                .fileImporter(isPresented: $presentFileImporter, allowedContentTypes: fileTypes, onCompletion: fileImporterOnCompletion)
                .sheet(isPresented: $presentPhotoImporter) {
                }
                .toolbar {
                    Button(action: {() -> () in print("sfsds")}){ Text("?") .foregroundColor(Color.black)
                            .font(.title)
                            .padding(10)
                            .background(
                                Circle().stroke(.black, lineWidth: 2)
                                    .background(Color.white).cornerRadius(20)
                                    .opacity(0.5)
                            )
                    }
                }
            }
            .navigationTitle("iCryptr")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPhone 13 Pro")
        }
    }
}
