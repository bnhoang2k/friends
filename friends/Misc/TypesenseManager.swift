//
//  TypesenseManager.swift
//  friends
//
//  Created by Bryan Hoang on 9/19/24.
//

import Foundation
import Typesense

@MainActor
final class TypesenseManager {
    static let shared = TypesenseManager()
    
    let node: Node = Node(host: "bryanswift.zapto.org", port: "80", nodeProtocol: "http")
    var config: Configuration? = nil
}
