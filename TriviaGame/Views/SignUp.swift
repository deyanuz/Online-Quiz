//
//  SignUp.swift
//  TriviaGame
//
//  Created by kuet on 8/11/23.
//

import SwiftUI
import Firebase
import FirebaseDatabase
import Cloudinary
import UIKit

struct SignUp: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var userName: String = ""
    @State private var name: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var userExist = 0
    @State private var userNameExist = 0
    @State private var invalidPass = 0
    @State private var isActive = false
    @State private var goToSignIn = false
    @State private var uid = ""
    @State private var showImagePicker = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            VStack {
                VStack {
                    Text("Sign Up")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                        .foregroundColor(Color("AccentColor"))

                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding(.bottom, 20)
                    } else {
                        ZStack {
                            Circle()
                                .stroke(Color.gray, lineWidth: 2)
                                .frame(width: 100, height: 100)

                            Button(action: {
                                showImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color("AccentColor"))
                                        .frame(width: 35, height: 35)
                                    Image(systemName: "plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 35, y: 35)
                        }
                        .padding(.bottom, 20)
                    }

                    TextField("Name", text: $name)
                        .padding()
                        .frame(width: 350, height: 50)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(10)
                        .disableAutocorrection(true)

                    TextField("Username", text: $userName)
                        .padding()
                        .frame(width: 350, height: 50)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(10)
                        .border(.red, width: CGFloat(userNameExist))
                        .disableAutocorrection(true)

                    TextField("Email", text: $email)
                        .padding()
                        .frame(width: 350, height: 50)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(10)
                        .border(.red, width: CGFloat(userExist))
                        .disableAutocorrection(true)

                    SecureField("Password", text: $password)
                        .padding()
                        .frame(width: 350, height: 50)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(10)
                        .border(.red, width: CGFloat(invalidPass))

                    Button("Sign Up") {
                        signUpBtn()
                    }
                    .foregroundColor(.white)
                    .frame(width: 350, height: 50)
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
                    .padding()

                    Text("Already have an account?")
                        .font(.title3)
                        .bold()
                        .padding()
                        .foregroundColor(Color("AccentColor"))

                    Button {
                        goToSignIn = true
                    } label: {
                        Text("Sign In")
                            .frame(width: 150, height: 50)
                    }
                    .foregroundColor(.white)
                    .frame(width: 150, height: 50)
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            .background(Color("Background"))

            if isActive || goToSignIn {
                ContentView()
            }

            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .alert("Error", isPresented: $authManager.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "An error occurred")
        }
        .disabled(isLoading)
    }

    func signUpBtn() {
        authManager.signUp(email: email, password: password) { success in
            if success {
                uploadImageToCloudinary()
            }
        }
    }

    func uploadImageToCloudinary() {
        guard let selectedImage = selectedImage else {
            print("No image selected.")
            return
        }

        CloudinaryService.shared.uploadImage(image: selectedImage) { imageURL in
            if let imageURL = imageURL {
                storeUserInfo(imageURL: imageURL)
            } else {
                print("Failed to upload image to Cloudinary.")
            }
        }
    }

    func storeUserInfo(imageURL: String) {
        let db = Database.database().reference()

        if let user = Auth.auth().currentUser {
            uid = user.uid
            isLoading = true

            let userInfo: [String: Any] = [
                "name": name,
                "username": userName,
                "email": email,
                "profileImageURL": imageURL,
                "totalQuizzes": 0,
                "averageScore": 0.0
            ]

            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.photoURL = URL(string: imageURL)

            changeRequest.commitChanges { [self] error in
                if let error = error {
                    print("Error updating profile: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                db.child("userinfo").child(uid).setValue(userInfo) { error, _ in
                    if let error = error {
                        print("Error writing user info to Firebase: \(error.localizedDescription)")
                        isLoading = false
                        return
                    }

                    let firestore = Firestore.firestore()
                    firestore.collection("users").document(uid).setData(userInfo) { error in
                        DispatchQueue.main.async {
                            isLoading = false
                            if let error = error {
                                print("Error writing to Firestore: \(error.localizedDescription)")
                            } else {
                                print("User info successfully written!")
                                isActive = true
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct signUp_Previews: PreviewProvider {
    static var previews: some View {
        SignUp()
    }
}
