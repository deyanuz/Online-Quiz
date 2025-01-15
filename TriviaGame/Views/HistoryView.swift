import SwiftUI
import Firebase
import FirebaseFirestore

struct HistoryView: View {
    @State private var results: [(id: String, data: [String: Any])] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Quiz History")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .padding(.top, 20)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.top, 50)
                } else if results.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "95A5A6"))
                        Text("No quiz history yet")
                            .font(.headline)
                            .foregroundColor(Color(hex: "7F8C8D"))
                    }
                    .padding(.top, 50)
                } else {
                    LazyVStack(spacing: 15) {
                        ForEach(results, id: \.id) { result in
                            HistoryCard(result: result)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            fetchHistory()
        }
    }
    
    private func fetchHistory() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(user.uid)
            .collection("results")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error fetching history: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                results = documents.map { ($0.documentID, $0.data()) }
            }
    }
}

struct HistoryCard: View {
    let result: (id: String, data: [String: Any])
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Quiz Type Icon
                Image(systemName: isTrivia ? "brain.head.profile" : "list.bullet.clipboard")
                    .foregroundColor(isTrivia ? Color(hex: "9B59B6") : Color(hex: "E67E22"))
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quizTitle)
                        .font(.headline)
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "7F8C8D"))
                }
                
                Spacer()
                
                // Score Circle
                ZStack {
                    Circle()
                        .stroke(
                            Color(hex: scoreColor).opacity(0.2),
                            lineWidth: 4
                        )
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(percentage) / 100)
                        .stroke(
                            Color(hex: scoreColor),
                            style: StrokeStyle(
                                lineWidth: 4,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(percentage))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: scoreColor))
                }
                .frame(width: 50, height: 50)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var isTrivia: Bool {
        (result.data["quizId"] as? String)?.hasPrefix("trivia_") ?? false
    }
    
    private var quizTitle: String {
        if isTrivia {
            return "Trivia Quiz"
        }
        return "Regular Quiz"
    }
    
    private var percentage: Double {
        result.data["percentage"] as? Double ?? 0
    }
    
    private var formattedDate: String {
        let timestamp = result.data["timestamp"] as? TimeInterval ?? 0
        let date = Date(timeIntervalSince1970: timestamp)
        return date.formatted(date: .abbreviated, time: .shortened)
    }
    
    private var scoreColor: String {
        switch percentage {
        case 80...100: return "2ECC71" // Green
        case 60..<80: return "3498DB"  // Blue
        case 40..<60: return "F1C40F"  // Yellow
        default: return "E74C3C"       // Red
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
} 
