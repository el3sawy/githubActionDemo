//
//  MockUserRepository.swift
//  CIDemo
//
//  Created by Ahmed on 15/06/2026.
//


import Foundation
@testable import CI_Dev

final class MockUserRepository: UserRepositoryProtocol {

    var users: [User] = []
    var error: Error?

    func fetchUsers() async throws -> [User] {
        if let error {
            throw error
        }

        return users
    }
}
