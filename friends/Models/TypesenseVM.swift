//
//  TypesenseVM.swift
//  friends
//
//  Created by Bryan Hoang on 10/7/24.
//

import Foundation
import Typesense

@MainActor
final class TypesenseVM: ObservableObject {
    @Published private var client: Client?
    
    @Published var searchResults: [DBUser] = [] // To store the search results
    @Published var searchText: String = ""
}

extension TypesenseVM {
    // https://github.com/typesense/typesense-swift
    func createClient() async throws {
        // Fetch API Key
        let apiKey = try await TypesenseManager.shared.fetchAPIKey()
        // Create the nodes
        var nodes: [Node] = []
        let node1 = Node(host: "w9p3k2cytodfqxnep-1.a1.typesense.net",
                         port: "443",
                         nodeProtocol: "https")
        let node2 = Node(host: "w9p3k2cytodfqxnep-2.a1.typesense.net",
                         port: "443",
                         nodeProtocol: "https")
        let node3 = Node(host: "w9p3k2cytodfqxnep-3.a1.typesense.net",
                         port: "443",
                         nodeProtocol: "https")
        
        nodes.append(node1)
        nodes.append(node2)
        nodes.append(node3)
        
        // Create the configuration
        let config = Configuration(nodes: nodes, apiKey: apiKey, sendApiKeyAsQueryParam: true)
        
        // Create typesense client
        self.client = Client(config: config)
    }
}

extension TypesenseVM {
    // Search users based on the current query
    func searchUsers(query: String, excludedName: String? = nil, page: Int = 1, perPage: Int = 50) async {
        guard let client = self.client, !query.isEmpty else {
            searchResults = [] // Clear the results when query is empty
            return
        }
        
        let searchParameters = SearchParameters(
            q: query,
            queryBy: "full_name,username",
            filterBy: "username:!=\(excludedName ?? "")",
            page: page,
            perPage: perPage
        )
        
        do {
            let (data, _) = try await client.collection(name: "users").documents().search(searchParameters, for: DBUser.self)
            if let res = data {
                self.searchResults = res.hits?.map { $0.document } as! [DBUser]
            } else {
                self.searchResults = []
            }
        } catch {
            print("Error searching for users: \(error.localizedDescription)")
            self.searchResults = []
        }
    }
}
