import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    
    // переменная с индексом текущего вопроса
    private var currentQuestionIndex = 0
    // переменная со счётчиком правильных ответов
    private var correctAnswers = 0
    // общее количество вопросов для квиза
    private let questionsAmount: Int = 10
    // фабрика вопросов
    private var questionFactory: QuestionFactoryProtocol?
    // вопрос, который видит пользователь
    private var currentQuestion: QuizQuestion?
    
    private var alertPresenter = AlertPresenter()
    
    private var statisticService: StatisticsServiceProtocol!
    
    // метод конвертации, который принимает моковый вопрос и возвращает вью модель для экрана вопроса
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    // приватный метод вывода на экран вопроса, принимает на вход вью модель вопроса
    private func show(quiz step: QuizStepViewModel) {
        noButton.isEnabled = true
        yesButton.isEnabled = true
        
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = nil
        
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        questionFactory = QuestionFactory(delegate: self)
        
        questionFactory?.requestNextQuestion()
        
        statisticService = StatisticService()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        // проверка, что вопрос не nil
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }

        // приватный метод, который меняет цвет рамки
    private func showAnswerResult(isCorrect: Bool) {
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
            if currentQuestionIndex == questionsAmount - 1 {
                
            // сохраняем результат игры
            statisticService.store(correct: correctAnswers, total: questionsAmount)
                
                let viewModel = QuizResultsViewModel(
                    title: "",
                    text: "",
                    buttonText: "Сыграть ещё раз")
                show(quiz: viewModel)
                
            } else {
                currentQuestionIndex += 1
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
        
        let statisticsMessage = "Ваш результат: \(correctAnswers)/\(questionsAmount)\n" +
        "Количество сыгранных квизов: \(gamesCount)\n " +
        "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGameDate))\n" +
        "Средняя точность: \(String(format: "%.2f", totalAccuracy))%"
        
      let model = AlertModel(
        title: "Этот раунд окончен!",
        message: statisticsMessage,
        buttonText: result.buttonText) { [weak self] in
            guard let self = self else { return }
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.noButton.isEnabled = true
            self.yesButton.isEnabled = true
          
          self.questionFactory?.requestNextQuestion()
        }
        
      alertPresenter.show(in: self, model: model)
    }
            
            // метод вызывается, когда пользователь нажимает на кнопку "Да"
            @IBAction private func yesButtonClicked(_ sender: UIButton) {
                guard let currentQuestion = currentQuestion else {
                    return
                }
                let givenAnswer = true
                showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
            }
            
            // метод вызывается, когда пользователь нажимает на кнопку "Нет"
            @IBAction private func noButtonClicked(_ sender: UIButton) {
                guard let currentQuestion = currentQuestion else {
                    return
                }
                let givenAnswer = false
                showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
            }
        }
