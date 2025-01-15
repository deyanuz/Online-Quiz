//
//  TriviaView.swift
//  TriviaGame
//
//  Created by kuet on 8/11/23.
//

import SwiftUI
import Firebase

struct TriviaView: View {
    @EnvironmentObject var triviaManager: TriviaManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showEndQuizAlert = false
    @State private var isStoringScore = false
    
    var body: some View {
        if triviaManager.reachedEnd {
            ZStack {
                Color(hex: "F5F6FA").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Score Circle
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "E0E0E0"), lineWidth: 20)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(triviaManager.score) / CGFloat(triviaManager.length))
                            .stroke(
                                Color(hex: scoreColor),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: triviaManager.score)
                        
                        VStack(spacing: 8) {
                            Text("\(triviaManager.score)/\(triviaManager.length)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color(hex: "2C3E50"))
                            
                            Text("Score")
                                .font(.title3)
                                .foregroundColor(Color(hex: "7F8C8D"))
                        }
                    }
                    .padding(.top, 40)
                    
                    Text("Quiz Completed! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "2C3E50"))
                        .padding(.top, 20)
                    
                    Text("Great job on completing the quiz!")
                        .font(.body)
                        .foregroundColor(Color(hex: "7F8C8D"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button {
                            handleButtonAction {
                                Task.init {
                                    await triviaManager.fetchTrivia()
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Play Again")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "3498DB"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: Color(hex: "3498DB").opacity(0.3), radius: 8, y: 4)
                        }
                        
                        Button {
                            handleButtonAction {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "2ECC71"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: Color(hex: "2ECC71").opacity(0.3), radius: 8, y: 4)
                        }
                    }
                    .disabled(isStoringScore)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        } else {
            VStack {
                HStack {
                    Button {
                        showEndQuizAlert = true
                    } label: {
                        Text("End Quiz")
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text("\(triviaManager.index + 1)/\(triviaManager.length)")
                        .font(.headline)
                        .foregroundColor(Color(hex: "3498DB"))
                }
                .padding(.horizontal)
                
                // Improved Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "E0E0E0"))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "3498DB"))
                            .frame(width: CGFloat(Double(triviaManager.index + 1) / Double(triviaManager.length)) * geometry.size.width,
                                   height: 8)
                            .animation(.easeInOut, value: triviaManager.index)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                QuestionView()
                    .environmentObject(triviaManager)
            }
            .foregroundColor(Color("AccentColor"))
            .padding()
            .background(Color("Background"))
            .alert(isPresented: $showEndQuizAlert) {
                Alert(
                    title: Text("End Quiz"),
                    message: Text("Are you sure you want to end this quiz? Your progress will be lost."),
                    primaryButton: .destructive(Text("End Quiz")) {
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func handleButtonAction(completion: @escaping () -> Void) {
        guard !isStoringScore else { return }
        isStoringScore = true
        
        storeScore { success in
            isStoringScore = false
            if success {
                completion()
            }
        }
    }
    
    func storeScore(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let realtimeDb = Database.database().reference()
        
        if let user = Auth.auth().currentUser {
            let timestamp = Date().timeIntervalSince1970
            let quizId = String(format: "%.0f", timestamp)
            let currentPercentage = (Double(triviaManager.score) / Double(triviaManager.length)) * 100
            
            // First store the quiz result
            let resultData: [String: Any] = [
                "score": triviaManager.score,
                "totalQuestions": triviaManager.length,
                "quizId": "trivia_\(quizId)",
                "timestamp": timestamp,
                "percentage": currentPercentage,
                "type": "online"
            ]
            
            // Update Firestore average
            let userRef = db.collection("users").document(user.uid)
            
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let userDocument: DocumentSnapshot
                do {
                    try userDocument = transaction.getDocument(userRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                let oldAverage = userDocument.data()?["averageScore"] as? Double ?? 0
                let totalQuizzes = userDocument.data()?["totalQuizzes"] as? Int ?? 0
                
                // Calculate new average
                let newTotalQuizzes = totalQuizzes + 1
                let newAverage = ((oldAverage * Double(totalQuizzes)) + currentPercentage) / Double(newTotalQuizzes)
                
                transaction.updateData([
                    "averageScore": newAverage,
                    "totalQuizzes": newTotalQuizzes
                ], forDocument: userRef)
                
                // Also update Realtime Database
                let userInfoRef = realtimeDb.child("userinfo").child(user.uid)
                userInfoRef.updateChildValues([
                    "averageScore": newAverage,
                    "totalQuizzes": newTotalQuizzes
                ])
                
                return nil
            }) { (_, error) in
                if let error = error {
                    print("Error updating average: \(error)")
                }
            }
            
            // Store the quiz result
            userRef.collection("results")
                .document(quizId)
                .setData(resultData) { error in
                    if let error = error {
                        print("Error storing trivia result: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Trivia result successfully stored with ID: \(quizId)")
                        completion(true)
                    }
                }
        } else {
            completion(false)
        }
    }
    
    private var scoreColor: String {
        let percentage = Double(triviaManager.score) / Double(triviaManager.length) * 100
        switch percentage {
        case 80...100: return "2ECC71" // Green
        case 60..<80: return "3498DB"  // Blue
        case 40..<60: return "F1C40F"  // Yellow
        default: return "E74C3C"       // Red
        }
    }
}

struct TriviaView_Previews: PreviewProvider {
    static var previews: some View {
        TriviaView()
            .environmentObject(TriviaManager())
    }
}
