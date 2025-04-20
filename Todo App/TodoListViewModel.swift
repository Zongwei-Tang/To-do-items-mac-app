import Foundation
import SwiftUI

class TodoListViewModel: ObservableObject {
    @Published var todoItems: [TodoItem] = [] {
        didSet {
            DataManager.shared.saveTodoItems(todoItems)
        }
    }
    
    @Published var categories: [String] = ["默认", "工作", "学习", "生活", "其他"] {
        didSet {
            DataManager.shared.saveCategories(categories)
        }
    }
    
    @Published var selectedCategory: String = "全部" {
        didSet {
            filterItems()
        }
    }
    
    @Published var filteredItems: [TodoItem] = []
    @Published var searchText: String = "" {
        didSet {
            filterItems()
        }
    }
    
    init() {
        todoItems = DataManager.shared.loadTodoItems()
        categories = DataManager.shared.loadCategories()
        filterItems()
    }
    
    func checkAndCreateRepeatingTasks() {
        var newTasks: [TodoItem] = []
        
        for item in todoItems {
            // 检查已完成的重复任务
            if item.isCompleted && item.repeatOption != .never {
                if let nextDueDate = item.nextDueDate() {
                    // 创建重复任务
                    var newItem = item
                    newItem.id = UUID() // 新的ID
                    newItem.isCompleted = false
                    newItem.dueDate = nextDueDate
                    newItem.lastCompletedDate = nil
                    
                    newTasks.append(newItem)
                }
            }
        }
        
        if !newTasks.isEmpty {
            todoItems.append(contentsOf: newTasks)
            filterItems()
        }
    }

    func loadData() {
        todoItems = DataManager.shared.loadTodoItems()
        categories = DataManager.shared.loadCategories()
        filterItems()
    }
    
    func filterItems() {
        if selectedCategory == "全部" {
            filteredItems = todoItems
        } else {
            filteredItems = todoItems.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            filteredItems = filteredItems.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func addItem(title: String, category: String = "默认") {
        var newItem = TodoItem(title: title)
        newItem.category = category
        todoItems.append(newItem)
        // 添加任务通知
        NotificationManager.shared.scheduleNotification(for: newItem)
        filterItems()
    }
    
    func deleteItem(at indexSet: IndexSet) {
        // 先移除通知
        for index in indexSet {
            if index < filteredItems.count {
                let item = filteredItems[index]
                NotificationManager.shared.removeNotification(for: item)
                if let originalIndex = todoItems.firstIndex(where: { $0.id == item.id }) {
                    todoItems.remove(at: originalIndex)
                }
            }
        }
        filterItems()
    }
    
    func toggleItemCompletion(item: TodoItem) {
        if let index = todoItems.firstIndex(where: { $0.id == item.id }) {
            todoItems[index].isCompleted.toggle()
            
            // 如果标记为完成，移除通知
            if todoItems[index].isCompleted {
                todoItems[index].lastCompletedDate = Date()
                            NotificationManager.shared.removeNotification(for: todoItems[index])
                            
                            // 如果是重复任务，创建下一个任务
                            if todoItems[index].repeatOption != .never, let nextDueDate = todoItems[index].nextDueDate() {
                                var newItem = todoItems[index]
                                newItem.id = UUID() // 新的ID
                                newItem.isCompleted = false
                                newItem.dueDate = nextDueDate
                                newItem.lastCompletedDate = nil
                                
                                todoItems.append(newItem)
                                
                                // 为新任务创建通知
                                NotificationManager.shared.scheduleNotification(for: newItem)
                            }
            } else {
                // 如果标记为未完成且截止日期未过，重新添加通知
                if todoItems[index].dueDate > Date() {
                    NotificationManager.shared.scheduleNotification(for: todoItems[index])
                }
            }
            filterItems()
        }
    }
    
    func updateItem(item: TodoItem, newTitle: String, newDueDate: Date, newPriority: TodoItem.Priority, newCategory: String, newNotes: String, newRepeatOption: TodoItem.RepeatOption) {
        if let index = todoItems.firstIndex(where: { $0.id == item.id }) {
            // 移除旧的通知
            NotificationManager.shared.removeNotification(for: todoItems[index])
            
            // 更新任务
            todoItems[index].title = newTitle
            todoItems[index].dueDate = newDueDate
            todoItems[index].priority = newPriority
            todoItems[index].category = newCategory
            todoItems[index].notes = newNotes
            todoItems[index].repeatOption = newRepeatOption
            
            // 如果未完成并且截止日期未过，重新添加通知
            if !todoItems[index].isCompleted && todoItems[index].dueDate > Date() {
                NotificationManager.shared.scheduleNotification(for: todoItems[index])
            }
            
            filterItems()
        }
    }
    
    func addCategory(_ category: String) {
        if !categories.contains(category) {
            categories.append(category)
        }
    }
    
    func removeCategory(_ category: String) {
        if category != "默认" {
            categories.removeAll { $0 == category }
            
            // 将该分类下的任务移到"默认"分类
            for i in 0..<todoItems.count {
                if todoItems[i].category == category {
                    todoItems[i].category = "默认"
                }
            }
            
            if selectedCategory == category {
                selectedCategory = "全部"
            }
        }
    }
}
