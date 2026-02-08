import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private var presenter: MovieQuizPresenter!
    private var alertPresenter = AlertPresenter()
    private var statisticService: StatisticServiceProtocol!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        presenter = MovieQuizPresenter(viewController: self)
        
        statisticService = StatisticService()
        
        showLoadingIndicator()
        
        presenter.questionFactory?.loadData()
    }
    
    // MARK: - Quiz UI Methods
    
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
            
    // метод для показа результатов раунда квиза
   func showResults(_ result: QuizResultsViewModel) {
       let message = presenter.makeResultsMessage()
       
       if let statisticService = statisticService {
           statisticService.store(correct: presenter.correctAnswers, total: presenter.questionsAmount)
       }
        
        let model = AlertModel(
            title: "Этот раунд окончен!",
            message: message,
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
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        noButton.isEnabled = false
        yesButton.isEnabled = false
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
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
