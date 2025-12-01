import SwiftUI

struct EmailInputDialogView: View {
    @Binding var email: String
    let dismissAction: () -> Void
    @ObservedObject var cameraService: CameraService // Inject CameraService
    let onUserInteraction: (() -> Void)? // New callback for user interaction
    
    @State private var emailError: String = ""
    
    // Computed property to check email format (pure function, no state modification)
    private var isValidEmailFormat: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // New function to trigger validation and update error state
    private func triggerValidation() {
        if email.isEmpty {
            emailError = "El correo no puede estar vacío"
        } else if !isValidEmailFormat {
            emailError = "Formato de correo inválido"
        } else {
            emailError = ""
        }
    }
    
    // For controlling the dialog's position
    @State private var dialogOffset: CGSize = CGSize(width: 0, height: UIScreen.main.bounds.height)
    
    // For the overall dialog background
    let dialogBackgroundColor = Color(red: 0.25, green: 0.75, blue: 0.75) // A turquoise-like color

    var body: some View {
        ZStack {
            // Invisible background to capture taps outside the dialog if needed (not explicitly requested)
            // Color.black.opacity(0.001) // Can add this if we want to dismiss on tap outside

            ZStack(alignment: .topTrailing) { // ZStack for positioning the close button
                VStack { // Main dialog content
                    switch cameraService.photoCaptureState {
                    case .showingEmailInput(.some(.sending)):
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding()
                        Text("Enviando correo...")
                            .font(.headline)
                            .foregroundColor(.white)

                    case .showingEmailInput(.some(.success)):
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .padding(.bottom, 5)
                        Text("¡Correo enviado con éxito!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        Button(action: {
                            onUserInteraction?() // Notify interaction before dismissing
                            dismissAction() // Dismisses the dialog
                        }) {
                            Text("Enviado!")
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 15)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }

                    case .showingEmailInput(.some(.failed(let errorMessage))):
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .padding(.bottom, 5)
                        Text("No se pudo enviar el correo;")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("las imágenes siguen guardadas.")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        
                        // Retry and Cancel buttons
                        HStack {
                            Button(action: {
                                onUserInteraction?() // Notify interaction
                                Task {
                                    await cameraService.sendEmail() // Retry sending email
                                }
                            }) {
                                Text("Reintentar")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 15)
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                onUserInteraction?() // Notify interaction
                                dismissAction() // Dismisses the dialog
                            }) {
                                Text("Cancelar")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 15)
                                    .background(Color.gray)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Optionally display the actual error message for debugging purposes
                        // You can comment this out for production
                        Text("Error técnico: \(errorMessage)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                    case .showingEmailInput(.none): // Initial email input state
                        Text("Ingresa tu correo para enviar las fotos")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        TextField("email@gmail.com", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal)
                            .onChange(of: email) { _ in
                                DispatchQueue.main.async {
                                    triggerValidation()
                                }
                            }
                        
                        if !emailError.isEmpty {
                            Text(emailError)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            onUserInteraction?() // Notify interaction before sending
                            Task {
                                await cameraService.sendEmail()
                            }
                        }) {
                            Text("Enviar")
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 15)
                                .background(isValidEmailFormat && !email.isEmpty ? Color.orange : Color.gray)
                                .cornerRadius(8)
                        }
                        .padding(.top, 10)
                        .disabled(!isValidEmailFormat || email.isEmpty)
                        
                    default: // Should not happen if photoCaptureState is always managed correctly within showingEmailInput
                        EmptyView()
                    }
                }
                .padding()
                .frame(width: UIScreen.main.bounds.width * 0.8) // 80% of screen width
                .background(dialogBackgroundColor)
                .cornerRadius(20)
                .shadow(radius: 10)
                .onTapGesture {
                    onUserInteraction?() // Notify interaction on any tap within the dialog content
                }
                
                // Close button at top right
                Button(action: {
                    onUserInteraction?() // Notify interaction before dismissing
                    dismissAction()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .padding(10) // Padding for the close button
            }
            .offset(dialogOffset) // Apply offset for animation
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) { // 1 second bottom to center transition
                    dialogOffset = .zero // Move to center (default offset)
                }
            }
        }
    }
}

struct EmailInputDialogView_Previews: PreviewProvider {
    static var previews: some View {
        EmailInputDialogView(email: .constant("test@example.com"), dismissAction: {}, cameraService: CameraService(), onUserInteraction: nil) // Pass a dummy CameraService and nil for onUserInteraction
            .previewLayout(.sizeThatFits)
    }
}
