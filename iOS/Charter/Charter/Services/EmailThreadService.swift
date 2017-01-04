//
//  ThreadService.swift
//  Charter
//
//  Created by Matthew Palmer on 20/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


protocol EmailThreadService {
    init(cacheDataSource: EmailThreadCacheDataSource, networkDataSource: EmailThreadNetworkDataSource)
    func getCachedThreads(_ request: CachedThreadRequest, completion: @escaping ([Email]) -> Void)
    func refreshCache(_ request: EmailThreadRequest, completion: @escaping ([Email]) -> Void)
    /// Prefer `refreshCache` over this method.
    func getUncachedThreads(_ request: UncachedThreadRequest, completion: @escaping ([Email]) -> Void)
}

protocol Application {
    var networkActivityIndicatorVisible: Bool { get set }
}

extension UIApplication: Application {}

class EmailThreadServiceImpl: EmailThreadService {
    let cacheDataSource: EmailThreadCacheDataSource
    let networkDataSource: EmailThreadNetworkDataSource
    
    var application: Application = UIApplication.shared
    
    required init(cacheDataSource: EmailThreadCacheDataSource, networkDataSource: EmailThreadNetworkDataSource) {
        self.cacheDataSource = cacheDataSource
        self.networkDataSource = networkDataSource
    }
    
    func getCachedThreads(_ request: CachedThreadRequest, completion: @escaping ([Email]) -> Void) {
        cacheDataSource.getThreads(request) {
            completion($0)
        }
    }
    
    func refreshCache(_ request: EmailThreadRequest, completion: @escaping ([Email]) -> Void) {
        application.networkActivityIndicatorVisible = true
        
        networkDataSource.getThreads(request) { networkThreads in
            DispatchQueue.main.async {
                self.application.networkActivityIndicatorVisible = false
                
                let _ = try? self.cacheDataSource.cacheEmails(networkThreads)
                
                self.cacheDataSource.getThreads(request) {
                    completion($0)
                }
            }
        }
    }
    
    func getUncachedThreads(_ request: UncachedThreadRequest, completion: @escaping ([Email]) -> Void) {
        application.networkActivityIndicatorVisible = true
        
        networkDataSource.getThreads(request) { (networkThreads) -> Void in
            DispatchQueue.main.async {
                self.application.networkActivityIndicatorVisible = false
                
                let _ = try? self.cacheDataSource.cacheEmails(networkThreads)
                
                // Create Id -> Index map so that we can sort later
                var order = [String: Int]()
                for i in 0..<networkThreads.count {
                    order[networkThreads[i].id] = i
                }
                
                let builder = EmailThreadRequestBuilder()
                builder.idIn = networkThreads.map { $0.id }
                
                self.cacheDataSource.getThreads(builder.build()) { (localEmails) in
                    completion(localEmails.sorted { order[$0.id] < order[$1.id] })
                }
            }
        }
    }
}
