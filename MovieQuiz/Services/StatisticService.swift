import Foundation

// MARK: - StatisticService

final class StatisticService: StatisticServiceProtocol {
    
    // MARK: - Storage
    
    private let storage: UserDefaults = .standard
    
    // MARK: - Keys
    
    private enum Keys: String {
        case gamesCount
        case bestGameCorrect
        case bestGameTotal
        case bestGameDate
        case totalCorrectAnswers
    }
    
    // MARK: - Public Properties
    
    var gamesCount: Int {
        get {
            storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameResult {
        get {
            // читаем каждое поле GameResult
            let correct = storage.integer(forKey: Keys.bestGameCorrect.rawValue)
            
            let total = storage.integer(forKey: Keys.bestGameTotal.rawValue)
            
            let date = storage.object(forKey: Keys.bestGameDate.rawValue) as? Date ?? Date()
            
            return GameResult(correct: correct, total: total, date: date)
        }
        set {
            storage.set(newValue.correct, forKey: Keys.bestGameCorrect.rawValue)
            
            storage.set(newValue.total, forKey: Keys.bestGameTotal.rawValue)
            
            storage.set(newValue.date, forKey: Keys.bestGameDate.rawValue)
        }
    }
    
    // средняя точность
    var totalAccuracy: Double {
        if gamesCount == 0 {
            return 0.0
        }
        
        let totalQuestions = gamesCount * 10
        
        return Double(totalCorrectAnswers)/Double(totalQuestions) * 100
    }
    // MARK: - Private Properties
    
    private var totalCorrectAnswers: Int {
        get { storage.integer(forKey: Keys.totalCorrectAnswers.rawValue)
        }
        set { storage.set(newValue, forKey: Keys.totalCorrectAnswers.rawValue)
        }
    }
    
    // MARK: - Public Methods
    
    func store(correct count: Int, total amount: Int) {
        gamesCount += 1
        
        totalCorrectAnswers += count
        
        let currentGame = GameResult(correct: count, total: amount, date: Date())
        
        if gamesCount == 1 || currentGame.isBetterThan(bestGame) {
            bestGame = currentGame
        }
    }
}
