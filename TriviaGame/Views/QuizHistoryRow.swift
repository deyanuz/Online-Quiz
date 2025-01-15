import SwiftUI
import Firebase

struct QuizHistoryRow: View {
    let quizId: String
    let score: String
    @State private var quizTitle: String = ""
    @State private var date: Date = Date()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(quizTitle.isEmpty ? "Quiz \(quizId)" : quizTitle)
                    .font(.headline)
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(score)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onAppear {
            fetchQuizDetails()
        }
    }
    
    private func fetchQuizDetails() {
        // Fetch quiz title and date from Firebase
        let db = Database.database().reference()
        db.child("quizes").child(quizId).observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                self.quizTitle = value["title"] as? String ?? "Quiz \(quizId)"
                if let timestamp = value["timestamp"] as? Double {
                    self.date = Date(timeIntervalSince1970: timestamp)
                }
            }
        }
    }
} 