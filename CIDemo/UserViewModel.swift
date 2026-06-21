//
//  User.swift
//  CIDemo
//
//  Created by Ahmed on 15/06/2026.
//


import Foundation

struct User: Equatable {
    let id: Int
    let name: String
}

protocol UserRepositoryProtocol {
    func fetchUsers() async throws -> [User]
}

final class UserViewModel {

    enum State: Equatable {
        case idle
        case loading
        case loaded([User])
        case failed(String)
    }

    private let repository: UserRepositoryProtocol

    private(set) var state: State = .idle

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func loadUsers() async {
        state = .loading

        do {
            let users = try await repository.fetchUsers()
            state = .loaded(users)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
    
    
    func getName() -> String {
        "Ahmed"
    }
}
