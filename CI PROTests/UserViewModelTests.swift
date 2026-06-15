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

        let sut = UserViewModel(repository: repository)

        // When
        await sut.loadUsers()

        // Then
        XCTAssertEqual(
            sut.state,
            .loaded([
                User(id: 1, name: "Ahmed"),
                User(id: 2, name: "Ali")
            ])
        )
    }

    func testLoadUsersFailure() async {
        // Given
        let repository = MockUserRepository()
        repository.error = URLError(.notConnectedToInternet)

        let sut = UserViewModel(repository: repository)

        // When
        await sut.loadUsers()

        // Then
        guard case .failed = sut.state else {
            XCTFail("Expected failed state")
            return
        }
    }

    func testLoadUsersChangesStateToLoading() async {
        // Given
        let repository = MockUserRepository()
        repository.users = [User(id: 1, name: "Ahmed")]

        let sut = UserViewModel(repository: repository)

        // When
        let task = Task {
            await sut.loadUsers()
        }

        // Then
        XCTAssertEqual(sut.state, .idle)

        await task.value
    }
}
