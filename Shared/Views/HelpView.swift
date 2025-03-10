//
//  HelpView.swift
//  iCryptr
//
//  Created by Brendan Lindsey
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Welcome to iCryptr")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("iCryptr is a secure file encryption app that allows you to protect your sensitive files and photos with strong AES-256 encryption.")
                            .font(.body)
                        
                        Text("Getting Started")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("• To encrypt a file, tap the \"Encrypt File\" button and select a file from your device.")
                            Text("• To encrypt a photo, tap the \"Encrypt Photo\" button and select a photo from your photo library.")
                            Text("• To decrypt a file, tap the \"Decrypt File\" button and select a .icryptr file.")
                        }
                        .font(.body)
                        
                        Text("Password Requirements")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your encryption password must contain:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("• At least 8 characters")
                            Text("• At least one uppercase letter")
                            Text("• At least one lowercase letter")
                            Text("• At least one number")
                            Text("• At least one symbol")
                        }
                        .font(.body)
                    }
                    
                    Group {
                        Text("Security Information")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("• iCryptr uses AES-256 encryption, a strong industry-standard encryption algorithm")
                            Text("• Encrypted files have the .icryptr extension")
                            Text("• The original file name is encrypted along with the file contents")
                        }
                        .font(.body)
                        
                        Text("Important Notes")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("• If you forget your password, your encrypted files CANNOT be recovered")
                            Text("• Always keep backups of your important files")
                        }
                        .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
            .previewDevice("iPhone 13 Pro")
    }
} 