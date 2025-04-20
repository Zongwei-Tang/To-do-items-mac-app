import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @State private var newItemTitle = ""
    @State private var isShowingTaskEditor = false
    @State private var selectedItem: TodoItem?
    @State private var isShowingAddCategory = false
    @State private var newCategoryName = ""
    @State private var isShowingAdvancedSearch = false
    
    init(viewModel: TodoListViewModel) {
            self._viewModel = ObservedObject(wrappedValue: viewModel)
        }
    
    var body: some View {
        NavigationView {
            // 侧边栏（分类列表）
            List {
                Text("全部")
                    .font(viewModel.selectedCategory == "全部" ? .headline : .body)
                    .onTapGesture {
                        viewModel.selectedCategory = "全部"
                    }
                
                Section(header:
                    HStack {
                        Text("分类")
                        Spacer()
                        Button(action: {
                            isShowingAddCategory = true
                        }) {
                            Image(systemName: "plus")
                                .font(.caption)
                        }
                    }
                ) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        HStack {
                            Text(category)
                                .font(viewModel.selectedCategory == category ? .headline : .body)
                            Spacer()
                            if category != "默认" {
                                Button(action: {
                                    viewModel.removeCategory(category)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedCategory = category
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 150, idealWidth: 150, maxWidth: 200)
            
            // 主内容区域
            VStack {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("搜索任务...", text: $viewModel.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            isShowingAdvancedSearch = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .popover(isPresented: $isShowingAdvancedSearch) {
                            SearchFilterView(viewModel: viewModel, isPresented: $isShowingAdvancedSearch)
                        }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 添加任务
                HStack {
                    TextField("添加新任务...", text: $newItemTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("", selection: Binding(
                        get: { viewModel.selectedCategory == "全部" ? "默认" : viewModel.selectedCategory },
                        set: { _ in }
                    )) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .frame(width: 100)
                    .disabled(true)
                    
                    Button(action: {
                        if !newItemTitle.isEmpty {
                            let category = viewModel.selectedCategory == "全部" ? "默认" : viewModel.selectedCategory
                            viewModel.addItem(title: newItemTitle, category: category)
                            newItemTitle = ""
                        }
                    }) {
                        Text("添加")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // 任务列表
                List {
                    ForEach(viewModel.filteredItems) { item in
                        TaskRow(item: item, viewModel: viewModel)
                            .contextMenu {
                                Button {
                                    viewModel.toggleItemCompletion(item: item)
                                } label: {
                                    Label(item.isCompleted ? "标记为未完成" : "标记为已完成", systemImage: item.isCompleted ? "circle" : "checkmark.circle")
                                }
                                
                                Button {
                                    selectedItem = item
                                    isShowingTaskEditor = true
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    if let index = viewModel.filteredItems.firstIndex(where: { $0.id == item.id }) {
                                        viewModel.deleteItem(at: IndexSet([index]))
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                selectedItem = item
                                isShowingTaskEditor = true
                            }
                    }
                    .onDelete(perform: viewModel.deleteItem)
                }
                
                Spacer()
                
                // 统计信息
                HStack {
                    Text("总计: \(viewModel.filteredItems.count) 个任务")
                    Spacer()
                    Text("已完成: \(viewModel.filteredItems.filter { $0.isCompleted }.count)")
                    Spacer()
                    Text("未完成: \(viewModel.filteredItems.filter { !$0.isCompleted }.count)")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
            }
            .navigationTitle("我的待办事项")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button("按名称排序") {
                            viewModel.todoItems.sort { $0.title < $1.title }
                        }
                        Button("按截止日期排序") {
                            viewModel.todoItems.sort { $0.dueDate < $1.dueDate }
                        }
                        Button("按优先级排序") {
                            viewModel.todoItems.sort { $0.priority.rawValue > $1.priority.rawValue }
                        }
                        Button("按完成状态排序") {
                            viewModel.todoItems.sort { !$0.isCompleted && $1.isCompleted }
                        }
                    } label: {
                        Label("排序", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $isShowingTaskEditor) {
                if let item = selectedItem {
                    TaskEditorView(item: item, viewModel: viewModel, categories: viewModel.categories)
                }
            }
            .alert("添加新分类", isPresented: $isShowingAddCategory) {
                TextField("分类名称", text: $newCategoryName)
                Button("取消", role: .cancel) {
                    newCategoryName = ""
                }
                Button("添加") {
                    if !newCategoryName.isEmpty {
                        viewModel.addCategory(newCategoryName)
                        newCategoryName = ""
                    }
                }
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: Notification.Name("NewTask"),
                object: nil,
                queue: .main) { _ in
                    newItemTitle = ""
                    // 这里添加逻辑使文本字段成为焦点
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

struct TaskRow: View {
    let item: TodoItem
    let viewModel: TodoListViewModel
    
    var body: some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isCompleted ? .green : .gray)
                .onTapGesture {
                    viewModel.toggleItemCompletion(item: item)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .fontWeight(.medium)
                
                HStack {
                    Label {
                        Text(item.dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(isDueDatePassed(item.dueDate) && !item.isCompleted ? .red : .gray)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    if !item.notes.isEmpty {
                        Image(systemName: "note.text")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(item.category)
                        .font(.caption)
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(item.priority.description)
                        .font(.caption)
                        .padding(4)
                        .background(Color(item.priority.color).opacity(0.3))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func isDueDatePassed(_ date: Date) -> Bool {
        return date < Date()
    }
}

struct TaskEditorView: View {
    let item: TodoItem
    let viewModel: TodoListViewModel
    let categories: [String]
    
    @State private var editedTitle: String
    @State private var editedDueDate: Date
    @State private var editedPriority: TodoItem.Priority
    @State private var editedCategory: String
    @State private var editedNotes: String
    @State private var editedRepeatOption: TodoItem.RepeatOption
    @Environment(\.presentationMode) var presentationMode
    
    init(item: TodoItem, viewModel: TodoListViewModel, categories: [String]) {
        self.item = item
        self.viewModel = viewModel
        self.categories = categories
        _editedTitle = State(initialValue: item.title)
        _editedDueDate = State(initialValue: item.dueDate)
        _editedPriority = State(initialValue: item.priority)
        _editedCategory = State(initialValue: item.category)
        _editedNotes = State(initialValue: item.notes)
        _editedRepeatOption = State(initialValue: item.repeatOption)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务详情")) {
                    TextField("任务名称", text: $editedTitle)
                    
                    DatePicker("截止日期", selection: $editedDueDate, displayedComponents: .date)
                    
                    Picker("优先级", selection: $editedPriority) {
                        ForEach(TodoItem.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .foregroundColor(Color(priority.color))
                                    .frame(width: 10, height: 10)
                                Text(priority.description)
                            }
                            .tag(priority)
                        }
                    }
                    
                    Picker("分类", selection: $editedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("重复", selection: $editedRepeatOption) {
                        ForEach(TodoItem.RepeatOption.allCases, id: \.self) { option in
                            Text(option.description).tag(option)
                        }
                    }
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("编辑任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.updateItem(
                            item: item,
                            newTitle: editedTitle,
                            newDueDate: editedDueDate,
                            newPriority: editedPriority,
                            newCategory: editedCategory,
                            newNotes: editedNotes,
                            newRepeatOption: editedRepeatOption
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: TodoListViewModel())
    }
}
