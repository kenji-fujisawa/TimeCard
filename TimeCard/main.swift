//
//  main.swift
//  TimeCard
//
//  Created by uhimania on 2025/12/26.
//

import Foundation
import SwiftUI

#if DEBUG
if CommandLine.arguments.contains("-UITests") {
    UITestApp.main()
} else {
    TimeCardApp.main()
}
#else
TimeCardApp.main()
#endif
