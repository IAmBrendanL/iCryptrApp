//
//  ContentView.swift
//  Shared
//
//  Created by Brendan Lindsey on 8/17/21.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var showSheet = false
    @State private var pickedImage: URL?
    @State private var pickedDocument: UIDocument?
    @State private var currentSheet: CurrentSheet = .image
    @State private var encryptionMode: HelperService.EncryptionMode?

    enum CurrentSheet {
        case image, document
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray
                .edgesIgnoringSafeArea(.all)
                VStack {
                    Button(action: {
                        self.showSheet = true
                        self.currentSheet = .document
//                        let thing = ImportFilesAction
//                        thing.callAsFunction(thing)
                        
                    },
                         label: {
                             Text("  Encrypt File  ")
                                 .foregroundColor(Color.white)
                                 .font(.largeTitle)
                                 .padding()
                                 .background(Color.blue)
                                 .cornerRadius(10.0)
                         }
                    )
                    Spacer().frame(height: 20.0)
                    Button(action: { self.showSheet = true; self.currentSheet = .image; self.encryptionMode = .encrypt },
                        label: {
                            Text("Encrypt Photo")
                                .foregroundColor(Color.white)
                                .font(.largeTitle)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10.0)
                        }
                    )
                    Spacer().frame(height: 20.0)
                    Button(action: { self.showSheet = true; self.currentSheet = .document; self.encryptionMode = .decrypt },
                        label: {
                            Text(" Decrypt File  ")
                                .foregroundColor(Color.white)
                                .font(.largeTitle)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10.0)
                        }
                    )
                }
                .navigationBarTitle("iCryptr").foregroundColor(Color.white)
                .navigationBarItems(trailing:
                    Button(action: {print("Go To Settings")},
                        label: {
                            Text("Settings")
                                .foregroundColor(Color.white)
                        }
                    )
                )
                .sheet(isPresented: $showSheet) {
                    if self.currentSheet == .image {
                        ImagePicker(image: self.$pickedImage)
                    } else if let fileURL = self.pickedDocument?.fileURL {
                        FileEncryptionView(encryptionMode: self.$encryptionMode.wrappedValue!, fileURL: fileURL)
                    } else if let fileURL = self.pickedImage {
                        FileEncryptionView(encryptionMode: self.$encryptionMode.wrappedValue!, fileURL: fileURL)
                    } else {
                        DocumentPicker(encryptionMode: self.$encryptionMode.wrappedValue)
                    }
                }
            }
        }
        .environment(\.horizontalSizeClass, .compact)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
