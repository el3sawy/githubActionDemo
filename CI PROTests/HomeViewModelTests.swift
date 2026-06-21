//
//  HomeViewModelTests.swift
//  CI PROTests
//
//  Created by Ahmed on 21/06/2026.
//

import XCTest
@testable import CI_Dev

final class HomeViewModelTests: XCTestCase {
    
    func test_getData() {
        XCTAssertEqual(HomeViewModel().getData(), "Hello World")
    }
}
