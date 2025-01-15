import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            if authManager.isLoggedIn {
                Home()
            } else {
                ContentView()
            }
        } else {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("AccentColor").opacity(0.6),
                        Color("AccentColor")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // App icon with animation
                    Image("AppIcon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 200, height: 200)
                                            .padding()
                                            
                                            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
                                            .scaleEffect(size)
                                            .opacity(opacity)
                    
                    Text("Online Quiz")
                        .font(.custom("AmericanTypewriter", size: 42))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .opacity(opacity)
                }
            }
            .onAppear {
                // Animate the splash screen
                withAnimation(.easeIn(duration: 1.2)) {
                    self.size = 0.9
                    self.opacity = 1.0
                }
                // Transition to main view after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
} 
