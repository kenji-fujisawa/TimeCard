//
//  TaskQueue.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/11/04.
//

import Foundation

class TaskQueue {
    private var queue: [() async -> Void] = []
    private var running: Bool = false
    
    static let shared = TaskQueue()
    
    func add(_ task: @escaping () async -> Void) {
        queue.append(task)
        
        if !running {
            runNext()
        }
    }
    
    private func runNext() {
        if queue.isEmpty {
            running = false
            return
        }
        
        running = true
        
        Task {
            let task = queue.removeFirst()
            await task()
            runNext()
        }
    }
}
