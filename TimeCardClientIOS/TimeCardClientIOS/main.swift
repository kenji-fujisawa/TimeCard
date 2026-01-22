//
//  main.swift
//  TimeCardClientIOS
//
//  Created by uhimania on 2025/12/30.
//

import Foundation

#if DEBUG
if CommandLine.arguments.contains("-UITests") {
    UITestApp.main()
} else {
    TimeCardClientIOSApp.main()
}
#else
TimeCardClientIOSApp.main()
#endif
