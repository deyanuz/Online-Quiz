import SwiftUI
import Firebase
import FirebaseFirestore

struct QuizCard: View {
    let question: String
    let options: [String: Bool]
    let creatorId: String
    let timestamp: TimeInterval
    @State private var creatorImage: URL?
    @State private var creatorName: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with user info
            HStack {
                AsyncImage(url: creatorImage) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                Text(creatorName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(Date(timeIntervalSince1970: timestamp).formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Question
            Text(question)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.vertical, 5)
            
            // Options
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(options.sorted(by: { $0.key < $1.key })), id: \.key) { option, isCorrect in
                    HStack {
                        Text(option)
                            .font(.body)
                        
                        Spacer()
                        
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "x.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .onAppear {
            fetchCreatorDetails()
        }
    }
    
    private func fetchCreatorDetails() {
            let ref = Database.database().reference()
            ref.child("userinfo").child(creatorId).observeSingleEvent(of: .value) { snapshot in
                if let data = snapshot.value as? [String: Any] {
                    self.creatorName = data["name"] as? String ?? "Anonymous"
                    if let profileImageURL = data["profileImageURL"] as? String {
                        self.creatorImage = URL(string: profileImageURL)
                    }
                }
            } withCancel: { error in
                print("Error fetching creator details: \(error.localizedDescription)")
            }
        }

}

struct AllQuizzesView: View {
    @State private var quizzes: [(id: String, data: [String: Any])] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView()
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(quizzes, id: \.id) { quiz in
                            if let question = quiz.data["question"] as? String,
                               let options = quiz.data["options"] as? [String: Bool],
                               let creatorId = quiz.data["createdBy"] as? String,
                               let timestamp = quiz.data["timestamp"] as? TimeInterval {
                                QuizCard(
                                    question: question,
                                    options: options,
                                    creatorId: creatorId,
                                    timestamp: timestamp
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .padding()
            .navigationTitle("All Quizzes")
            .onAppear {
                fetchAllQuizzes()
            }
        }
    }
    
    private func fetchAllQuizzes() {
        let db = Firestore.firestore()
        isLoading = true
        
        // Fetch all quizzes from single collection
        db.collection("quizzes")
            .order(by: "timestamp", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching quizzes: \(error)")
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    isLoading = false
                    return
                }
                
                self.quizzes = documents.map { doc in
                    (id: doc.documentID, data: doc.data())
                }
                
                isLoading = false
            }
    }
}

struct AllQuizzesView_Previews: PreviewProvider {
    static var previews: some View {
        AllQuizzesView()
    }
} 
