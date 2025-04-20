import Foundation

class BackupManager {
    static let shared = BackupManager()
    private let backupFolder = "TodoAppBackups"
    private let maxBackups = 5
    
    func scheduleBackup() {
        // 每天创建一次备份
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            self.createBackup()
        }
    }
    
    func createBackup() {
        let todoItems = DataManager.shared.loadTodoItems()
        let categories = DataManager.shared.loadCategories()
        
        let exportData = ExportData(
            todoItems: todoItems,
            categories: categories
        )
        
        // 编码为JSON
        guard let jsonData = try? JSONEncoder().encode(exportData) else {
            print("备份数据编码失败")
            return
        }
        
        // 获取应用支持目录
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        
        // 创建备份文件夹
        let backupFolderURL = appSupportURL.appendingPathComponent(backupFolder, isDirectory: true)
        
        do {
            if !FileManager.default.fileExists(atPath: backupFolderURL.path) {
                try FileManager.default.createDirectory(at: backupFolderURL, withIntermediateDirectories: true)
            }
            
            // 创建备份文件名
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let dateString = dateFormatter.string(from: Date())
            
            let backupURL = backupFolderURL.appendingPathComponent("Backup_\(dateString).json")
            
            // 保存备份
            try jsonData.write(to: backupURL)
            
            // 清理旧备份
            cleanupOldBackups(in: backupFolderURL)
        } catch {
            print("备份失败: \(error.localizedDescription)")
        }
    }
    
    func listBackups() -> [URL] {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return []
        }
        
        let backupFolderURL = appSupportURL.appendingPathComponent(backupFolder)
        
        guard FileManager.default.fileExists(atPath: backupFolderURL.path) else {
            return []
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: backupFolderURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )
            
            // 按修改日期排序，最新的在前
            return fileURLs.filter { $0.pathExtension == "json" }.sorted { file1, file2 in
                let date1 = try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let date2 = try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                
                return date1 ?? Date.distantPast > date2 ?? Date.distantPast
            }
        } catch {
            print("获取备份列表失败: \(error.localizedDescription)")
            return []
        }
    }
    
    func restoreFromBackup(url: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            if let importedData = TodoFileManager.shared.importData(from: url) {
                DataManager.shared.saveTodoItems(importedData.todoItems)
                DataManager.shared.saveCategories(importedData.categories)
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    private func cleanupOldBackups(in folder: URL) {
        let backups = listBackups()
        
        if backups.count > maxBackups {
            // 删除旧备份
            for i in maxBackups..<backups.count {
                do {
                    try FileManager.default.removeItem(at: backups[i])
                } catch {
                    print("删除旧备份失败: \(error.localizedDescription)")
                }
            }
        }
    }
}//
//  BackupManager.swift
//  Todo App
//
//  Created by Citrus Furina on 4/20/25.
//

