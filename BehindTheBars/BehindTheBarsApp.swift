/*
 import SwiftUI
 import Firebase
 
 @main
 struct BehindTheBarsApp: App {
 
 init() {
 FirebaseApp.configure()
 }
 
 var body: some Scene {
 WindowGroup {
 Text("Initializing...")
 }
 }
 }
 */

import SwiftUI
import Firebase

@main
struct BehindTheBarsApp: App {
    
    @StateObject var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
