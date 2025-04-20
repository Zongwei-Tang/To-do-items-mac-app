//
//  NotificationManager.swift
//  Todo App
//
//  Created by Citrus Furina on 4/20/25.
//
import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限已获取")
            } else if let error = error {
                print("通知权限请求错误: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for todoItem: TodoItem) {
        let content = UNMutableNotificationContent()
        content.title = "任务提醒"
        content.body = todoItem.title
        content.sound = .default
        
        // 创建截止日期前1小时的提醒
        let calendar = Calendar.current
        
        // 如果截止日期已过，则不创建通知
        if todoItem.dueDate <= Date() {
            return
        }
        
        // 创建提醒时间：在截止日期前1小时
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: todoItem.dueDate)
        if let hour = dateComponents.hour {
            dateComponents.hour = hour - 1
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: todoItem.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    func removeNotification(for todoItem: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todoItem.id.uuidString])
    }
}
