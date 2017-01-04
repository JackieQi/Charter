//
//  ThreadsViewControllerDataSource.swift
//  Charter
//
//  Created by Matthew Palmer on 25/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

protocol ThreadsViewControllerDataSource: class, UITableViewDataSource {
    var mailingList: MailingListType { get }
    var title: String { get }
    var isEmpty: Bool { get }
    func refreshDataFromNetwork(_ completion: @escaping (Bool) -> Void)
    func emailAtIndexPath(_ indexPath: IndexPath) -> Email
    func registerTableView(_ tableView: UITableView)
}

extension ThreadsViewControllerDataSource {
    var title: String {
        return mailingList.name
    }
}

class ThreadsViewControllerDataSourceImpl: NSObject, ThreadsViewControllerDataSource {
    fileprivate let service: EmailThreadService
    fileprivate let labelService: LabelService
    fileprivate let cellReuseIdentifier = "threadsCellReuseIdentifier"
    fileprivate let emptyCellReuseIdentifier = "emptyCellReuseIdentifier"
    
    let mailingList: MailingListType
    fileprivate var threads: [Email] = []
    
    fileprivate lazy var emailFormatter: EmailFormatter = EmailFormatter()
    
    init(service: EmailThreadService, mailingList: MailingListType, labelService: LabelService) {
        self.service = service
        self.mailingList = mailingList
        self.labelService = labelService
        
        super.init()
    }
    
    var isEmpty: Bool {
        return threads.count == 0
    }
    
    func registerTableView(_ tableView: UITableView) {
        tableView.register(MessagePreviewTableViewCell.nib(), forCellReuseIdentifier: cellReuseIdentifier)
        tableView.register(NoThreadsTableViewCell.nib(), forCellReuseIdentifier: emptyCellReuseIdentifier)
        
        service.getCachedThreads(threadsRequestForPage(1)) { [unowned self] (emails) -> Void in
            self.threads = emails
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard threads.count > 0 else {
            tableView.backgroundColor = UIColor.white
            return tableView.dequeueReusableCell(withIdentifier: emptyCellReuseIdentifier)!
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! MessagePreviewTableViewCell
        let email = threads[indexPath.row]
        let formattedSubject = emailFormatter.formatSubject(email.subject)
        let labels = emailFormatter.labelsInSubject(formattedSubject)
        
        cell.setName(emailFormatter.formatName(email.from))
        cell.setTime(emailFormatter.formatDate(email.date))
        cell.setMessageCount("\(email.descendants.count)")
        cell.setLabels(labels.map { (labelService.formattedStringForLabel($0), labelService.colorForLabel($0), UIColor.white) })
        cell.setSubject(emailFormatter.subjectByRemovingLabels(formattedSubject))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard threads.count > 0 else {
            tableView.backgroundColor = UIColor.white
            return 1
        }
        
        tableView.backgroundColor = UIColor(hue:0.67, saturation:0.02, brightness:0.96, alpha:1)
        return threads.count
    }
    
    func refreshDataFromNetwork(_ completion: @escaping (Bool) -> Void) {
        service.refreshCache(threadsRequestForPage(1)) { emails in
            self.threads = emails
            completion(true)
        }
    }
    
    func emailAtIndexPath(_ indexPath: IndexPath) -> Email {
        return threads[indexPath.row]
    }
    
    fileprivate func threadsRequestForPage(_ page: Int) -> EmailThreadRequest {
        let builder = EmailThreadRequestBuilder()
        builder.mailingList = mailingList.identifier
        builder.inReplyTo = Either.right(NSNull())
        builder.onlyComplete = true
        builder.pageSize = 50
        builder.page = page
        builder.sort = [("date", false)]
        return builder.build()
    }
}
