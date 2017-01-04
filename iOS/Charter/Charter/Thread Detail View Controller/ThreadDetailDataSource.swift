//
//  ThreadDetailDataSource.swift
//  Charter
//
//  Created by Matthew Palmer on 27/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

/// Used to redirect the UITableViewDelegate indentation level to a data source.
protocol TableViewCellIndentationLevelDataSource: class {
    func tableView(_ tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: IndexPath) -> Int
}

protocol ThreadDetailDataSource: class, UITableViewDataSource, TableViewCellIndentationLevelDataSource {
    var cellDelegate: FullEmailMessageTableViewCellDelegate? { get set }
    func registerTableView(_ tableView: UITableView)
}

class ThreadDetailDataSourceImpl: NSObject, ThreadDetailDataSource {
    fileprivate let service: EmailThreadService
    weak var cellDelegate: FullEmailMessageTableViewCellDelegate?
    
    fileprivate let cellIdentifier = "emailCell"
    
    fileprivate var indentationAndEmail: [(Int, Email)] = [] {
        didSet {
            textViewDataSources = [IndexPath: EmailTextRegionViewDataSource]()
        }
    }
    
    fileprivate let codeBlockParser: CodeBlockParser
    fileprivate let rootEmail: Email
    fileprivate var textViewDataSources: [IndexPath: EmailTextRegionViewDataSource] = [IndexPath: EmailTextRegionViewDataSource]()
    fileprivate lazy var emailFormatter: EmailFormatter = EmailFormatter()
    
    fileprivate var emails: [Email] = [] {
        didSet {
            self.indentationAndEmail = self.computeIndentationLevels(rootEmail)
        }
    }
    
    init(service: EmailThreadService, rootEmail: Email, codeBlockParser: CodeBlockParser) {
        self.service = service
        self.rootEmail = rootEmail
        self.codeBlockParser = codeBlockParser
        super.init()
    }
    
    func registerTableView(_ tableView: UITableView) {
        tableView.register(FullEmailMessageTableViewCell.nib(), forCellReuseIdentifier: cellIdentifier)
        
        service.getCachedThreads(descendantsRequestForRootEmail(rootEmail)) { (emails) -> Void in
            self.emails = emails
            tableView.reloadData()
            
            if self.rootEmail.descendants.count > emails.count {
                // Get uncached threads if we are missing any
                self.service.refreshCache(self.descendantsRequestForRootEmail(self.rootEmail), completion: { (descendants) -> Void in
                    self.emails = descendants
                    tableView.reloadData()
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: IndexPath) -> Int {
        return indentationAndEmail[indexPath.row].0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! FullEmailMessageTableViewCell
        let email = indentationAndEmail[indexPath.row].1
        
        cell.indentationLevel = indentationAndEmail[indexPath.row].0
        cell.indentationWidth = 10
        cell.setDate(emailFormatter.formatDate(email.date))
        cell.setName(emailFormatter.formatName(email.from))
        cell.delegate = cellDelegate
        
        var textViewDataSource = textViewDataSources[indexPath]
        
        let content = emailFormatter.formatContent(email.content)
        
        if textViewDataSource == nil {
            let regions = EmailQuoteRanges(content)
            textViewDataSource = EmailTextRegionViewDataSource(text: content, initiallyCollapsedRegions: regions, codeBlockParser: codeBlockParser)
            textViewDataSources[indexPath] = textViewDataSource!
        }
        
        cell.textViewDataSource = textViewDataSource!
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indentationAndEmail.count
    }
    
    fileprivate func descendantsRequestForRootEmail(_ rootEmail: Email) -> EmailThreadRequest {
        let builder = EmailThreadRequestBuilder()
        builder.idIn = Array(rootEmail.descendants.map { $0.id })
        builder.page = 1
        builder.pageSize = 1000
        builder.onlyComplete = true
        return builder.build()
    }
    
    fileprivate func computeIndentationLevels(_ rootEmail: Email) -> [(Int, Email)] {
        var children = [String: [Email]]()
        for email in rootEmail.descendants {
            if let inReplyTo = email.inReplyTo {
                if children[inReplyTo.id] == nil {
                    children[inReplyTo.id] = []
                }
                
                children[inReplyTo.id]!.append(email)
            }
        }
        
        for id in children.keys {
            children[id] = children[id]?.sorted { $0.date.compare($1.date as Date) == ComparisonResult.orderedAscending }
        }
        
        func indentationLevel(_ root: Email, indentLevel: Int) -> [(Int, Email)] {
            var list = [(Int, Email)]()
            for child in children[root.id] ?? [] {
                if child.id != root.id {
                    list.append(contentsOf: indentationLevel(child, indentLevel: indentLevel + 1))
                }
            }
            return [(indentLevel, root)] + list
        }
        
        let thread = indentationLevel(rootEmail, indentLevel: 0)
        return thread
    }
}
