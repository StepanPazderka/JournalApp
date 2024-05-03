//
//  JournalAppTests.swift
//  JournalAppTests
//
//  Created by Štěpán Pazderka on 05.03.2024.
//

import XCTest
import SwiftData

final class JournalAppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRemoveAllButThreeLastIdeas() async throws {
        let modelContainer = await DatabaseInteractorMock.mockContainer()
        let databaseInteractor = DatabaseInteractor(modelContainer: modelContainer)
        await databaseInteractor.keepLatest3TextIdeas()
        
        let ideas = try? await modelContainer.mainContext.fetch(FetchDescriptor<TextIdeaSwiftData>())
        print("Ideas count: \(ideas!.count)")
        assert(ideas!.count == 3)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

final class DatabaseInteractorTest: XCTestCase {
    
}
