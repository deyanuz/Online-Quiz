import Firebase
import FirebaseFirestore
import SwiftUI

struct AddQuiz: View {
    @State var option1: String = ""
    @State var option2: String = ""
    @State var option3: String = ""
    @State var option4: String = ""
    @State var quizid: String = ""
    @State var question: String = ""
    @State private var timestamp: TimeInterval = 0.0
    @State var isActive = false

    @State var clicked1 = false
    @State var clicked2 = false
    @State var clicked3 = false
    @State var clicked4 = false

    @State var uid = ""
    
    @State private var currentUserId: String = ""
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Add Quiz")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color("AccentColor"))
                        .padding(.top, 40)
                    
                    // Question Card
                    VStack(spacing: 20) {
                        TextField("Add a question", text: $question)
                            .font(.title3)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.05), radius: 5)
                            .disableAutocorrection(true)
                        
                        // Options Container
                        VStack(spacing: 16) {
                            // Option 1
                            OptionField(
                                text: $option1,
                                isSelected: clicked1,
                                optionNumber: 1,
                                action: {
                                    clicked1 = true
                                    clicked2 = false
                                    clicked3 = false
                                    clicked4 = false
                                }
                            )
                            
                            // Option 2
                            OptionField(
                                text: $option2,
                                isSelected: clicked2,
                                optionNumber: 2,
                                action: {
                                    clicked1 = false
                                    clicked2 = true
                                    clicked3 = false
                                    clicked4 = false
                                }
                            )
                            
                            // Option 3
                            OptionField(
                                text: $option3,
                                isSelected: clicked3,
                                optionNumber: 3,
                                action: {
                                    clicked1 = false
                                    clicked2 = false
                                    clicked3 = true
                                    clicked4 = false
                                }
                            )
                            
                            // Option 4
                            OptionField(
                                text: $option4,
                                isSelected: clicked4,
                                optionNumber: 4,
                                action: {
                                    clicked1 = false
                                    clicked2 = false
                                    clicked3 = false
                                    clicked4 = true
                                }
                            )
                        }
                        .padding(.vertical)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
                    
                    // Add Button
                    Button(action: storeQuestion) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Question")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color("AccentColor").opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.top)
                    
                    // Quiz ID Display
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(Color("AccentColor"))
                        Text("Quiz ID: \(quizid)")
                            .font(.headline)
                            .foregroundColor(Color("AccentColor"))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
                .padding()
            }
        }
        .onAppear {
            generateQuizId()
            getCurrentUser()
        }
    }
    
    func generateQuizId() {
        timestamp = Date().timeIntervalSince1970
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        quizid = dateFormatter.string(from: date)
    }
    
    private func getCurrentUser() {
        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
        }
    }
    
    func storeQuestion() {
        guard !currentUserId.isEmpty else {
            print("Error: No user logged in")
            return
        }
        
        let db = Firestore.firestore()
        
        // Create a dictionary for the options
        let options: [String: Bool] = [
            option1: clicked1,
            option2: clicked2,
            option3: clicked3,
            option4: clicked4
        ]
        
        // Create a dictionary for the question
        let questionData: [String: Any] = [
            "question": question,
            "options": options,
            "timestamp": timestamp,
            "createdBy": currentUserId,
            "quizId": quizid
        ]
        
        // Store in a single collection with quizId as document ID
        db.collection("quizzes")
            .document(quizid)
            .setData(questionData) { error in
                if let error = error {
                    print("Error storing data to Firestore: \(error.localizedDescription)")
                } else {
                    print("Question added to Firestore.")
                    isActive = true
                    // Reset all fields
                    option1 = ""
                    option2 = ""
                    option3 = ""
                    option4 = ""
                    question = ""
                    clicked1 = false
                    clicked2 = false
                    clicked3 = false
                    clicked4 = false
                }
            }
        generateQuizId()
    }
}

// Helper view for option fields
struct OptionField: View {
    @Binding var text: String
    let isSelected: Bool
    let optionNumber: Int
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Option \(optionNumber)", text: $text)
                .padding()
                .background(Color("Background"))
                .cornerRadius(12)
                .disableAutocorrection(true)
            
            Button(action: action) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : Color.gray.opacity(0.5))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

struct AddQuiz_Previews: PreviewProvider {
    static var previews: some View {
        AddQuiz()
    }
}
