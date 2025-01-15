import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct Home: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var triviaManager = TriviaManager()
    @State var score: [String: String] = [:]
    @State var userPhotoURL: URL?
    @State var userName: String = "User Name"
    @State var userEmail: String = "user@example.com"
    @State private var showSidebar = false
    @State private var loadingUserData = true
    @State private var totalQuizzes: Int = 0
    @State private var currentRank: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                //Sidebar
                VStack {
                    VStack(spacing: 16) {
                        if let photoURL = userPhotoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .shadow(color: .black.opacity(0.2), radius: 5)
                                    )
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 100, height: 100)
                                    .overlay(Text("Image"))
                            }
                            .padding(.top, 80)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 100, height: 100)
                                .overlay(Text("No Image"))
                                .padding(.top, 80)
                        }

                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)

                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                    .padding(.trailing, 70)

                    Divider()
                        .frame(height: 1)
                        .background(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.5), .white.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                        .padding(.horizontal)

                    Spacer()

                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                            Text("Sign Out")
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: 240)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FF4B4B"), Color(hex: "FF6B6B")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(hex: "FF4B4B").opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.trailing, 60)
                    .padding(.bottom, 30)
                }
                .frame(minWidth: 100, maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "2C3E50"), Color(hex: "3498DB")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(20)
                .edgesIgnoringSafeArea(.all)

                // Main Content
                VStack {
                    // Top Bar
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                showSidebar.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .foregroundColor(Color(hex: "2C3E50"))
                                .font(.title)
                                .padding(.leading, 20)
                        }
                        Spacer()
                    }
                    .frame(height: 50)
                    
                    // Main Content Area
                    ScrollView {
                        VStack(spacing: 25) {
                            // Header
                            Text("Online Quiz")
                                .font(.custom("AmericanTypewriter", size: 35))
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "2C3E50"))
                                .padding(.top, 20)
                            
                            // Action Buttons Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 20) {
                                // Create Quiz
                                NavigationLink(destination: AddQuiz()) {
                                    ActionCard(
                                        title: "Create Quiz",
                                        icon: "plus.circle.fill",
                                        color: Color(hex: "3498DB")
                                    )
                                }
                                
                                
                                // Trivia
                                NavigationLink(destination: TriviaView().environmentObject(triviaManager)) {
                                    ActionCard(
                                        title: "Trivia",
                                        icon: "brain.head.profile",
                                        color: Color(hex: "9B59B6")
                                    )
                                }
                                
                                // All Quizzes
                                NavigationLink(destination: AllQuizzesView()) {
                                    ActionCard(
                                        title: "All Quizzes",
                                        icon: "list.bullet.clipboard",
                                        color: Color(hex: "E67E22")
                                    )
                                }
                                
                                // History
                                NavigationLink(destination: HistoryView()) {
                                    ActionCard(
                                        title: "History",
                                        icon: "clock.arrow.circlepath",
                                        color: Color(hex: "1ABC9C")
                                    )
                                }
                                
                                // Leaderboard
                                NavigationLink(destination: LeaderboardView()) {
                                    ActionCard(
                                        title: "Leaderboard",
                                        icon: "trophy.fill",
                                        color: Color(hex: "F1C40F")
                                    )
                                }
                                // Profile
                                NavigationLink(destination: ProfileView()) {
                                    ActionCard(
                                        title: "Profile",
                                        icon: "person.circle.fill",
                                        color: Color(hex: "F1C40F")
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Statistics Section
                            statisticsSection
                            
                        }
                    }
                }
                .background(Color(hex: "F5F6FA"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: showSidebar ? 350 : 0)
            }
            .onAppear {
                loadUserData()
            }
            .disabled(loadingUserData) // Disable interactions while loading
        }
    }
    

    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            loadingUserData = true
            userPhotoURL = user.photoURL
            userEmail = user.email ?? "user@example.com"
            
            let dbRef = Database.database().reference().child("userinfo").child(user.uid)
            
            dbRef.observeSingleEvent(of: .value) { snapshot in
                if let value = snapshot.value as? [String: Any] {
                    userName = value["username"] as? String ?? "Username"
                    userEmail = value["email"] as? String ?? "user@example.com"
                    
                    // Update total quizzes
                    if let quizzes = value["totalQuizzes"] as? Int {
                        totalQuizzes = quizzes
                        score = Array(repeating: "", count: quizzes).reduce(into: [:]) { dict, _ in
                            dict[UUID().uuidString] = ""
                        }
                    }
                    
                    if let profileImageString = value["profileImageURL"] as? String,
                       let profileImageURL = URL(string: profileImageString) {
                        userPhotoURL = profileImageURL
                    }
                    
                    // After loading user data, update rank
                    updateCurrentRank()
                } else {
                    print("User data not found in Realtime Database")
                }
                loadingUserData = false
            }
        }
    }
    
    private func updateCurrentRank() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Database.database().reference()
        
        db.child("userinfo").observeSingleEvent(of: .value) { snapshot in
            var scores: [(uid: String, score: Double)] = []
            
            for child in snapshot.children {
                guard let snapshot = child as? DataSnapshot,
                      let value = snapshot.value as? [String: Any],
                      let averageScore = value["averageScore"] as? Double,
                      let totalQuizzes = value["totalQuizzes"] as? Int,
                      totalQuizzes > 0 else {
                    continue
                }
                
                scores.append((uid: snapshot.key, score: averageScore))
            }
            
            // Sort by score in descending order
            scores.sort { $0.score > $1.score }
            
            // Find current user's rank
            if let userIndex = scores.firstIndex(where: { $0.uid == user.uid }) {
                currentRank = userIndex + 1
            } else {
                currentRank = scores.count + 1
            }
        }
    }
    
    // Update the statistics section in the view
    var statisticsSection: some View {
        VStack(spacing: 20) {
            Text("Your Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "2C3E50"))
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Total Quizzes",
                    value: "\(totalQuizzes)",
                    color: Color(hex: "3498DB")
                )
                StatCard(
                    title: "Current Rank",
                    value: "#\(currentRank)",
                    color: Color(hex: "2ECC71")
                )
            }
        }
        .padding()
    }

}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
