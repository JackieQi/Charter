//
//  Email.swift
//  Swift Mailing List
//
//  Created by Matthew Palmer on 4/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit
import RealmSwift

/// An email as a Realm object. The difference between `Email` and `NetworkEmail` is that `NetworkEmail` is much more inert--it does not exist in a Realm.
final class Email: Object {
    dynamic var id: String = ""
    dynamic var from: String = ""
    dynamic var mailingList: String = ""
    dynamic var content: String = ""
    dynamic var archiveURL: String?
    dynamic var date: Date = Date(timeIntervalSince1970: 1)
    dynamic var subject: String = ""
    dynamic var inReplyTo: Email?
    let references: List<Email> = List<Email>()
    let descendants: List<Email> = List<Email>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    var isComplete: Bool {
        // A 'complete' email is able to be used in the app and does not require retrieval from the backend.
        // Check a small subset of the properties necessary.
        return id.characters.count > 0
            && from.characters.count > 0
            && mailingList.characters.count > 0
            && content.characters.count > 0
            && subject.characters.count > 0
    }
}

enum EmailError: Swift.Error {
    case invalidDate
    case missingFields
    case invalidData
}

func ==(lhs: Email, rhs: Email) -> Bool {
    return lhs.id == rhs.id
}

extension Email {
    /// Construct an email from JSON data from `data`.
    class func createFromData(_ data: Data, inRealm realm: Realm) throws -> Email {
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else { throw EmailError.invalidData }
        
        let networkEmail = try NetworkEmail(fromDictionary: dictionary)
        
        return try Email.createFromNetworkEmail(networkEmail, inRealm: realm)
    }
    
    class func createFromNetworkEmail(_ networkEmail: NetworkEmail, inRealm realm: Realm) throws -> Email {
        let email = Email()
        email.id = networkEmail.id
        email.from = networkEmail.from
        email.date = networkEmail.date as Date
        email.subject = networkEmail.subject
        email.mailingList = networkEmail.mailingList
        email.content = networkEmail.content
        email.archiveURL = networkEmail.archiveURL
        
        func emailsToCreate(fromListOfIds ids: [String], inRealm realm: Realm) -> [Email] {
            let predicate = NSPredicate(format: "id IN %@", ids)
            let emailsInDatabase = Set<Email>(realm.objects(Email.self)
                .filter(predicate))
                .map { $0.id } + [networkEmail.id] // In case of self-references
            
            let emailsNotInDatabase = Set<String>(ids).subtracting(emailsInDatabase)
            
            let emailsToCreate: Array<Email> = (emailsNotInDatabase).map { id in
                let email = Email()
                email.id = id
                return email
            }
            
            return emailsToCreate
        }
        
        // Ensure that we only add 1 email with a given id
        var emailPool = [String: Email]()
        
        let descendantIDs = networkEmail.descendants
        let descendantsToCreate = emailsToCreate(fromListOfIds: descendantIDs, inRealm: realm)
        
        descendantsToCreate.forEach { emailPool[$0.id] = $0 }
        
        let referenceIDs = networkEmail.references
        let referencesToCreate = emailsToCreate(fromListOfIds: referenceIDs, inRealm: realm)
        
        referencesToCreate.forEach { emailPool[$0.id] = $0 }
        
        let inReplyTo = networkEmail.inReplyTo
        let inReplyToToCreate: [Email]
        if let inReplyTo = inReplyTo {
            inReplyToToCreate = emailsToCreate(fromListOfIds: [inReplyTo], inRealm: realm)
        } else {
            inReplyToToCreate = []
        }
        
        inReplyToToCreate.forEach { emailPool[$0.id] = $0 }
        
        // If any of the reference-type emails (i.e. incomplete emails) are trying to save over the top of the networkEmail, remove them from the pool.
        emailPool.removeValue(forKey: email.id)
        
        try realm.write {
            realm.add(email, update: true)
            realm.add(emailPool.values)
            
            func addEmailsWithIds(_ ids: [String], toList list: List<Email>) {
              
                let toAdd = realm.objects(Email.self).filter("id in %@", ids).map { $0 }
                list.append(objectsIn: toAdd)
            }
            
            addEmailsWithIds(descendantIDs, toList: email.descendants)
            addEmailsWithIds(referenceIDs, toList: email.references)
            
            if let inReplyTo = inReplyTo {
                email.inReplyTo = realm.objects(Email.self).filter("id == %@", inReplyTo).first
            }
        }

        return email
    }
}
