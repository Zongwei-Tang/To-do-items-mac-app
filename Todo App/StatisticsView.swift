import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var viewModel: TodoListViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 任务完成率概览卡片
                CompletionRateCard(viewModel: viewModel)
                
                // 按分类统计
                CategoryStatsCard(viewModel: viewModel)
                
                // 按优先级统计
                PriorityStatsCard(viewModel: viewModel)
                
                // 按日期统计
                DateStatsCard(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("任务统计")
    }
}

struct CompletionRateCard: View {
    @ObservedObject var viewModel: TodoListViewModel
    
    var completionRate: Double {
        let totalTasks = viewModel.todoItems.count
        if totalTasks == 0 { return 0 }
        let completedTasks = viewModel.todoItems.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var body: some View {
        VStack {
            Text("完成率")
                .font(.headline)
            
            HStack(spacing: 20) {
                // 完成率仪表盘
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(completionRate))
                        .stroke(
                            completionRate > 0.7 ? Color.green :
                                completionRate > 0.4 ? Color.yellow : Color.red,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(completionRate * 100))%")
                        .font(.title2)
                        .bold()
                }
                
                // 状态统计
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("总任务:")
                        Text("\(viewModel.todoItems.count)")
                            .bold()
                    }
                    
                    HStack {
                        Text("已完成:")
                        Text("\(viewModel.todoItems.filter { $0.isCompleted }.count)")
                            .bold()
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("未完成:")
                        Text("\(viewModel.todoItems.filter { !$0.isCompleted }.count)")
                            .bold()
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("已逾期:")
                        Text("\(viewModel.todoItems.filter { !$0.isCompleted && $0.dueDate < Date() }.count)")
                            .bold()
                            .foregroundColor(.orange)
                    }
                }
                .padding(.leading)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct CategoryStatsCard: View {
    @ObservedObject var viewModel: TodoListViewModel
    
    var categoryData: [(category: String, count: Int)] {
        var result: [(String, Int)] = []
        
        for category in viewModel.categories {
            let count = viewModel.todoItems.filter { $0.category == category }.count
            if count > 0 {
                result.append((category, count))
            }
        }
        
        // 修复排序错误，使用明确的闭包参数类型
        return result.sorted { (item1: (String, Int), item2: (String, Int)) -> Bool in
            return item1.1 > item2.1
        }
    }
    
    var body: some View {
        VStack {
            Text("按分类统计")
                .font(.headline)
            
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(categoryData, id: \.category) { item in
                        BarMark(
                            x: .value("分类", item.category),
                            y: .value("任务数", item.count)
                        )
                        .foregroundStyle(Color.blue.gradient)
                    }
                }
                .frame(height: 200)
            } else {
                // 对于不支持 Chart 的系统，提供备选视图
                VStack {
                    ForEach(categoryData, id: \.category) { item in
                        HStack {
                            Text(item.category)
                                .frame(width: 100, alignment: .leading)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: CGFloat(item.count) * 20, height: 20)
                            
                            Text("\(item.count)")
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct PriorityStatsCard: View {
    @ObservedObject var viewModel: TodoListViewModel
    
    var priorityData: [(priority: String, count: Int, color: Color)] {
        let highCount = viewModel.todoItems.filter { $0.priority == .high }.count
        let normalCount = viewModel.todoItems.filter { $0.priority == .normal }.count
        let lowCount = viewModel.todoItems.filter { $0.priority == .low }.count
        
        return [
            ("高", highCount, Color.red),
            ("中", normalCount, Color.blue),
            ("低", lowCount, Color.gray)
        ]
    }
    
    var body: some View {
        VStack {
            Text("按优先级统计")
                .font(.headline)
            
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(priorityData, id: \.priority) { item in
                        SectorMark(
                            angle: .value("任务数", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(item.color)
                    }
                }
                .frame(height: 200)
            } else {
                // 对于不支持 Chart 的系统，提供备选视图
                HStack(spacing: 20) {
                    ForEach(priorityData, id: \.priority) { item in
                        VStack {
                            Text(item.priority)
                                .font(.caption)
                            
                            Text("\(item.count)")
                                .font(.title2)
                                .foregroundColor(item.color)
                            
                            Text("任务")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                        .background(item.color.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct DateStatsCard: View {
    @ObservedObject var viewModel: TodoListViewModel
    
    var dateData: [(date: Date, count: Int)] {
        // 获取未来7天的日期
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var result: [(Date, Int)] = []
        
        for day in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: day, to: today) else { continue }
            let count = viewModel.todoItems.filter { item in
                !item.isCompleted && calendar.isDate(calendar.startOfDay(for: item.dueDate), inSameDayAs: date)
            }.count
            
            result.append((date, count))
        }
        
        return result
    }
    
    var body: some View {
        VStack {
            Text("未来7天待办")
                .font(.headline)
            
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(dateData, id: \.date) { item in
                        LineMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("任务数", item.count)
                        )
                        .symbol(Circle())
                        .foregroundStyle(Color.green.gradient)
                    }
                    
                    ForEach(dateData, id: \.date) { item in
                        PointMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("任务数", item.count)
                        )
                        .annotation {
                            Text("\(item.count)")
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 200)
            } else {
                // 对于不支持 Chart 的系统，提供备选视图
                VStack {
                    ForEach(dateData, id: \.date) { item in
                        HStack {
                            Text(dateFormatter.string(from: item.date))
                                .frame(width: 100, alignment: .leading)
                            
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: CGFloat(item.count) * 20, height: 20)
                            
                            Text("\(item.count)")
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }
}
