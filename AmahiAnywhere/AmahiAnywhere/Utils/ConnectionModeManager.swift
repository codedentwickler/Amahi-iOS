//
//  ConnectionModeManager.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 5/27/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Alamofire
import Reachability

class ConnectionModeManager {
    
    private let MinimumConnectionCheckPeriod = 3.0
    
    var lastCheckedAt: Date?
    var lastCheckPassed = true
    var currentMode: ConnectionMode?
    var currentConnectionInfo: ServerRoute?
    
    var reachability: Reachability?
    
    private init(){
        
        lastCheckedAt = nil
        currentMode = LocalStorage.shared.userConnectionPreference
    }
    
    static let shared = ConnectionModeManager()
    
    func setupReachability(_ hostName: String?) {
        if let hostName = hostName {
            reachability = Reachability(hostname: hostName)
        } else {
            reachability = Reachability()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reachabilityChanged(_:)),
            name: .reachabilityChanged,
            object: reachability
        )
    }
    
    private func reset() {
        lastCheckPassed = false
        lastCheckedAt = nil
    }
    
    private func startNotifier() {
        do {
            try reachability?.startNotifier()
        } catch {
            debugPrint("Unable to start notifier")
            return
        }
    }
    
    private func stopNotifier() {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
        reachability = nil
    }
    
    func testLocalAvailability() {
        
        debugPrint("testLocalAvailability was called")
        
        if lastCheckedAt != nil && fabs(Float(lastCheckedAt!.timeIntervalSinceNow)) <= Float(MinimumConnectionCheckPeriod)  {
                 debugPrint("local checking ratelimit exceeded. last cheked %.1fs ago", fabs(Float((lastCheckedAt?.timeIntervalSinceNow)!)))
            return
        }
        
        if currentMode != ConnectionMode.auto {
            return
        }
        
        let url = localAvailabilityURL()
        
        debugPrint("trying local reachability test with url: \(url!)")
        
        guard url != nil else {
            debugPrint("local availability URL is nil")
            return
        }
        
        // Make Request
        debugPrint("Making server availability request  \(url!)")

        Alamofire.SessionManager.default.requestWithoutCache(url!,
                                                             headers: ServerApi.shared?.getSessionHeader(),
                                                             timeoutInterval: 3.0)?
            .responseJSON(completionHandler: { (response) in

                switch response.result {
                    case .success:
                        if let data = response.result.value {
                            self.lastCheckPassed = data is [Any]
                        } else{
                            self.lastCheckPassed = false
                        }
                    
                    case .failure(let error):
                        self.lastCheckPassed = false
                        debugPrint("local availability check return with error \(error)")
                }
                
                self.lastCheckedAt = Date()
                debugPrint("Last check passed after testLocalAvailability completed \(self.lastCheckPassed)")
            })
    }
    
    func updateCurrentConnectionInfo(connectionInfo: ServerRoute) {
        
        currentConnectionInfo = connectionInfo
        
        if currentMode == ConnectionMode.remote {
            lastCheckPassed = false
            return
        }
        stopNotifier()
        setupReachability(currentConnectionInfo?.local_addr)
        startNotifier()
    }
    
    @objc private func reachabilityChanged(_ note: Notification) {
        let reachability = note.object as! Reachability
        reset()

        if reachability.connection != .none {
            testLocalAvailability()
        }
    }
    
    private func localAvailabilityURL() -> URL? {
        let baseURL = URL(string: currentConnectionInfo!.local_addr!)
        let finalURL = baseURL?.appendingPathComponent("/shares")
     
        return finalURL
    }
    
    private func isLocalModeAvailable() -> Bool {
        return lastCheckPassed
    }
    
    func currentConnectionBaseURL(serverRoute: ServerRoute) -> String? {
        
        if isLocalInUse() {
            debugPrint("Current mode in use \(currentMode!)")
            debugPrint("LAN mode in use")
            return serverRoute.local_addr
        }
        debugPrint("Remote mode in use")
        return serverRoute.relay_addr
    }
    
    public func isLocalInUse() -> Bool {
        if currentMode == ConnectionMode.auto {
            if isLocalModeAvailable() {
                return true
            } else {
                return false
            }
        }
        if currentMode == ConnectionMode.local {
            return true
        }
        return false
    }
    
    deinit {
        stopNotifier()
    }
}
