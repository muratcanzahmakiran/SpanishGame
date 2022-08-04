//
//  GameViewModelTests.swift
//  SpanishGameTests
//
//  Created by Murat Can Zahmakıran on 1.08.2022.
//

import XCTest
@testable import SpanishGame

private final class MockTranslationsInteractor: TranslationsInteractorInterface {
    let defaultTranslation: Translation
    let fallbackTranslation: Translation
    
    var isInitializationSuccessful = true
    var skipInitialization = false
    
    private var _isTranslationsInitialized = false
    var isTranslationsInitialized: Bool { _isTranslationsInitialized || skipInitialization }
    private(set) var translationInitializationCount = 0
    
    init(defaultTranslation: Translation, fallbackTranslation: Translation) {
        self.defaultTranslation = defaultTranslation
        self.fallbackTranslation = fallbackTranslation
    }
    
    func initializeTranslations() async throws {
        translationInitializationCount += 1
        guard isInitializationSuccessful else {
            throw NSError(domain: "", code: 0)
        }
        _isTranslationsInitialized = true
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
        
        let initialloadingExpectation = expectationLoading()
        let initialNextTranslationExpectation = expectationNextTranslation()
        let initialScoreChangeExpectation = expectationScoreChanged(fulfillmentCount: 1)
        let initialOtherExpectation = expectationOther()
        
        func assertDefaultTranslation(english: String, spanish: String) -> Void {
            XCTAssertEqual(english, "DefaultEnglish")
            XCTAssertEqual(spanish, "DefaultSpanish")
        }
        
        let gameVM = GameViewModel<MockTranslationsInteractor, MockRoundTimer>(interactor: interactor)
        
        var loadings = [Bool]()
        gameVM.updateHandler = { update in
            switch update {
            case .loading(let show):
                loadings.append(show)
                initialloadingExpectation.fulfill()
            case .nextTranslation(let english, let spanish):
                assertDefaultTranslation(english: english, spanish: spanish)
                initialNextTranslationExpectation.fulfill()
            case .scoreChanged:
                initialScoreChangeExpectation.fulfill()
            default:
                initialOtherExpectation.fulfill()
            }
        }
        gameVM.startGame()
        
        wait(for: [initialloadingExpectation, initialNextTranslationExpectation, initialScoreChangeExpectation, initialOtherExpectation], timeout: 0.1)
        XCTAssertEqual([true, false], loadings)
        XCTAssertEqual(interactor.translationInitializationCount, 1)
        XCTAssertEqual(gameVM.correctAttemps, 0)
        XCTAssertEqual(gameVM.wrongAttemps, 0)
        
        let laterNextTranslationExpectation = expectationNextTranslation()
        let laterOtherExpectation = expectationOther()
        
        gameVM.updateHandler = { update in
            switch update {
            case .nextTranslation(let english, let spanish):
                assertDefaultTranslation(english: english, spanish: spanish)
                laterNextTranslationExpectation.fulfill()
            default:
                initialOtherExpectation.fulfill()
            }
        }
        gameVM.startGame()
                
        wait(for: [laterNextTranslationExpectation, laterOtherExpectation], timeout: 0.1)
        XCTAssertEqual(interactor.translationInitializationCount, 1)
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
        interactor.skipInitialization = true
        
        func createTest() -> (handler: (GameViewModelUpdate) -> Void, expectations: [XCTestExpectation]) {
            let scoreChangeExpectation = expectationScoreChanged(fulfillmentCount: 1)
            let otherExpectation = expectationOther()
            
            return ({ update in
                switch update {
                case .scoreChanged:
                    scoreChangeExpectation.fulfill()
                case .nextTranslation:
                    break
                default:
                    otherExpectation.fulfill()
                }
            }, [scoreChangeExpectation, otherExpectation])
        }
        
        let gameVM = GameViewModel<MockTranslationsInteractor, MockRoundTimer>(interactor: interactor)
        gameVM.startGame()
        
        let firstTest = createTest()
        gameVM.updateHandler = firstTest.handler
        gameVM.validateAttempt(.correct)
        wait(for: firstTest.expectations, timeout: 0)
        XCTAssertEqual(gameVM.correctAttemps, 1)
        XCTAssertEqual(gameVM.wrongAttemps, 0)
        
        let secondTest = createTest()
        gameVM.updateHandler = secondTest.handler
        gameVM.validateAttempt(.correct)
        wait(for: secondTest.expectations, timeout: 0)
        XCTAssertEqual(gameVM.correctAttemps, 1)
        XCTAssertEqual(gameVM.wrongAttemps, 1)
    }
    
    @MainActor
    func testFetchNextTranslation() {
        MockRoundTimer.fireEnabled = false
        interactor.skipInitialization = true
        
        func createTest(expectedEnglish: String, expectedSpanish: String) -> (handler: (GameViewModelUpdate) -> Void, expectations: [XCTestExpectation]) {
            let nextTranslationExpectation = expectationNextTranslation()
            let otherExpectation = expectationOther()
            
            return ({ update in
                switch update {
                case .nextTranslation(let english, let spanish):
                    XCTAssertEqual(english, expectedEnglish)
                    XCTAssertEqual(spanish, expectedSpanish)
                    nextTranslationExpectation.fulfill()
                case .scoreChanged:
                    break
                default:
                    otherExpectation.fulfill()
                }
            }, [nextTranslationExpectation, otherExpectation])
        }

        let gameVM = GameViewModel<MockTranslationsInteractor, MockRoundTimer>(interactor: interactor)
        
        let firstTest = createTest(expectedEnglish: "DefaultEnglish", expectedSpanish: "DefaultSpanish")
        gameVM.updateHandler = firstTest.handler
        gameVM.startGame()
        wait(for: firstTest.expectations, timeout: 0)
        
        let secondTest = createTest(expectedEnglish: "FallbackEnglish", expectedSpanish: "FallbackSpanish")
        gameVM.updateHandler = secondTest.handler
        gameVM.validateAttempt(.correct)
        wait(for: secondTest.expectations, timeout: 0)
    }
    
    @MainActor
    func testGameOver() {
        MockRoundTimer.fireEnabled = false
        interactor.skipInitialization = true
        
        let gameOverExpectation = expectationGameOver()
        let scoreChangedExpectation = expectationScoreChanged(fulfillmentCount: 4)
        let otherExpectation = expectationOther()
        
        let gameVM = GameViewModel<MockTranslationsInteractor, MockRoundTimer>(interactor: interactor)
        gameVM.startGame()
    
        gameVM.updateHandler = { update in
            switch update {
            case .nextTranslation:
                break
            case .gameOver:
                gameOverExpectation.fulfill()
            case .scoreChanged:
                scoreChangedExpectation.fulfill()
            default:
                otherExpectation.fulfill()
            }
        }
        
        gameVM.validateAttempt(.wrong)
        gameVM.validateAttempt(.wrong)
        gameVM.validateAttempt(.correct)
        gameVM.validateAttempt(.correct)
        wait(for: [scoreChangedExpectation, gameOverExpectation, otherExpectation], timeout: 0)
        XCTAssertEqual(gameVM.correctAttemps, 1)
        XCTAssertEqual(gameVM.wrongAttemps, 3)
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
    
    private func expectationScoreChanged(fulfillmentCount: Int) -> XCTestExpectation {
        let expectation = expectation(description: "Update for score change.")
        expectation.expectedFulfillmentCount = fulfillmentCount
        return expectation
    }
    
    private func expectationGameOver() -> XCTestExpectation {
        return expectation(description: "Update for game over.")
    }
    
    private func expectationOther() -> XCTestExpectation {
        let expectation = expectation(description: "Other updates. Shouldn't be emited.")
        expectation.isInverted = true
        return expectation
    }
}
