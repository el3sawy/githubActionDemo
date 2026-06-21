//
//  UserViewModelTests.swift
//  CIDemo
//
//  Created by Ahmed on 15/06/2026.
//


import XCTest
@testable import CI_Dev

final class UserViewModelTests: XCTestCase {

    func testLoadUsersSuccess() async {
        // Given
        let repository = MockUserRepository()
        repository.users = [
            User(id: 1, name: "Ahmed"),
            User(id: 2, name: "Ali")
        ]

        let sut = await UserViewModel(repository: repository)

        // When
        await sut.loadUsers()
    }

    func testLoadUsersFailure() async {
        // Given
        let repository = MockUserRepository()
        repository.error = URLError(.notConnectedToInternet)

        let sut = await UserViewModel(repository: repository)

        // When
        await sut.loadUsers()

        // Then
        guard case .failed = await sut.state else {
            XCTFail("Expected failed state")
            return
        }
    }
    
    func test() {
        let repository = MockUserRepository()
        repository.users = [
            User(id: 1, name: "Ahmed"),
            User(id: 2, name: "Ali")
        ]

        let sut = UserViewModel(repository: repository)

        XCTAssertEqual(sut.getName(), "Ahmed")
    }
}
