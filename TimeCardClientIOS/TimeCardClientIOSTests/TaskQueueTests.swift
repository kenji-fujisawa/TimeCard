//
//  TaskQueueTests.swift
//  TimeCardClientIOSTests
//
//  Created by uhimania on 2025/12/30.
//

import Testing

@testable import TimeCardClientIOS

struct TaskQueueTests {

    @Test func testRunTasksSequentially() async throws {
        var results: [String] = []
        
        TaskQueue.shared.add {
            try? await Task.sleep(for: .seconds(3))
            results.append("task1")
        }
        TaskQueue.shared.add {
            try? await Task.sleep(for: .seconds(1))
            results.append("task2")
        }
        
        try? await Task.sleep(for: .seconds(5))
        
        #expect(results.count == 2)
        #expect(results[0] == "task1")
        #expect(results[1] == "task2")
    }

}
