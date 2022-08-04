//
//  GameViewModelTests.swift
//  SpanishGameTests
//
//  Created by Murat Can Zahmakıran on 1.08.2022.
//

import XCTest
@testable import SpanishGame

private final class MockTranslationsInteractor: TranslationsInteractorInterface {
    
    var isInitializationSuccessful = false
    let defaultTranslation: Translation
    let fallbackTranslation: Translation
    
    init(defaultTranslation: Translation, fallbackTranslation: Translation) {
        self.defaultTranslation = defaultTranslation
        self.fallbackTranslation = fallbackTranslation
    }
    
    func initializeTranslations() async throws {
        guard isInitializationSuccessful else {
            throw NSError(domain: "", code: 0)
        }
    }
    
    func fetchRandomTranslation(excluding usedWords: [String]) -> Translation {
        if usedWords.contains(defaultTranslation.english) {
            return fallbackTranslation
        } else {
            return defaultTranslation
        }
    }
}

private final class MockRoundTimer: RoundTimerInterface {
    let fireHandler: () -> Void
    private(set) var startCount = 0
    private(set) var stopCount = 0
    
    static var fireEnabled: Bool = true
    
    init(interval: TimeInterval, fire fireHandler: @escaping () -> Void) {
        self.fireHandler = fireHandler
    }
    
    func start() {
        startCount += 1
        if Self.fireEnabled {
            fireHandler()
        }
        
    }
    
    func stop() {
        stopCount += 1
    }
}

class GameViewModelTests: XCTestCase {
    
    private var interactor: MockTranslationsInteractor!

    override func setUpWithError() throws {
        interactor = MockTranslationsInteractor(defaultTranslation: ("DefaultEnglish", "DefaultSpanish", true),
                                                    fallbackTranslation: ("FallbackEnglish", "FallbackSpanish", false))
    }

    override func tearDownWithError() throws {
        interactor = nil
    }

    @MainActor
    func testStartGame() {
        MockRoundTimer.fireEnabled = false
        interactor.isInitializationSuccessful = true
        
        let loadingExpectation = expectationLoading()
        let nextTranslationExpectation = expectationNextTranslation()
        let otherExpectation = expectationOther()
        
        let gameVM = GameViewModel<MockTranslationsInteractor, MockRoundTimer>(interactor: interactor)
        
        var loadings = [Bool]()
        gameVM.updateHandler = { update in
            switch update {
            case .loading(let show):
                loadings.append(show)
                loadingExpectation.fulfill()
            case .nextTranslation(let english, let spanish):
                XCTAssertEqual(english, "DefaultEnglish")
                XCTAssertEqual(spanish, "DefaultSpanish")
                nextTranslationExpectation.fulfill()
            default:
                otherExpectation.fulfill()
            }
        }
        gameVM.startGame()
        
        wait(for: [loadingExpectation, nextTranslationExpectation, otherExpectation], timeout: 0.1)
        XCTAssertEqual([true, false], loadings)
    }
    
    @MainActor
    func testStartGameFail() {
        MockRoundTimer.fireEnabled = false
        interactor.isInitializationSuccessful = false
        
        let loadingExpectation = expectationLoading()
        let loadFailedExpectation = expectationLoadFailed()
        let otherExpectation = expectationOther()
        
        let gameVM = GameViewModel<MockTranslationsInteractor, MockRoundTimer>(interactor: interactor)
        
        var loadings = [Bool]()
        gameVM.updateHandler = { update in
            switch update {
            case .loading(let show):
                loadings.append(show)
                loadingExpectation.fulfill()
            case .loadFailed(let message):
                XCTAssertEqual(message, "Translations could not be loaded.")
                loadFailedExpectation.fulfill()
            default:
                otherExpectation.fulfill()
            }
        }
        gameVM.startGame()
        
        wait(for: [loadingExpectation, loadFailedExpectation, otherExpectation], timeout: 0.1)
        XCTAssertEqual([true, false], loadings)
    }
    
    @MainActor
    func testValidateAttempt() {
        MockRoundTimer.fireEnabled = false
        interactor.isInitializationSuccessful = true
        
        func createTest(isSuccess: Bool) -> (handler: (GameViewModelUpdate) -> Void, expectations: [XCTestExpectation]) {
            let attemptResultExpectation = expectationAttemptResult()
            let otherExpectation = expectationOther()
            
            return ({ update in
                switch update {
                case .attemptResult(let succeeded):
                    XCTAssertEqual(succeeded, isSuccess)
                    attemptResultExpectation.fulfill()
                default:
                    otherExpectation.fulfill()
                }
            }, [attemptResultExpectation, otherExpectation])
        }
        
        let gameVM = GameViewModel<MockTranslationsInteractor, MockRoundTimer>(interactor: interactor)
        
        gameVM.fetchNextTranslation()
        let firstTest = createTest(isSuccess: true)
        gameVM.updateHandler = firstTest.handler
        gameVM.validateAttempt(.correct)
        wait(for: firstTest.expectations, timeout: 0)
        
        gameVM.fetchNextTranslation()
        let secondTest = createTest(isSuccess: false)
        gameVM.updateHandler = secondTest.handler
        gameVM.validateAttempt(.correct)
        wait(for: secondTest.expectations, timeout: 0)
    }
    
    @MainActor
    func testFetchNextTranslation() {
        MockRoundTimer.fireEnabled = false
        interactor.isInitializationSuccessful = true
        
        func createTest(expectedEnglish: String, expectedSpanish: String) -> (handler: (GameViewModelUpdate) -> Void, expectations: [XCTestExpectation]) {
            let nextTranslationExpectation = expectationNextTranslation()
            let otherExpectation = expectationOther()
            
            return ({ update in
                switch update {
                case .nextTranslation(let english, let spanish):
                    XCTAssertEqual(english, expectedEnglish)
                    XCTAssertEqual(spanish, expectedSpanish)
                    nextTranslationExpectation.fulfill()
                default:
                    otherExpectation.fulfill()
                }
            }, [nextTranslationExpectation, otherExpectation])
        }

        let gameVM = GameViewModel<MockTranslationsInteractor, MockRoundTimer>(interactor: interactor)
        
        let firstTest = createTest(expectedEnglish: "DefaultEnglish", expectedSpanish: "DefaultSpanish")
        gameVM.updateHandler = firstTest.handler
        gameVM.fetchNextTranslation()
        wait(for: firstTest.expectations, timeout: 0)
        
        let secondTest = createTest(expectedEnglish: "FallbackEnglish", expectedSpanish: "FallbackSpanish")
        gameVM.updateHandler = secondTest.handler
        gameVM.fetchNextTranslation()
        wait(for: secondTest.expectations, timeout: 0)
    }
    
    private func expectationLoading() -> XCTestExpectation {
        let expectation = expectation(description: "Update for loading. Should be emited twice.")
        expectation.expectedFulfillmentCount = 2
        return expectation
    }
    
    private func expectationLoadFailed() -> XCTestExpectation {
        return expectation(description: "Update for failed initialization")
    }
    
    private func expectationNextTranslation() -> XCTestExpectation {
        return expectation(description: "Update for translation.")
    }
    
    private func expectationAttemptResult() -> XCTestExpectation {
        return expectation(description: "Update for attempt result.")
    }
    
    private func expectationOther() -> XCTestExpectation {
        let expectation = expectation(description: "Other updates. Shouldn't be emited.")
        expectation.isInverted = true
        return expectation
    }
}
