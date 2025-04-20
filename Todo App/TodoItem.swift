import Foundation

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date = Date()
    var priority: Priority = .normal
    var category: String = "默认"
    var notes: String = ""
    var repeatOption: RepeatOption = .never
    var lastCompletedDate: Date?
    
    enum Priority: Int, Codable, CaseIterable {
        case low = 0
        case normal = 1
        case high = 2
        
        var description: String {
            switch self {
            case .low: return "低"
            case .normal: return "中"
            case .high: return "高"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "gray"
            case .normal: return "blue"
            case .high: return "red"
            }
        }
    }
    
    enum RepeatOption: Int, Codable, CaseIterable {
        case never = 0
        case daily = 1
        case weekly = 2
        case monthly = 3
        case yearly = 4
        
        var description: String {
            switch self {
            case .never: return "不重复"
            case .daily: return "每天"
            case .weekly: return "每周"
            case .monthly: return "每月"
            case .yearly: return "每年"
            }
        }
    }
    
    // 获取下一个重复日期
    func nextDueDate() -> Date? {
        guard repeatOption != .never else { return nil }
        
        let calendar = Calendar.current
        let baseDate = lastCompletedDate ?? dueDate
        
        switch repeatOption {
        case .never:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: baseDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: baseDate)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: baseDate)
        }
    }
}
