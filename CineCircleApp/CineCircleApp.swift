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
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Friend.self, Movie.self])
                .environmentObject(authService)
        }
    }
}
