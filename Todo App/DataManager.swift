import Foundation

class DataManager {
    static let shared = DataManager()
    private let todoItemsKey = "todoItems"
    private let categoriesKey = "categories"
    
    func saveTodoItems(_ items: [TodoItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: todoItemsKey)
        }
    }
    
    func loadTodoItems() -> [TodoItem] {
        if let data = UserDefaults.standard.data(forKey: todoItemsKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            return decoded
        }
        return []
    }
    
    func saveCategories(_ categories: [String]) {
        UserDefaults.standard.set(categories, forKey: categoriesKey)
    }
    
    func loadCategories() -> [String] {
        if let categories = UserDefaults.standard.stringArray(forKey: categoriesKey) {
            return categories
        }
        return ["默认", "工作", "学习", "生活", "其他"]
    }
}
