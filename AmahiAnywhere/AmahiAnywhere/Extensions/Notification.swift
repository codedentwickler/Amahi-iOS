//
//  Notification.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 7/9/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let DownloadStarted = Notification.Name("DownloadStarted")
    static let DownloadCancelled = Notification.Name("DownloadCancelled")
    static let DownloadPaused = Notification.Name("DownloadPaused")
    static let DownloadCompletedSuccessfully = Notification.Name("DownloadCompletedSuccessfully")
    static let DownloadCompletedWithError = Notification.Name("DownloadCompletedWithError")
    
    static let LanTestPassed =  Notification.Name("LanTestPassed")
    static let LanTestFailed =  Notification.Name("LanTestFailed")
}
