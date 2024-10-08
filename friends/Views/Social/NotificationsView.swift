//
//  NotificationsView.swift
//  friends
//
//  Created by Bryan Hoang on 10/7/24.
//

import SwiftUI

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var isLoading = false

    func loadNotifications(uid: String) {
        Task {
            do {
                isLoading = true
                let fetchedNotifications = try await UserManager.shared.fetchNotifications(uid: uid)
                DispatchQueue.main.async {
                    self.notifications = fetchedNotifications
                    self.isLoading = false
                }
            } catch {
                print("Failed to fetch notifications: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
}

struct NotificationsView: View {
    @EnvironmentObject private var avm: AuthenticationVM // Assuming you have authentication setup
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Notifications...")
                } else if viewModel.notifications.isEmpty {
                    Text("No notifications yet.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(viewModel.notifications, id: \.notificationId) { notification in
                        NotificationRowView(notification: notification)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .onAppear {
                if let userId = avm.user?.uid {
                    viewModel.loadNotifications(uid: userId)
                }
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(notification.message ?? "Error")
                .font(.headline)
            Text(notification.timestamp, style: .relative)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AuthenticationVM()) // Provide AuthenticationVM for preview
}
