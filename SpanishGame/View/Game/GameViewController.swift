//
//  ViewController.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 1.08.2022.
//

import UIKit

@MainActor
final class GameViewController: UIViewController {
    @IBOutlet private weak var loadingView: UIView!
    
    @IBOutlet private weak var correctAttemptLabel: UILabel!
    @IBOutlet private weak var wrongAttemptLabel: UILabel!
    
    @IBOutlet private weak var englishLabel: UILabel!
    @IBOutlet private weak var spanishLabel: UILabel!
    
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
            case .attemptResult:
                completeRound()
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
        let alert = UIAlertController(title: "Spanish Game", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [unowned self] _ in
            viewModel.startGame()
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { _ in
            exit(1)
        }))
        present(alert, animated: true)
    }
    
    private func showTranslation(english: String, spanish: String) {
        englishLabel.text = english
        spanishLabel.text = spanish
    }
    
    private func completeRound() {
        
        correctAttemptLabel.text = String(viewModel.correctAttemps)
        wrongAttemptLabel.text = String(viewModel.wrongAttemps)
        
        viewModel.fetchNextTranslation()
    }
    
    @IBAction private func chooseCorrect() {
        viewModel.validateAttempt(.correct)
    }
    
    @IBAction private func chooseWrong() {
        viewModel.validateAttempt(.wrong)
    }
}

