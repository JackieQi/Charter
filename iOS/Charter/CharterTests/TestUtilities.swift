//
//  TestUtilities.swift
//  Charter
//
//  Created by Matthew Palmer on 25/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import XCTest
import RealmSwift
@testable import Charter

let config = Realm.Configuration(path: "./test-realm", inMemoryIdentifier: "test-realm")

extension XCTestCase {
    func setUpTestRealm() -> Realm {
        let realm = try! Realm(configuration: config)
        
        try! realm.write {
            realm.deleteAll()
        }
        
        return realm
    }
    
    func testBundle() -> Bundle {
        return Bundle(for: type(of: self))
    }
    
    func dataForJSONFile(_ file: String) -> Data {
        let fileURL = testBundle().url(forResource: file, withExtension: "json")!
        return (try! Data(contentsOf: fileURL))
    }
}

class NSURLSessionDataTaskMock : URLSessionDataTask {
    var completionHandler: ((Data?, URLResponse?, NSError?) -> Void?)?
    var completionArguments: (data: Data?, response: URLResponse?, error: NSError?)
    
    override func resume() {
        completionHandler?(completionArguments.data, completionArguments.response, completionArguments.error)
    }
}

class NetworkingSessionMock: NetworkingSession {
    let dataTask: NSURLSessionDataTaskMock
    
    var assertionBlockForRequest: ((URLRequest) -> Void)?
    
    init(dataTask: NSURLSessionDataTaskMock) {
        self.dataTask = dataTask
    }
    
    func dataTaskWithRequest(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask {
        assertionBlockForRequest?(request)
        
        dataTask.completionHandler = completionHandler
        return dataTask
    }
}

class EmailThreadServiceMock: EmailThreadService {
    var cachedThreads: [Email] = []
    var uncachedThreads: [Email] = []
    
    var getCachedThreadsAssertionBlock: ((_ request: CachedThreadRequest) -> Void)?
    var refreshCacheAssertionBlock: ((_ request: EmailThreadRequest) -> Void)?
    var getUncachedThreadsAssertionBlock: ((_ request: UncachedThreadRequest) -> Void)?
    
    required init(cacheDataSource: EmailThreadCacheDataSource, networkDataSource: EmailThreadNetworkDataSource) {}
    
    func getCachedThreads(_ request: CachedThreadRequest, completion: ([Email]) -> Void) {
        getCachedThreadsAssertionBlock?(request: request)
        completion(cachedThreads)
    }
    
    func refreshCache(_ request: EmailThreadRequest, completion: ([Email]) -> Void) {
        refreshCacheAssertionBlock?(request: request)
        completion(uncachedThreads)
    }
    
    func getUncachedThreads(_ request: UncachedThreadRequest, completion: ([Email]) -> Void) {
        getUncachedThreadsAssertionBlock?(request: request)
        completion(uncachedThreads)
    }
}

class MockCacheDataSource: EmailThreadCacheDataSource {
    var emails: [Email] = []
    
    var cacheEmailAssertionBlock: ((_ emails: [NetworkEmail]) -> Void)?
    
    func getThreads(_ request: CachedThreadRequest, completion: ([Email]) -> Void) {
        completion(emails)
    }
    
    func cacheEmails(_ emails: [NetworkEmail]) throws {
        cacheEmailAssertionBlock?(emails: emails)
    }
}

class MockNetworkDataSource: EmailThreadNetworkDataSource {
    var emails: [NetworkEmail] = []
    
    func getThreads(_ request: UncachedThreadRequest, completion: ([NetworkEmail]) -> Void) {
        completion(emails)
    }
}

class MockApplication: Application {
    var networkActivityIndicatorToggleCount = 0
    
    var networkActivityIndicatorVisible: Bool = false {
        didSet {
            networkActivityIndicatorToggleCount += 1
        }
    }
}
