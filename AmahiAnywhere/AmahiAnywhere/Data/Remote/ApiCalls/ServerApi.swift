//
//  ServerApi.swift
//  AmahiAnywhere
//
//  Created by Chirag Maheshwari on 07/03/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation
import Alamofire
import EVReflection

class ServerApi {
    public static var shared: ServerApi?
    
    private var server: Server!
    private var serverRoute: ServerRoute?
    private var serverAddress: String?

    private init(_ server: Server) {
        self.server = server
    }

    public static func initialize(server: Server!) {
        self.shared = ServerApi(server)
    }
    
    func getServer() -> Server? {
        return self.server
    }
    
    private var isServerRouteLoaded : Bool {
        return serverRoute != nil
    }
    
    public func getSessionHeader() -> HTTPHeaders {
        return [ "Session": server.session_token! ]
    }
    
    func loadServerRoute(completion: @escaping (_ isLoadSuccessful: Bool) -> Void ) {
        
        func updateServerRoute(serverRouteResponse: ServerRoute?) {
            guard let serverRoute = serverRouteResponse else {
                completion(false)
                return
            }
//            serverRoute.local_addr = ApiConfig.LOCAL_BASE_URL

            self.serverRoute = serverRoute            
            configureConnection()
            completion(true)
        }
        
        Network.shared.request(ApiEndPoints.getServerRoute(), headers: getSessionHeader(), completion: updateServerRoute)
    }
    
    func configureConnection() {
        
        if !isServerRouteLoaded {
            debugPrint("Route is not loaded when configureConnection was called")
            return
        }
        
        let connectionMode = LocalStorage.shared.userConnectionPreference
        ConnectionModeManager.shared.currentMode = connectionMode
        
        if connectionMode == .local {
            serverAddress = serverRoute?.local_addr
        } else if connectionMode == .remote {
            serverAddress = serverRoute?.relay_addr
        } else if connectionMode == .auto {
            startServerConnectionDetection()
        }
    }
    
    func startServerConnectionDetection() {
        ConnectionModeManager.shared.updateCurrentConnectionInfo(connectionInfo: serverRoute!)
        ConnectionModeManager.shared.testLocalAvailability()
    }
    
    var isConnected: Bool  {
        return server != nil && serverRoute != nil && serverAddress != nil
    }
    
    func getShares(completion: @escaping (_ serverShares: [ServerShare]?) -> Void ) {
        if !isServerRouteLoaded {
            return
        }

        serverAddress = ConnectionModeManager.shared.currentConnectionBaseURL(serverRoute: serverRoute!)
        Network.shared.request(ApiEndPoints.getServerShares(serverAddress), headers: getSessionHeader(), completion: completion)
    }
    
    public func getFiles(share: ServerShare, directory: ServerFile? = nil, completion: @escaping (_ serverFiles: [ServerFile]?) -> Void ) {
        
        func updateFiles(serverFiles: [ServerFile]?) {
            guard let files = serverFiles else {
                completion(serverFiles)
                return
            }
            for file in files {
                file.parentFile = directory
                file.parentShare = share
            }
            completion(files)
        }
        
        var params: Parameters = ["s": share.name!]
        if directory != nil {
            params["p"] = directory?.getPath()
        }
        
        Network.shared.request(ApiEndPoints.getServerFiles(serverAddress), parameters: params, headers: getSessionHeader(), completion: updateFiles)
    }
    
    public func getFileUri(_ file: ServerFile) -> URL {
        var components = URLComponents(string: serverAddress!)!
        components.path = "/files"
        components.queryItems = [
            URLQueryItem(name: "s", value: file.parentShare!.name),
            URLQueryItem(name: "p", value: file.getPath()),
            URLQueryItem(name: "mtime", value: String(file.getLastModifiedEpoch())),
            URLQueryItem(name: "session", value: server.session_token)
        ]
        return try! components.asURL()
    }
    
}
