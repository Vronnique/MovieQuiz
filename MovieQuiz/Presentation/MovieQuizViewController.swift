import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter = AlertPresenter()
    private var statisticService: StatisticsServiceProtocol!
    private let presenter = MovieQuizPresenter()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        presenter.viewController = self
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        
        statisticService = StatisticService()
        
        showLoadingIndicator()
        
        questionFactory?.loadData()
    }
    
    
    // MARK: - QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkErrorAlert(message: error.localizedDescription)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        // проверка, что вопрос не nil
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }

    // MARK: - Private Game Methods
    
    // метод вывода на экран вопроса, принимает на вход вью модель вопроса
    private func show(quiz step: QuizStepViewModel) {
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
            if isCorrect {
                correctAnswers += 1
            }
            noButton.isEnabled = false
            yesButton.isEnabled = false
            
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = 8
            imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.showNextQuestionOrResults()
            }
        }
        
        // приватный метод, который содержит логику перехода в один из сценариев
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
                
            // сохраняем результат игры
                statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
                
                let viewModel = QuizResultsViewModel(
                    title: "",
                    text: "",
                    buttonText: "Сыграть ещё раз")
                show(quiz: viewModel)
                
            } else {
                presenter.switchToNextQuestion()
                questionFactory?.requestNextQuestion()
            }
        }
            
    // приватный метод для показа результатов раунда квиза
    private func show(quiz result: QuizResultsViewModel) {
        // получаем статистику
        let gamesCount = statisticService.gamesCount
        let bestGame = statisticService.bestGame
        let totalAccuracy = statisticService.totalAccuracy
        let bestGameDate = bestGame.date.dateTimeString
        
        let statisticsMessage = "Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)\n" +
        "Количество сыгранных квизов: \(gamesCount)\n " +
        "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGameDate))\n" +
        "Средняя точность: \(String(format: "%.2f", totalAccuracy))%"
        
        let model = AlertModel(
            title: "Этот раунд окончен!",
            message: statisticsMessage,
            buttonText: result.buttonText) { [weak self] in
                guard let self = self else { return }
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                
                self.noButton.isEnabled = true
                self.yesButton.isEnabled = true
    
                self.questionFactory?.requestNextQuestion()
            }
        
        alertPresenter.show(in: self, model: model)
    }

    // MARK: - Utility Methods
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func showNetworkErrorAlert(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз") { [weak self] in
                guard let self = self else { return }
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                
                self.noButton.isEnabled = false
                self.yesButton.isEnabled = false
                
                self.showLoadingIndicator()
                self.questionFactory?.loadData()
            }
        
        alertPresenter.show(in: self, model: model)
    }
      
    // MARK: - Actions
    
            // метод вызывается, когда пользователь нажимает на кнопку "Да"
        @IBAction private func yesButtonClicked(_ sender: UIButton) {
            presenter.currentQuestion = currentQuestion
            presenter.yesButtonClicked()
            }
            
            // метод вызывается, когда пользователь нажимает на кнопку "Нет"
        @IBAction private func noButtonClicked(_ sender: UIButton) {
            presenter.currentQuestion = currentQuestion
            presenter.noButtonClicked()
            }
        }
