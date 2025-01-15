import SwiftUI
import FirebaseCore
import Cloudinary

class CloudinaryService {
    static let shared = CloudinaryService()
    private var cloudinary: CLDCloudinary

    private init() {
        // Replace with your Cloudinary credentials (preferably from a secure location)
        let config = CLDConfiguration(cloudName: "dtmaeg6xf", apiKey: "923796223786711")
        cloudinary = CLDCloudinary(configuration: config)
        
    }

    func uploadImage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        let uploadPreset = "onlinequiz" // Replace with your preset name

        cloudinary.createUploader().upload(data: imageData, uploadPreset: uploadPreset, completionHandler: { result, error in
            if let error = error {
                print("Cloudinary upload error: \(error.localizedDescription)")
                completion(nil)
            } else if let result = result, let url = result.secureUrl {
                print("Image uploaded successfully: \(url)")
                completion(url)
            }
        })
    }
}

@main
struct TriviaGameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(authManager)
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Firebase configured successfully")
        return true
    }
}
