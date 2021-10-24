//
//  SwiftUIView.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 6/23/20.
//  Copyright © 2020 Brendan Lindsey. All rights reserved.
//

import SwiftUI

struct EncryptActionView: View {
//    @Binding var fileURL: URL?
    var body: some View {
        VStack {
//            Image(<#T##cgImage: CGImage##CGImage#>, scale: <#T##CGFloat#>, label: <#T##Text#>)
            Button(action: {print("asdfas")}) {
                Text("Button")
            }
            Text("Placeholder")
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        EncryptActionView()
        .previewLayout(.sizeThatFits)
    }
}
