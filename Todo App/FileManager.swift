//
//  FileManager.swift
//  Todo App
//
//  Created by Citrus Furina on 4/20/25.
//
import Foundation
import SwiftUI

class TodoFileManager {
    static let shared = TodoFileManager()
    
    func exportData(todoItems: [TodoItem], categories: [String]) -> URL? {
        // 创建包含所有数据的结构
        let exportData = ExportData(todoItems: todoItems, categories: categories)
        
        // 编码为JSON
        guard let jsonData = try? JSONEncoder().encode(exportData) else {
            print("导出数据编码失败")
            return nil
        }
        
        // 创建临时文件
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let exportFileURL = temporaryDirectoryURL.appendingPathComponent("TodoExport_\(Date().timeIntervalSince1970).json")
        
        do {
            try jsonData.write(to: exportFileURL)
            return exportFileURL
        } catch {
            print("写入文件失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importData(from url: URL) -> ExportData? {
        do {
            let jsonData = try Data(contentsOf: url)
            let importedData = try JSONDecoder().decode(ExportData.self, from: jsonData)
            return importedData
        } catch {
            print("导入数据失败: \(error.localizedDescription)")
            return nil
        }
    }
}

// 用于导入导出的数据结构
struct ExportData: Codable {
    var todoItems: [TodoItem]
    var categories: [String]
    var exportDate: Date = Date()
    var appVersion: String = "1.0"
}
