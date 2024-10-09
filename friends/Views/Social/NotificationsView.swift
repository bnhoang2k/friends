//
//  NotificationsView.swift
//  friends
//
//  Created by Bryan Hoang on 10/7/24.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var nvm: NotificationViewModel
    var body: some View {
        NavigationStack {
            List(nvm.cachedNotifications, id: \.notificationId) {notification in
                NotificationRow(notification: notification)
            }
            .listStyle(.plain)
        }
    }
}

struct NotificationRow: View {
    let notification: Notification

    var body: some View {
        HStack {
            ImageView(urlString: notification.fromUserPP?.first)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(notification.message ?? "No message")
                    .font(.headline)
                Text(notification.timestamp, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Show different icons or actions depending on the type of notification
            if notification.type == .friendRequest {
                if notification.status == "pending" {
                    Button("Accept") {
                        // Action to accept the request
                    }
                } else {
                    Text("Accepted")
                }
            } else if notification.type == .hangoutRequest {
                // Handle hangout requests
                Text("Hangout request")
            } else if notification.type == .reminder {
                // Handle reminders
                Text("Reminder")
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environmentObject(AuthenticationVM())
            .environmentObject(NotificationViewModel())
    }
}
    
