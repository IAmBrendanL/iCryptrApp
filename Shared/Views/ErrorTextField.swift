import SwiftUI

struct ErrorTextField: View {
    var title: String
    @Binding var text: String
    var errorMessage: String?
    var isSecure: Bool = false
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSecure {
                SecureField("", text: $text, prompt: Text(title).foregroundStyle(Color.gray))
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10.0)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(errorMessage == nil ? .clear : .red, lineWidth: 4)
                    }
                    .onSubmit {
                        if let onSubmit = onSubmit {
                            onSubmit()
                        }
                    }
            } else {
                TextField("", text: $text, prompt: Text(title).foregroundStyle(Color.gray))
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10.0)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(errorMessage == nil ? .clear : .red, lineWidth: 4)
                    }
                    .autocorrectionDisabled()
                    .onSubmit {
                        if let onSubmit = onSubmit {
                            onSubmit()
                        }
                    }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.red.opacity(0.8))
                    )
                    .padding(.top, 2)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorTextField(
            title: "Username",
            text: .constant(""),
            errorMessage: nil
        )
        
        ErrorTextField(
            title: "Password",
            text: .constant("weak"),
            errorMessage: "The password must contain at least one uppercase letter, one lowercase letter, one number, and be at least 8 characters long",
            isSecure: true
        )

    }
    .padding()
    .background(Color.gray)
} 
