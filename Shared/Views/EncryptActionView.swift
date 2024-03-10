//
//  SwiftUIView.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 6/23/20.
//  Copyright © 2020 Brendan Lindsey. All rights reserved.
//

import SwiftUI

struct EncryptActionView: View {
    @Binding var fileURL: URL?
    var body: some View {
        VStack {
            Button(action: {print("asdfas")}) {
                Text("Button")
            }
            Text("Encrypt \(fileURL?.lastPathComponent ?? "File") ")
        }
    }
}

//struct SwiftUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        EncryptActionView(nil)
//        .previewLayout(.sizeThatFits)
//    }
//}
