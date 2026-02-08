import Foundation

final class MovieQuizPresenter: QuestionFactoryDelegate {
    var questionFactory: QuestionFactoryProtocol?
    weak var viewController: MovieQuizViewController?
    private var statisticService: StatisticsServiceProtocol!
    
    init(viewController: MovieQuizViewController){
        self.viewController = viewController
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    let questionsAmount: Int = 10
    var correctAnswers: Int = 0
    private var currentQuestionIndex: Int = 0
    var currentQuestion: QuizQuestion?
    
    // MARK: - QuestionFactoryDelegate
        
        func didLoadDataFromServer() {
            viewController?.hideLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
        
        func didFailToLoadData(with error: Error) {
            let message = error.localizedDescription
            viewController?.showNetworkErrorAlert(message: message)
        }
        
        func didReceiveNextQuestion(question: QuizQuestion?) {
            guard let question = question else {
                return
            }
            
            currentQuestion = question
            let viewModel = convert(model: question)
            DispatchQueue.main.async { [weak self] in
                self?.viewController?.show(quiz: viewModel)
            }
        }
        
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    // метод конвертации, который принимает вопрос и возвращает вью модель для экрана вопроса
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: model.image,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен",
                text: "",
                buttonText: "Сыграть ещё раз")
            viewController?.showResults(viewModel)
            
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        
        viewController?.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        
    }
    
    func didAnswer(isCorrectAnswer: Bool) {
        if isCorrectAnswer {
            correctAnswers += 1
        }
    }
}
