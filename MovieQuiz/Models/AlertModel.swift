import Foundation
/// модель финального алерта
struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
}
