//
//  ThreadsViewController.swift
//  Swift Mailing List
//
//  Created by Matthew Palmer on 29/01/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

protocol ThreadsViewControllerDelegate: class {
    func threadsViewController(_ threadsViewController: ThreadsViewController, didSelectEmail email: Email)
    func threadsViewController(_ threadsViewController: ThreadsViewController, didSearchWithPhrase phrase: String, inMailingList mailingList: MailingListType)
}

class ThreadsViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let dataSource: ThreadsViewControllerDataSource
    
    weak var delegate: ThreadsViewControllerDelegate?
    
    var searchEnabled = true
    var refreshEnabled = true
    
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    
    init(dataSource: ThreadsViewControllerDataSource) {
        self.dataSource = dataSource
        super.init(nibName: "ThreadsViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ThreadsViewController.didRequestRefresh(_:)), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        self.dataSource.registerTableView(tableView)
        
        tableView.backgroundColor = UIColor(hue:0.67, saturation:0.02, brightness:0.96, alpha:1) // Group table background color
        
        tableView.delegate = self
        tableView.dataSource = dataSource
        navigationItem.title = dataSource.title
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        
        updateSeparatorStyle()
        
        if searchEnabled {
            searchController.dimsBackgroundDuringPresentation = true
            definesPresentationContext = true
            tableView.tableHeaderView = searchController.searchBar
            searchController.searchBar.delegate = self
        }
        
        if refreshEnabled {
            tableView.addSubview(refreshControl)
        }
        
        // Check whether we are running UI tests before performing an automatic refresh.
        // If we refresh immediately the screenshots (which we take with Fastlane in doing the UI tests)
        // will be in an undefined state.
        if !UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            didRequestRefresh(self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }
    
    fileprivate func updateSeparatorStyle() {
        if dataSource.isEmpty {
            tableView.separatorStyle = .none
        } else {
            tableView.separatorStyle = .singleLine
        }
    }
    
    func didRequestRefresh(_ sender: AnyObject) {
        dataSource.refreshDataFromNetwork { (success) -> Void in
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
            self.updateSeparatorStyle()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if dataSource.isEmpty {
            cell.isUserInteractionEnabled = false
        }
        
        if searchEnabled && cell is MessagePreviewTableViewCell {
            let messageCell = cell as! MessagePreviewTableViewCell
            messageCell.labelStackView.isUserInteractionEnabled = true
            messageCell.labelStackView.arrangedSubviews.forEach { labelView in
                let tap = UITapGestureRecognizer(target: self, action: #selector(ThreadsViewController.didTapLabelInCell(_:)))
                labelView.isUserInteractionEnabled = true
                labelView.addGestureRecognizer(tap)
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.threadsViewController(self, didSelectEmail: dataSource.emailAtIndexPath(indexPath))
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        delegate?.threadsViewController(self, didSearchWithPhrase: searchBar.text ?? "", inMailingList: dataSource.mailingList)
    }
    
    func didTapLabelInCell(_ sender: UIGestureRecognizer) {
        if let label = sender.view as? UILabel {
            let text = label.text?.lowercased() ?? ""
            let regex = try! NSRegularExpression(pattern: "[a-z]+-[0-9]+", options: .caseInsensitive)
            let searchText: String
            // If searching for an issue key (e.g. SE-0048), don't use square brackets
            if regex.matches(in: text, options: [], range: NSMakeRange(0, text.characters.count)).count > 0 {
                searchText = text
            } else {
                searchText = "[\(text)]"
            }
            
            delegate?.threadsViewController(self, didSearchWithPhrase: searchText, inMailingList: dataSource.mailingList)
        }
    }
}
