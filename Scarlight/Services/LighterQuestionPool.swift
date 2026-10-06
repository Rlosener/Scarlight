import Foundation

enum LighterQuestionPool {
    private static let filename = "lighter_questions"

    static func randomQuestion(excluding current: String? = nil) -> String {
        let pool = load()
        guard !pool.isEmpty else { return "Bugün en çok neye güldün?" }
        let trimmed = current?.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = pool.filter { $0 != trimmed }
        return (candidates.isEmpty ? pool : candidates).randomElement() ?? pool[0]
    }

    private static func load() -> [String] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let questions = try? JSONDecoder().decode([String].self, from: data) else {
            return fallback
        }
        return questions
    }

    private static let fallback: [String] = [
        "En son ne zaman utandın?",
        "En saçma alışkanlığın ne?",
        "30 saniye plank yap."
    ]
}
