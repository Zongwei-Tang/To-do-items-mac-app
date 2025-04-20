import SwiftUI

struct SearchFilterView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @Binding var isPresented: Bool
    
    @State private var filterByStatus: FilterStatus = .all
    @State private var filterByPriority: TodoItem.Priority? = nil
    @State private var filterByDueDate: FilterDueDate = .all
    @State private var filterStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var filterEndDate: Date = Date()
    
    enum FilterStatus: String, CaseIterable {
        case all = "所有"
        case completed = "已完成"
        case notCompleted = "未完成"
        case overdue = "已逾期"
        
        var description: String { return rawValue }
    }
    
    enum FilterDueDate: String, CaseIterable {
        case all = "所有日期"
        case today = "今天"
        case tomorrow = "明天"
        case thisWeek = "本周"
        case nextWeek = "下周"
        case thisMonth = "本月"
        case custom = "自定义日期范围"
        
        var description: String { return rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("高级筛选")
                .font(.headline)
            
            Divider()
            
            Group {
                Text("按状态")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("状态", selection: $filterByStatus) {
                    ForEach(FilterStatus.allCases, id: \.self) { status in
                        Text(status.description).tag(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Group {
                Text("按优先级")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("不限") {
                        filterByPriority = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(filterByPriority == nil ? .blue : .secondary)
                    
                    ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                        Button(priority.description) {
                            filterByPriority = priority
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(filterByPriority == priority ? Color(priority.color) : .secondary)
                    }
                }
            }
            
            Group {
                Text("按截止日期")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("截止日期", selection: $filterByDueDate) {
                    ForEach(FilterDueDate.allCases, id: \.self) { dueDate in
                        Text(dueDate.description).tag(dueDate)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if filterByDueDate == .custom {
                    HStack {
                        DatePicker("从", selection: $filterStartDate, displayedComponents: .date)
                        DatePicker("到", selection: $filterEndDate, displayedComponents: .date)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("重置") {
                    resetFilters()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("应用筛选") {
                    applyFilters()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
    
    private func resetFilters() {
        filterByStatus = .all
        filterByPriority = nil
        filterByDueDate = .all
        filterStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        filterEndDate = Date()
    }
    
    private func applyFilters() {
        let calendar = Calendar.current
        
        viewModel.filteredItems = viewModel.todoItems.filter { item in
            var statusMatch = true
            var priorityMatch = true
            var dueDateMatch = true
            
            // 状态筛选
            switch filterByStatus {
            case .all:
                statusMatch = true
            case .completed:
                statusMatch = item.isCompleted
            case .notCompleted:
                statusMatch = !item.isCompleted
            case .overdue:
                statusMatch = !item.isCompleted && item.dueDate < Date()
            }
            
            // 优先级筛选
            if let priority = filterByPriority {
                priorityMatch = item.priority == priority
            }
            
            // 截止日期筛选
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: today)!
            let nextWeekEnd = calendar.date(byAdding: .day, value: 6, to: nextWeekStart)!
            
            let itemDate = calendar.startOfDay(for: item.dueDate)
            
            switch filterByDueDate {
            case .all:
                dueDateMatch = true
            case .today:
                dueDateMatch = calendar.isDate(itemDate, inSameDayAs: today)
            case .tomorrow:
                dueDateMatch = calendar.isDate(itemDate, inSameDayAs: tomorrow)
            case .thisWeek:
                let weekday = calendar.component(.weekday, from: today)
                let daysToAdd = weekday == 1 ? 0 : 8 - weekday // 如果今天是周日，本周结束日就是今天，否则计算到下周日
                let endOfWeek = calendar.date(byAdding: .day, value: daysToAdd, to: today)!
                dueDateMatch = itemDate >= today && itemDate <= endOfWeek
            case .nextWeek:
                dueDateMatch = itemDate >= nextWeekStart && itemDate <= nextWeekEnd
            case .thisMonth:
                let components = calendar.dateComponents([.year, .month], from: today)
                let startOfMonth = calendar.date(from: components)!
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
                dueDateMatch = itemDate >= today && itemDate <= endOfMonth
            case .custom:
                let startDate = calendar.startOfDay(for: filterStartDate)
                let endDate = calendar.startOfDay(for: filterEndDate)
                dueDateMatch = itemDate >= startDate && itemDate <= endDate
            }
            
            return statusMatch && priorityMatch && dueDateMatch
        }
        
        // 如果分类筛选也选择了
        if viewModel.selectedCategory != "全部" {
            viewModel.filteredItems = viewModel.filteredItems.filter { $0.category == viewModel.selectedCategory }
        }
        
        // 如果搜索框也有内容
        if !viewModel.searchText.isEmpty {
            viewModel.filteredItems = viewModel.filteredItems.filter { $0.title.localizedCaseInsensitiveContains(viewModel.searchText) }
        }
    }
}//
//  SearchFilterView.swift
//  Todo App
//
//  Created by Citrus Furina on 4/20/25.
//

