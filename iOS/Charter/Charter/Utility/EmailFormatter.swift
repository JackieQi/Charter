//
//  EmailFormatter.swift
//  Charter
//
//  Created by Matthew Palmer on 25/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

class EmailFormatter {
    fileprivate lazy var squareBracketAtStartRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "^\\[.*?\\]", options: .caseInsensitive)
    }()
    
    fileprivate lazy var withinParenthesesRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "\\((.*)\\)", options: .caseInsensitive)
    }()
    
    fileprivate lazy var sourceDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "ccc, dd MMM yyyy HH:mm:ss Z"
        df.timeZone = TimeZone(abbreviation: "GMT")
        return df
    }()
    
    fileprivate lazy var destinationDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        return df
    }()
    
    fileprivate lazy var footerBoilerPlateRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "_______________________________________________.*?$", options: NSRegularExpression.Options.dotMatchesLineSeparators)
    }()
    
    func formatContent(_ content: String) -> String {
        let noFooter = footerBoilerPlateRegex.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.characters.count), withTemplate: "")
        return noFooter
    }
    
    func formatSubject(_ subject: String) -> String {
        let noSquareBrackets = squareBracketAtStartRegex.stringByReplacingMatches(in: subject, options: [], range: NSMakeRange(0, subject.characters.count), withTemplate: "")
        return noSquareBrackets.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    fileprivate lazy var squareBracketForLabelRegex: NSRegularExpression = {
        // ^(\[[^\]]*\])+
        return try! NSRegularExpression(pattern: "^(\\[[^\\]]*\\]\\s*)+", options: [])
    }()
    
    fileprivate lazy var issueKeyRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "^([a-z]+-[0-9]+):?", options: .caseInsensitive)
    }()
    
    func labelsInSubject(_ string: String) -> [String] {
        let squareBrackets = squareBracketedLabels(string)
        if let issueKeys = issueKeyLabel(string) {
            return squareBrackets + [issueKeys]
        }
        
        return squareBrackets
    }
    
    fileprivate func squareBracketedLabels(_ string: String) -> [String] {
        let allLabelsStringMatch = squareBracketForLabelRegex.matches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
        guard let first = allLabelsStringMatch.first else {
            return []
        }
        
        return (string as NSString).substring(with: first.range)
            .components(separatedBy: "]")
            .map {
                $0.replacingOccurrences(of: "[", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }.filter { $0 != "" && $0 != "]" }
    }
    
    fileprivate func issueKeyLabel(_ string: String) -> String? {
        // Square bracketed labels conventionally precede issue key labels
        let noSquareBrackets = subjectByRemovingSquareBracketLabels(string)
        guard let match = issueKeyRegex.firstMatch(in: noSquareBrackets, options: [], range: NSMakeRange(0, noSquareBrackets.characters.count)) else { return nil }
        return (noSquareBrackets as NSString).substring(with: match.range).trimmingCharacters(in: CharacterSet(charactersIn: ":"))
    }
    
    func subjectByRemovingLabels(_ string: String) -> String {
        let noSquareBrackets = subjectByRemovingSquareBracketLabels(string)
        let withoutIssueKey = removeLeadingIssueKey(noSquareBrackets)
        return withoutIssueKey.characters.count == 0 ? noSquareBrackets : withoutIssueKey
    }
    
    fileprivate func subjectByRemovingSquareBracketLabels(_ string: String) -> String {
        let allLabelsStringMatch = squareBracketForLabelRegex.matches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
        guard let first = allLabelsStringMatch.first else {
            return string
        }
        
        return (string as NSString).replacingCharacters(in: first.range, with: "").trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    fileprivate func removeLeadingIssueKey(_ string: String) -> String {
        guard let issueKey = issueKeyRegex.firstMatch(in: string, options: [], range: NSMakeRange(0, string.characters.count)) else { return string }
        return (string as NSString).replacingCharacters(in: issueKey.range, with: "").trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func formatName(_ name: String) -> String {
        let firstMatch = withinParenthesesRegex.firstMatch(in: name, options: [], range: NSMakeRange(0, name.characters.count))
        let range = firstMatch?.rangeAt(1) ?? NSMakeRange(0, name.characters.count)
        let withinParens = (name as NSString).substring(with: range)
        
        // The server sometimes sends us ?utf-8? junk, and there's nothing we can do.
        let noJunk: String
        if withinParens.hasPrefix("=?utf-8?") {
            noJunk = ""
        } else {
            noJunk = withinParens
        }
        
        return noJunk
    }
    
    func dateStringToDate(_ date: String) -> Date? {
        return sourceDateFormatter.date(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        return destinationDateFormatter.string(from: date)
    }
}
