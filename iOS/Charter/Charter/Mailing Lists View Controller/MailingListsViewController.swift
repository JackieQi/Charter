//
//  MailingListsViewController.swift
//  Swift Mailing List
//
//  Created by Matthew Palmer on 4/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

protocol MailingListsViewControllerDelegate: class {
    func mailingListsViewControllerDidSelectMailingList(_ mailingList: MailingListType)
}

class MailingListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: MailingListsViewControllerDelegate?
    
    let mailingLists: [MailingListType]
    
    static let reuseIdentifier = "mailingListCellIdentifier"
    
    init(mailingLists: [MailingListType]) {
        self.mailingLists = mailingLists
        super.init(nibName: "MailingListsViewController", bundle: Bundle.main)
    }
    
    override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: MailingListsViewController.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: .zero)
        
        navigationItem.title = Localizable.Strings.mailingLists
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MailingListsViewController.reuseIdentifier)!
        cell.textLabel?.text = self.mailingLists[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = self.mailingLists[indexPath.row].identifier
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailingLists.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.selectRow(at: nil, animated: false, scrollPosition: UITableViewScrollPosition.middle)
        delegate?.mailingListsViewControllerDidSelectMailingList(mailingLists[indexPath.row])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }
}
