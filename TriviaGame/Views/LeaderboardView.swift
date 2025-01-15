import SwiftUI
import Firebase
import FirebaseFirestore

struct LeaderboardView: View {
    @State private var users: [(id: String, name: String, average: Double, totalQuizzes: Int)] = []
    @State private var isLoading = true
    @State private var currentUserRank: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Leaderboard")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                // Current User Rank
                HStack {
                    Text("Your Rank:")
                        .font(.headline)
                    Text("#\(currentUserRank)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "3498DB"))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                
                // Leaderboard List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                            LeaderboardRow(
                                rank: index + 1,
                                name: user.name,
                                average: user.average,
                                totalQuizzes: user.totalQuizzes,
                                isCurrentUser: user.id == Auth.auth().currentUser?.uid
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(hex: "F5F6FA"))
        .onAppear(perform: fetchLeaderboard)
    }
    
    private func fetchLeaderboard() {
        guard let currentUser = Auth.auth().currentUser else { return }
        isLoading = true
        
        let db = Database.database().reference()
        db.child("userinfo").observeSingleEvent(of: .value) { snapshot in
            var usersList: [(id: String, name: String, average: Double, totalQuizzes: Int)] = []
            
            for child in snapshot.children {
                guard let snapshot = child as? DataSnapshot,
                      let value = snapshot.value as? [String: Any],
                      let name = value["username"] as? String,
                      let average = value["averageScore"] as? Double,
                      let totalQuizzes = value["totalQuizzes"] as? Int else {
                    continue
                }
                
                // Only include users who have taken at least one quiz
                if totalQuizzes > 0 {
                    usersList.append((
                        id: snapshot.key,
                        name: name,
                        average: average,
                        totalQuizzes: totalQuizzes
                    ))
                }
            }
            
            // Sort by average score in descending order
            // If averages are equal, sort by total quizzes (more quizzes ranks higher)
            usersList.sort { user1, user2 in
                if abs(user1.average - user2.average) < 0.001 {
                    return user1.totalQuizzes > user2.totalQuizzes
                }
                return user1.average > user2.average
            }
            
            // Update the users array
            self.users = usersList
            
            // Find current user's rank
            if let userIndex = usersList.firstIndex(where: { $0.id == currentUser.uid }) {
                self.currentUserRank = userIndex + 1
            } else {
                // If user hasn't taken any quizzes yet
                self.currentUserRank = usersList.count + 1
            }
            
            self.isLoading = false
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let average: Double
    let totalQuizzes: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(rankColor)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(isCurrentUser ? Color(hex: "3498DB") : Color(hex: "2C3E50"))
                
                Text("\(totalQuizzes) quizzes")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "7F8C8D"))
            }
            
            Spacer()
            
            Text(String(format: "%.1f%%", average))
                .font(.headline)
                .foregroundColor(Color(hex: "2ECC71"))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color(hex: "3498DB").opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "F1C40F") // Gold
        case 2: return Color(hex: "BDC3C7") // Silver
        case 3: return Color(hex: "E67E22") // Bronze
        default: return Color(hex: "7F8C8D") // Regular
        }
    }
}
