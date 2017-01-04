//
//  NetworkEmail.swift
//  Charter
//
//  Created by Matthew Palmer on 25/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

struct NetworkEmail {
    let id: String
    let from: String
    let mailingList: String
    let content: String
    let archiveURL: String?
    let date: Date
    let subject: String
    let inReplyTo: String?
    let references: [String]
    let descendants: [String]
}

enum NetworkEmailError: Error {
    case missingRequiredField
    case invalidDate
    case invalidJSON
}

extension NetworkEmail {
    init(fromDictionary: NSDictionary) throws {
        let d = fromDictionary
        
        guard let
            id = d["_id"] as? String,
            let from = d["from"] as? String,
            let mailingList = d["mailingList"] as? String,
            let content = d["content"] as? String,
            let subject = d["subject"] as? String
            else {
                throw NetworkEmailError.missingRequiredField
        }
        
        let references = ((d["references"] as? [String]) ?? []).filter { !$0.isEmpty }
        let descendants = ((d["descendants"] as? [String]) ?? []).filter { !$0.isEmpty }
        let inReplyTo = d["inReplyTo"] as? String
        let archiveURL = d["archiveURL"] as? String
        
        guard let dateDict = d["date"] as? NSDictionary, let interval = dateDict["$date"] as? Double else {
            throw NetworkEmailError.invalidDate
        }
        let date = Date(timeIntervalSince1970: interval / 1000)
        
        self.init(id: id, from: from, mailingList: mailingList, content: content, archiveURL: archiveURL, date: date, subject: subject, inReplyTo: inReplyTo, references: references, descendants: descendants)
    }
    
    static func listFromJSONData(_ data: Data) throws -> [NetworkEmail] {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let dictionary = json as? NSDictionary,
            let embedded = dictionary["_embedded"] as? NSDictionary,
            let docs = embedded["rh:doc"] as? Array<NSDictionary> else { throw NetworkEmailError.invalidJSON }
        
        return docs.map { try? NetworkEmail(fromDictionary: $0) }.flatMap { $0 }
    }
}
