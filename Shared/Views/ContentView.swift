//
//  ContentView.swift
//  Shared
//
//  Created by Brendan Lindsey on 8/17/21.
//

import SwiftUI
import UIKit

enum CurrentSheet {
    case image, document, crypt, none
}

//struct ContentViewModel {
//    var currentSheet: CurrentSheet = .none
//    var encryptionMode: HelperService.EncryptionMode? = nil
//}

struct ContentView: View {
    @State var pickedImage: URL?
    @State var pickedDocument: UIDocument?
    @State var currentSheet: CurrentSheet? = nil
    @State var encryptionMode: HelperService.EncryptionMode? = nil
//    @State var contentViewState: ContentViewModel? = nil
    
    func updateSheetState(sheet: CurrentSheet, mode: HelperService.EncryptionMode) -> Void {
        encryptionMode = mode
        print(sheet, mode)
        currentSheet = sheet
    }
    
    func showSheetOnDismiss() {
        if [.document, .image].contains(currentSheet) && (pickedImage != nil || pickedDocument != nil) {
            currentSheet = .crypt
        } else {
            currentSheet =  nil
            pickedImage = nil
            pickedDocument = nil
        }
    }
    

    var body: some View {
        NavigationView {
            ZStack {
//                Color.gray
//                .edgesIgnoringSafeArea(.all)
                VStack {
                    Button(action: {updateSheetState(sheet: .image, mode: .encrypt)}) {
                        Text("Encrypt Photo")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10.0)
                    }
                    Spacer().frame(height: 20.0)
                    Button(action: {updateSheetState(sheet: .document, mode: .encrypt)}) {
                         Text("  Encrypt File  ")
                             .foregroundColor(Color.white)
                             .font(.largeTitle)
                             .padding()
                             .background(Color.blue)
                             .cornerRadius(10.0)
                    }
                    Spacer().frame(height: 20.0)
                    Button(action: {updateSheetState(sheet: .document, mode: .decrypt)}) {
                        Text(" Decrypt File  ")
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10.0)
                    }
                }
                .navigationBarTitle("iCryptr").foregroundColor(Color.white)
//                .sheet(isPresented: self.$contentViewState.showSheet, onDismiss: self.showSheetOnDismiss) {
//                    if contentViewState.currentSheet == .crypt {
//                        let fileURL = $pickedDocument.wrappedValue?.fileURL
//                        FileEncryptionView(encryptionMode: self.contentViewState.encryptionMode!, fileURL: fileURL, presentSelf: $contentViewState.showSheet)
//                    } else if let fileURL = $pickedImage.wrappedValue {
//                        FileEncryptionView(encryptionMode: self.contentViewState.encryptionMode!, fileURL: fileURL, presentSelf: $contentViewState.showSheet)
//                    } else if contentViewState.currentSheet == .image {
//                        ImagePicker(image: $pickedImage)
//                    } else if contentViewState.currentSheet == .document {
//                        DocumentPicker(encryptionMode: self.contentViewState.encryptionMode)
//                    }
//                }
                .sheet(item: self.$currentSheet, onDismiss: self.showSheetOnDismiss) { sheet in
                    if sheet == .crypt {
                        let fileURL = $pickedDocument.wrappedValue?.fileURL
                        FileEncryptionView(encryptionMode: encryptionMode!, fileURL: fileURL, presentSelf: true)
                    } else if let fileURL = $pickedImage.wrappedValue {
                        FileEncryptionView(encryptionMode: encryptionMode!, fileURL: fileURL, presentSelf: true)
                    } else if sheet == .image {
                        ImagePicker(image: $pickedImage)
                    } else if sheet == .document {
                        DocumentPicker(encryptionMode: encryptionMode)
                    }
                }
            }
        }
        .environment(\.horizontalSizeClass, .compact)
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
