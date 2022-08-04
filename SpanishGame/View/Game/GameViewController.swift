//
//  ViewController.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 1.08.2022.
//

import UIKit

final class TranslationView: UIView {
    private static let transitionDuration: TimeInterval = 0.1
    private static let revealDuration: TimeInterval = 0.3
    
    @IBOutlet private weak var englishLabel: UILabel!
    @IBOutlet private weak var spanishLabel: UILabel!
    
    @IBOutlet private var spanishLabelInitialConstraint: NSLayoutConstraint!
    @IBOutlet private var spanishLabelStartConstraint: NSLayoutConstraint!
    @IBOutlet private var spanishLabelEndConstraint: NSLayoutConstraint!
    
    func showTranslation(english: String, spanish: String, duration: TimeInterval) {
        
        UIView.transition(with: self,
                          duration: Self.transitionDuration,
                          options: .transitionCrossDissolve) {
            self.clear()
            UIView.performWithoutAnimation {
                self.englishLabel.text = english
                self.spanishLabel.text = spanish

                self.spanishLabelStartConstraint.isActive = false
                self.spanishLabelEndConstraint.isActive = false
                self.spanishLabelInitialConstraint.isActive = true
                self.layoutIfNeeded()
            }
        }
        
        UIView.animate(withDuration: Self.revealDuration,
                       delay: 0,
                       options: .curveLinear) {
            self.spanishLabelInitialConstraint.isActive = false
            self.spanishLabelEndConstraint.isActive = false
            self.spanishLabelStartConstraint.isActive = true
            self.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: duration,
                       delay: Self.revealDuration - 0.15,
                       options: [.curveEaseIn, .beginFromCurrentState]) {
            self.spanishLabelInitialConstraint.isActive = false
            self.spanishLabelStartConstraint.isActive = false
            self.spanishLabelEndConstraint.isActive = true
            self.layoutIfNeeded()
        }
    }
    
    func clear() {
        spanishLabel.layer.removeAllAnimations()
        
        englishLabel.text = nil
        spanishLabel.text = nil
    }
}

@MainActor
final class GameViewController: UIViewController {
    @IBOutlet private weak var loadingView: UIView!
    
    @IBOutlet private weak var correctAttemptLabel: UILabel!
    @IBOutlet private weak var wrongAttemptLabel: UILabel!
    
    @IBOutlet private weak var translationView: TranslationView!
    
    let viewModel: GameViewModelInterface
    
    init?(coder: NSCoder, viewModel: GameViewModelInterface) {
        self.viewModel = viewModel
        super.init(coder: coder)
        
        bindViewModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel() {
        viewModel.updateHandler = { [unowned self] update in
            switch update {
            case .loading(let show):
                setLoading(show)
            case .loadFailed(let message):
                showGameLoadError(message: message)
            case .nextTranslation(let english, let spanish):
                showTranslation(english: english, spanish: spanish)
            case .scoreChanged:
                updateScore()
            case .gameOver:
                completeGame()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.startGame()
    }
    
    private func setLoading(_ isLoading: Bool) {
        view.isUserInteractionEnabled = !isLoading
        loadingView.isHidden = !isLoading
    }
    
    private func showGameLoadError(message: String) {
        showRestartAlert(message: message, startGameTitle: "Retry")
    }
    
    private func showTranslation(english: String, spanish: String) {
        translationView.showTranslation(english: english, spanish: spanish, duration: viewModel.roundDuration)
    }
    
    private func updateScore() {
        correctAttemptLabel.text = String(viewModel.correctAttemps)
        wrongAttemptLabel.text = String(viewModel.wrongAttemps)
    }
    
    private func completeGame() {
        translationView.clear()
        
        let message = """
        Game Over
        Correct attemps: \(viewModel.correctAttemps)
        Wrong attemps: \(viewModel.wrongAttemps)
        """
        
        showRestartAlert(message: message, startGameTitle: "New Game")
    }
    
    private func showRestartAlert(message: String, startGameTitle: String) {
        let alert = UIAlertController(title: "Spanish Game", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: startGameTitle, style: .default, handler: { [unowned self] _ in
            viewModel.startGame()
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { _ in
            exit(1)
        }))
        present(alert, animated: true)
    }
    
    @IBAction private func chooseCorrect() {
        viewModel.validateAttempt(.correct)
    }
    
    @IBAction private func chooseWrong() {
        viewModel.validateAttempt(.wrong)
    }
}

