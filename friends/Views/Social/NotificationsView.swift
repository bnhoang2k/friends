//
//  NotificationsView.swift
//  friends
//
//  Created by Bryan Hoang on 10/7/24.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var svm: SocialViewModel
    var body: some View {
        NavigationStack {
            List(svm.cachedNotifications, id: \.notificationId) {notification in
                NotificationRow(notification: notification)
                    .environmentObject(svm)
            }
            .listStyle(.plain)
        }
    }
}

struct NotificationRow: View {
    @EnvironmentObject private var svm: SocialViewModel
    @State private var showActionButtons: Bool = false
    var notification: Notification
    
    var body: some View {
        HStack {
            ImageView(urlString: notification.fromUserPP?.first)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(notification.message ?? "No message")
                    .font(.subheadline)
                Text(notification.timestamp, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action buttons for accepting or rejecting
            if notification.type == .friendRequest {
                if notification.status == .pending {
                    HStack(spacing: 20) {
                        Button {
                            // Action for accepting
                            Task {
                                try await svm.updateNotificationStatus(notification: notification,
                                                                       status: .accepted)
                                try await svm.handleFriendRequest(notification: notification, status: .accepted)
                            }
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.green)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button {
                            Task {
                                try await svm.updateNotificationStatus(notification: notification,
                                                                       status: .rejected)
                                try await svm.handleFriendRequest(notification: notification, status: .rejected)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                else if notification.status == .accepted {
                    Text("Accepted")
                        .bold()
                        .foregroundColor(.green)
                } 
                else if notification.status == .rejected {
                    Text("Rejected")
                        .bold()
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environmentObject(SocialViewModel())
    }
}
