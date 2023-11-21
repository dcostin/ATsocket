//
//  Log.swift
//  GradePending
//
//  Created by Dan AppleDev on 5/10/20.
//  Copyright © 2021 Dan Costin. All rights reserved.
//

import Foundation

class Log {
    static let logQueue = DispatchQueue(label: "com.dancostin.sol.concurrency", qos: .userInitiated)
    
    static var errorLog = ""
    static var lastLog = ""
    
//    static func Log(_ format: String, _ args: CVarArg...) {
    static func Log(_ s: String, error : Bool = false, onlyOnce : Bool = false) {
        #if DEBUG
        
//        if !s.starts(with: "NMEA") { return }
        
        logQueue.async {
            if !(onlyOnce && s == lastLog) {
                NSLog("- %@", s)
            }
            lastLog = s
        }
        #endif
        
//        if error && (Settings.shared.settings.mappingOnOff["Log"]?.isOn ?? false) {
//            #if !DEBUG
//            NSLog("%@", s)
//            #endif
//            
//            logQueue.async {
//                if errorLog.count > 2000 {
//                    errorLog = String(errorLog.suffix(1000))
//                }
//                errorLog += ISO8601DateFormatter().string(from: Date()) + " \(s)\n"
//            }
//        }
    }
}
