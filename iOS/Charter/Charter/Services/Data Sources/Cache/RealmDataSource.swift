//
//  RealmCacheDataSource.swift
//  Charter
//
//  Created by Matthew Palmer on 25/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import Foundation
import RealmSwift

class RealmDataSource: EmailThreadCacheDataSource {
    fileprivate let realm: Realm
    
    init(realm: Realm = try! Realm()) {
        self.realm = realm
    }
    
    func getThreads(_ request: CachedThreadRequest, completion: ([Email]) -> Void) {
        let realmQuery = request.realmQuery
        var results = realm.objects(Email.self).filter(realmQuery.predicate)
        
        if realmQuery.onlyComplete {
            results = results.filter("subject != '' AND from != '' AND mailingList != ''")
        }
        
        if let sort = realmQuery.sort {
            results = results.sorted(byProperty: sort.property, ascending: sort.ascending)
        }
        
        let start = realmQuery.pageSize * (realmQuery.page - 1)
        
        var end = start + realmQuery.pageSize
        if end > results.count {
            end = results.count
        }
        
        if results.count == 0 {
            completion([])
        } else {
            let slice = results[start..<end]
            completion(Array(slice))
        }
    }
    
    func cacheEmails(_ emails: [NetworkEmail]) throws {
        try emails.forEach { email in
            _ = try Email.createFromNetworkEmail(email, inRealm: realm)
        }
    }
}
