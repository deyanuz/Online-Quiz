import SwiftUI
import Firebase
import FirebaseDatabase
import Cloudinary

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var currentImage: URL? = nil
    @State private var isEditing = false
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var totalQuizzes: Int = 0
    @State private var averageScore: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top Bar with Back Button
                HStack(spacing: 16) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(hex: "2C3E50"))
                            .frame(width: 44, height: 44)
                    }
                    
                    Text("Profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Spacer()
                    
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Image(systemName: isEditing ? "xmark" : "pencil")
                            .font(.title2)
                            .foregroundColor(isEditing ? Color(hex: "E74C3C") : Color(hex: "3498DB"))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                
                // Profile Image and Stats Section
                VStack(spacing: 24) {
                    // Profile Image
                    ZStack {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                        } else if let imageURL = currentImage {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: "E0E0E0"))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70)
                                        .foregroundColor(.white)
                                )
                        }
                        
                        if isEditing {
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Circle()
                                    .fill(Color(hex: "3498DB"))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: Color.black.opacity(0.2), radius: 5)
                            }
                            .offset(x: 50, y: 50)
                        }
                    }
                    .padding(.top, 24)
                    
                    // Statistics Cards
                    HStack(spacing: 16) {
                        StatisticCard(
                            title: "Total Quizzes",
                            value: "\(totalQuizzes)",
                            icon: "list.bullet.clipboard",
                            color: Color(hex: "3498DB")
                        )
                        
                        StatisticCard(
                            title: "Average Score",
                            value: String(format: "%.1f%%", averageScore),
                            icon: "chart.bar.fill",
                            color: Color(hex: "2ECC71")
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
                .padding(.horizontal, 16)
                
                // Profile Information
                VStack(alignment: .leading, spacing: 24) {
                    Text("Personal Information")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    VStack( alignment:.leading, spacing: 20) {
                        ProfileField(
                            title: "Name",
                            text: $name,
                            icon: "person.fill",
                            isEditing: isEditing
                        )
                        
                        ProfileField(
                            title: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            isEditing: false
                        )
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
                .padding(.horizontal, 16)
                
                if isEditing {
                    Button(action: saveProfile) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark")
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "2ECC71"))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: Color(hex: "2ECC71").opacity(0.3), radius: 5, y: 2)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color(hex: "F5F6FA"))
        .navigationBarHidden(true)
        .onAppear(perform: loadUserData)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .alert("Profile Update", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        let dbRef = Database.database().reference().child("userinfo").child(user.uid)
        dbRef.observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                name = value["name"] as? String ?? ""
                email = value["email"] as? String ?? ""
                totalQuizzes = value["totalQuizzes"] as? Int ?? 0
                averageScore = value["averageScore"] as? Double ?? 0.0
                
                if let imageURLString = value["profileImageURL"] as? String,
                   let imageURL = URL(string: imageURLString) {
                    currentImage = imageURL
                }
            }
        }
    }
    
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else { return }
        isSaving = true
        
        let saveData = {
            let updates: [String: Any] = [
                "name": name,
                "email": email
            ]
            
            Database.database().reference()
                .child("userinfo")
                .child(user.uid)
                .updateChildValues(updates) { error, _ in
                    isSaving = false
                    if let error = error {
                        alertMessage = "Failed to update profile: \(error.localizedDescription)"
                    } else {
                        alertMessage = "Profile updated successfully!"
                        isEditing = false
                    }
                    showAlert = true
                }
        }
        
        if let newImage = selectedImage {
            CloudinaryService.shared.uploadImage(image: newImage) { imageURL in
                if let imageURL = imageURL {
                    Database.database().reference()
                        .child("userinfo")
                        .child(user.uid)
                        .updateChildValues(["profileImageURL": imageURL])
                    currentImage = URL(string: imageURL)
                }
                saveData()
            }
        } else {
            saveData()
        }
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(height: 44)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "2C3E50"))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color(hex: "7F8C8D"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ProfileField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color(hex: "7F8C8D"))
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "3498DB"))
                    .frame(width: 44, height: 44)
                
                if isEditing {
                    TextField(title, text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(height: 44)
                } else {
                    Text(text)
                        .foregroundColor(Color(hex: "2C3E50"))
                        .frame(height: 44)
                }
            }
        }
    }
}
