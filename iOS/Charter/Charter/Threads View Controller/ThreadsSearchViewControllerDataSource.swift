//
//  ThreadsSearchViewControllerDataSource.swift
//  Charter
//
//  Created by Matthew Palmer on 17/03/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

class ThreadsSearchViewControllerDataSource: NSObject, ThreadsViewControllerDataSource {
    var emails: [Email] = [] {
        didSet {
            // Reset labels
            emails.forEach { email in
                let textLabels = emailFormatter.labelsInSubject(emailFormatter.formatSubject(email.subject))
                
                let match: Match
                if email.subject.lowercased().contains(searchPhrase.lowercased()) {
                    match = .subject(searchPhrase)
                } else if email.from.lowercased().contains(searchPhrase.lowercased()) {
                    match = .from(searchPhrase)
                } else {
                    match = .content(searchPhrase) // Assume that if we have the email it must match on one of these three fields.
                }
                
                var labels: [(string: String, textColor: UIColor, backgroundColor: UIColor)] = [
                    (string: match.label().0, textColor: UIColor.white, backgroundColor: match.label().1)
                ]
                
                labels
                    .append(
                        contentsOf: textLabels.map { (labelService.formattedStringForLabel($0), labelService.colorForLabel($0), UIColor.white) }
                )
                
                self.labels[email] = labels
            }
        }
    }
    
    var labels: [Email: [(string: String, textColor: UIColor, backgroundColor: UIColor)]] = [Email: [(string: String, textColor: UIColor, backgroundColor: UIColor)]]()
    
    let searchPhrase: String
    let mailingList: MailingListType
    let service: EmailThreadService
    let labelService: LabelService
    let request: UncachedThreadRequest
    
    let emailFormatter = EmailFormatter()
    
    fileprivate let cellReuseIdentifier = "messageCell"
    fileprivate let emptyCellReuseIdentifier = "searchInProgressCell"
    
    var isEmpty: Bool {
        return emails.count == 0
    }
    
    var isSearching: Bool = false
    
    var title: String = ""
    
    init(service: EmailThreadService, labelService: LabelService, mailingList: MailingListType, searchPhrase: String) {
        self.searchPhrase = searchPhrase
        self.mailingList = mailingList
        self.labelService = labelService
        let builder = SearchRequestBuilder()
        // Always do exact match search (tokenized searches are pretty useless in this context)
        builder.text = "\"" + searchPhrase + "\""
        builder.mailingList = mailingList.identifier
        self.request = builder.build()
        self.service = service
        self.title = "“\(searchPhrase)”"
        super.init()
    }
    
    func refreshDataFromNetwork(_ completion: @escaping (Bool) -> Void) {
        isSearching = true
        service.getUncachedThreads(self.request) { emails in
            self.isSearching = false
            self.emails = emails
            
            completion(true)
        }
    }
    
    func emailAtIndexPath(_ indexPath: IndexPath) -> Email {
        return emails[indexPath.row]
    }
    
    func registerTableView(_ tableView: UITableView) {
        tableView.register(MessagePreviewTableViewCell.nib(), forCellReuseIdentifier: cellReuseIdentifier)
        tableView.register(SearchInProgressTableViewCell.nib(), forCellReuseIdentifier: emptyCellReuseIdentifier)
        
        refreshDataFromNetwork { success in
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !isEmpty else {
            tableView.backgroundColor = UIColor.white
            return 1
        }
        
        tableView.backgroundColor = UIColor(hue:0.67, saturation:0.02, brightness:0.96, alpha:1)
        return emails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !isEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: emptyCellReuseIdentifier) as! SearchInProgressTableViewCell
            if isSearching {
                cell.activityIndicator.startAnimating()
                cell.searchLabel.text = Localizable.Strings.searching
                cell.activityIndicator.isHidden = false
            } else {
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.isHidden = true
                cell.searchLabel.text = Localizable.Strings.noResults
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! MessagePreviewTableViewCell
        let email = emailAtIndexPath(indexPath)
        let formattedSubject = emailFormatter.subjectByRemovingLabels(
                emailFormatter.formatSubject(email.subject)
            )
        
        cell.setName(emailFormatter.formatName(email.from))
        cell.setTime(emailFormatter.formatDate(email.date))
        cell.setMessageCount("\(email.descendants.count)")
        
        let labels: [(string: String, textColor: UIColor, backgroundColor: UIColor)] = self.labels[email] ?? []
        cell.setLabels(labels)
        cell.setSubject(formattedSubject)
        
        return cell
    }
}

private enum Match {
    case subject(String)
    case from(String)
    case content(String)
    
    func label() -> (String, UIColor) {
        let text: String
        let color: UIColor = UIColor(red:0.99, green:0.43, blue:0.22, alpha:1)
        
        switch self {
        case .subject(_):
            text = Localizable.Strings.subject
        case .from(_):
            text = Localizable.Strings.author
        case .content(_):
            text = Localizable.Strings.content
        }
        
        return (text.lowercased(), color)
    }
}
