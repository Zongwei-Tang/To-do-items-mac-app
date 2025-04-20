import SwiftUI

@main
struct TodoApp: App {
    @StateObject private var viewModel = TodoListViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    // 初始化备份管理
                    BackupManager.shared.scheduleBackup()
                    
                    // 每次启动时检查是否需要创建重复任务
                    viewModel.checkAndCreateRepeatingTasks()
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("新建任务") {
                    NotificationCenter.default.post(name: Notification.Name("NewTask"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Divider()
                
                Button("导出数据...") {
                    exportData()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                
                Button("导入数据...") {
                    importData()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
            
            CommandMenu("视图") {
                Button("统计分析") {
                    openStatisticsWindow()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Button("备份管理") {
                    openBackupManager()
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
            }
        }
        
        // 统计分析窗口
        WindowGroup("任务统计分析") {
            StatisticsView(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultPosition(.center)
        
        // 备份管理窗口
        WindowGroup("备份管理") {
            BackupListView(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultPosition(.center)
    }
    
    private func exportData() {
        if let url = TodoFileManager.shared.exportData(
            todoItems: viewModel.todoItems,
            categories: viewModel.categories
        ) {
            // 打开保存对话框
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "TodoApp_Export_\(Date().formatted(.dateTime.year().month().day()))"
            
            savePanel.begin { result in
                if result == .OK, let saveURL = savePanel.url {
                    do {
                        let data = try Data(contentsOf: url)
                        try data.write(to: saveURL)
                    } catch {
                        print("保存导出数据失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func importData() {
        // 打开文件对话框
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { result in
            if result == .OK, let fileURL = openPanel.url {
                if let importedData = TodoFileManager.shared.importData(from: fileURL) {
                    viewModel.todoItems = importedData.todoItems
                    viewModel.categories = importedData.categories
                    viewModel.filterItems()
                }
            }
        }
    }
    
    private func openStatisticsWindow() {
        NSApp.sendAction(Selector(("showWindow:")), to: nil, from: "任务统计分析")
    }
    
    private func openBackupManager() {
        NSApp.sendAction(Selector(("showWindow:")), to: nil, from: "备份管理")
    }
}
