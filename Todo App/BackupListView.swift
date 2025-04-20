import SwiftUI

struct BackupListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @State private var backups: [URL] = []
    @State private var selectedBackup: URL?
    @State private var isLoading = false
    @State private var showingRestoreAlert = false
    @State private var showingRestoreSuccessAlert = false
    @State private var showingRestoreFailureAlert = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("加载中...")
            } else {
                List(backups, id: \.absoluteString, selection: $selectedBackup) { backup in
                    HStack {
                        Text(backup.lastPathComponent)
                        Spacer()
                        if let date = try? backup.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                            Text(date, style: .date)
                            Text(date, style: .time)
                        }
                    }
                }
                .frame(minHeight: 300)
                
                HStack {
                    Button("刷新") {
                        loadBackups()
                    }
                    
                    Spacer()
                    
                    Button("创建备份") {
                        BackupManager.shared.createBackup()
                        loadBackups()
                    }
                    
                    Button("恢复备份") {
                        if selectedBackup != nil {
                            showingRestoreAlert = true
                        }
                    }
                    .disabled(selectedBackup == nil)
                    
                    Button("删除备份") {
                        if let url = selectedBackup {
                            do {
                                try FileManager.default.removeItem(at: url)
                                loadBackups()
                            } catch {
                                print("删除备份失败: \(error.localizedDescription)")
                            }
                        }
                    }
                    .disabled(selectedBackup == nil)
                }
                .padding()
            }
        }
        .padding()
        .navigationTitle("备份管理")
        .onAppear {
            loadBackups()
        }
        .alert("确认恢复", isPresented: $showingRestoreAlert) {
            Button("取消", role: .cancel) { }
            Button("恢复", role: .destructive) {
                if let url = selectedBackup {
                    isLoading = true
                    BackupManager.shared.restoreFromBackup(url: url) { success in
                        isLoading = false
                        if success {
                            viewModel.loadData()
                            showingRestoreSuccessAlert = true
                        } else {
                            showingRestoreFailureAlert = true
                        }
                    }
                }
            }
        } message: {
            Text("恢复备份将覆盖当前的所有数据，确定要继续吗？")
        }
        .alert("恢复成功", isPresented: $showingRestoreSuccessAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("备份数据已成功恢复。")
        }
        .alert("恢复失败", isPresented: $showingRestoreFailureAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("恢复备份数据失败，请检查备份文件是否有效。")
        }
    }
    
    private func loadBackups() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let backupList = BackupManager.shared.listBackups()
            
            DispatchQueue.main.async {
                backups = backupList
                isLoading = false
            }
        }
    }
}//
//  BackupListView.swift
//  Todo App
//
//  Created by Citrus Furina on 4/20/25.
//

