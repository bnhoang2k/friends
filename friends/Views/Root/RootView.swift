//
//  RootView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI
import Kingfisher

@MainActor
class userLoaded: ObservableObject {
    
    static let shared = userLoaded()
    private init() {}
    
    var loadingComplete: Bool {return userInformationLoaded && picturesLoaded}
    @Published var userInformationLoaded: Bool = false
    @Published var picturesLoaded: Bool = false
    @Published var cachedImage: UIImage? = nil // Store the cached image
    
    func preloadImage(urlString: String?) async {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return
        }
        
        if KingfisherManager.shared.cache.isCached(forKey: urlString) {
            self.picturesLoaded = true
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
            case .success(_):
                self.picturesLoaded = true
            case .failure(_):
                self.picturesLoaded = false
            }
        }
    }
    
    func configureForPreviews(userInformationLoaded: Bool, picturesLoaded: Bool) {
        self.userInformationLoaded = userInformationLoaded
        self.picturesLoaded = picturesLoaded
    }
}

struct RootView: View {
    
    @StateObject var avm: AuthenticationVM = AuthenticationVM()
    @ObservedObject var isLoading = userLoaded.shared
    
    var body: some View {
        VStack {
            if !isLoading.loadingComplete {
                ProgressView()
                    .task {
                        do {
                            try await avm.loadCurrentUser()
                            avm.getAuthProviders()
                            avm.showSignInView = (avm.user == nil)
                            await userLoaded.shared.preloadImage(urlString: avm.user?.photoURL!)
                        } catch {
                            print("RootView Error Loading User: \(error)")
                        }
                        isLoading.userInformationLoaded = true
                    }
            }
            else {
                if avm.showSignInView {
                    NavigationStack {
                        SignInView(showSignInView: $avm.showSignInView)
                            .environmentObject(avm)
                    }
                }
                else if avm.showGetInformationView {
                    GetInformationView()
                        .environmentObject(avm)
                }
                else {
                    NavigationStack {
                        MainView()
                            .environmentObject(avm)
                    }
                }
            }
        }
        .animation(.easeIn, value: avm.showSignInView)
    }
}

extension RootView {
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(avm: AuthenticationVM())
            .onAppear {
                userLoaded.shared.configureForPreviews(userInformationLoaded: true, picturesLoaded: true)
            }
    }
}
