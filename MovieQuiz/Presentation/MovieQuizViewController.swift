import UIKit

final class MovieQuizViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private var alertPresenter = AlertPresenter()
    private var statisticService: StatisticsServiceProtocol!
    private var presenter: MovieQuizPresenter!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        presenter = MovieQuizPresenter(viewController: self)
        
        statisticService = StatisticService()
        
        showLoadingIndicator()
        
        presenter.questionFactory?.loadData()
    }
    
    // MARK: - Private Game Methods
    
    // метод вывода на экран вопроса
   func show(quiz step: QuizStepViewModel) {
        noButton.isEnabled = true
        yesButton.isEnabled = true
        
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = nil
        
        imageView.image = UIImage(data: step.image) ?? UIImage()
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
        // метод, который меняет цвет рамки
    func showAnswerResult(isCorrect: Bool) {
        presenter.didAnswer(isCorrectAnswer: isCorrect)
        
        noButton.isEnabled = false
        yesButton.isEnabled = false
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.presenter.showNextQuestionOrResults()
        }
    }
    
    func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
                let text = "Вы ответили на \(presenter.correctAnswers) из 10, попробуйте ещё раз!"
                
                let viewModel = QuizResultsViewModel(
                    title: "Этот раунд окончен!",
                    text: text,
                    buttonText: "Сыграть ещё раз")
                    showResults(viewModel)
            } else {
                presenter.switchToNextQuestion()
                presenter.questionFactory?.requestNextQuestion()
            }
        }
        
            
    // приватный метод для показа результатов раунда квиза
   func showResults(_ result: QuizResultsViewModel) {
       
       if let statisticService = statisticService {
           statisticService.store(correct: presenter.correctAnswers, total: presenter.questionsAmount)
       }
        // получаем статистику
        let gamesCount = statisticService.gamesCount
        let bestGame = statisticService.bestGame
        let totalAccuracy = statisticService.totalAccuracy
        let bestGameDate = bestGame.date.dateTimeString
        
        let statisticsMessage = "Ваш результат: \(presenter.correctAnswers)/\(presenter.questionsAmount)\n" +
        "Количество сыгранных квизов: \(gamesCount)\n " +
        "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGameDate))\n" +
        "Средняя точность: \(String(format: "%.2f", totalAccuracy))%"
        
        let model = AlertModel(
            title: "Этот раунд окончен!",
            message: statisticsMessage,
            buttonText: result.buttonText) { [weak self] in
                guard let self = self else { return }
                
                self.noButton.isEnabled = true
                self.yesButton.isEnabled = true
    
                self.presenter.restartGame()
            }
        
        alertPresenter.show(in: self, model: model)
    }

    // MARK: - Utility Methods
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    func showNetworkErrorAlert(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз") { [weak self] in
                guard let self = self else { return }
                self.presenter.resetQuestionIndex()
                self.presenter.correctAnswers = 0
                
                self.noButton.isEnabled = false
                self.yesButton.isEnabled = false
                
                self.showLoadingIndicator()
                self.presenter.questionFactory?.loadData()
            }
        
        alertPresenter.show(in: self, model: model)
    }
      
    // MARK: - Actions
    
            // метод вызывается, когда пользователь нажимает на кнопку "Да"
        @IBAction private func yesButtonClicked(_ sender: UIButton) {
            presenter.yesButtonClicked()
            }
            
            // метод вызывается, когда пользователь нажимает на кнопку "Нет"
        @IBAction private func noButtonClicked(_ sender: UIButton) {
            presenter.noButtonClicked()
            }
        }
