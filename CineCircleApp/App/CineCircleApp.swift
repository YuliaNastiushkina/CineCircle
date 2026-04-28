//
//  FriendsFavoriteMoviesApp.swift
//  FriendsFavoriteMovies
//
//  Created by Yulya on 2025-04-29.
//
import SwiftUI

@main
struct CineCircleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var coreDataStack = CoreDataManager.shared
    @StateObject private var userSession = UserSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
                .environment(\.authService, FirebaseAuthService())
                .environment(\.managedObjectContext,
                             coreDataStack.container.viewContext)
        }
    }
}
