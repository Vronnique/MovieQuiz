//
//  GameResultModel.swift
//  MovieQuiz
//

import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    // метод сравнения по количеству верных ответов
    func isBetterThan(_ another: GameResult) -> Bool {
        if correct > another.correct {
            return date > another.date
        }
        return correct > another.correct
    }
}
