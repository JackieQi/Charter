//
//  ThreadDetailViewController.swift
//  Swift Mailing List
//
//  Created by Matthew Palmer on 31/01/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

class ThreadDetailViewController: UIViewController, UITableViewDelegate, FullEmailMessageTableViewCellDelegate, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let dataSource: ThreadDetailDataSource
    
    fileprivate var navigationBar: UINavigationBar? { return navigationController?.navigationBar }
    
    fileprivate lazy var nextMessageButton: UIBarButtonItem = { UIBarButtonItem(image: UIImage(named: "UIButtonBarArrowDown"), style: .plain, target: self, action: #selector(self.scrollToNextMessage)) }()
    fileprivate lazy var previousMessageButton: UIBarButtonItem = { UIBarButtonItem(image: UIImage(named: "UIButtonBarArrowUp"), style: .plain, target: self, action: #selector(self.scrollToPreviousMessage)) }()
    
    init(dataSource: ThreadDetailDataSource) {
        self.dataSource = dataSource
        super.init(nibName: "ThreadDetailViewController", bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        dataSource.registerTableView(tableView)
        dataSource.cellDelegate = self
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.estimatedRowHeight = 160
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        
        setupNavigationButtons()
    }
    
    func setupNavigationButtons() {
        navigationItem.rightBarButtonItems = [nextMessageButton, previousMessageButton]
        updateNavigationButtons()
    }
    
    func updateNavigationButtons() {
        guard let navigationBar = navigationBar else { return }
        
        previousMessageButton.isEnabled = tableView.contentOffset.y > 0
        
        let lastRowIndexPath = IndexPath(row: lastRowIndex, section: 0)
        let navBarOffset = navigationBar.frame.size.height + navigationBar.frame.origin.y
        nextMessageButton.isEnabled = tableView.contentOffset.y < tableView.rectForRow(at: lastRowIndexPath).origin.y - navBarOffset - 1
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationButtons()
    }
    
    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return dataSource.tableView(tableView, indentationLevelForRowAtIndexPath: indexPath) ?? 0
    }
    
    func didChangeCellHeight(_ indexPath: IndexPath) {
        tableView.reloadData()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func presentPopover(_ view: UIView, sender: UIView) {
        let size: CGSize
        
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            size = CGSize(width: self.view.frame.width - 140, height: self.view.frame.height - 10)
        } else {
            size = CGSize(width: self.view.frame.width - 10, height: self.view.frame.height - 140)
        }
        
        let viewController = UIViewController()
        viewController.preferredContentSize = size
        viewController.view.backgroundColor = .white
        viewController.modalPresentationStyle = UIModalPresentationStyle.popover
        
        viewController.popoverPresentationController!.delegate = self
        viewController.popoverPresentationController!.sourceView = sender
        viewController.popoverPresentationController!.sourceRect = sender.frame
        viewController.popoverPresentationController!.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0) // No arrow
        
        view.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: size.width - 10, height: size.height - 10))
        viewController.view.addSubview(view)
        
        self.present(viewController, animated: true, completion: nil)
    }
}

// Logic for navigation buttons (previous/next arrows)
extension ThreadDetailViewController {
    fileprivate var firstVisibleRowIndex: Int? {
        guard let navigationBar = navigationBar else { return nil }
        let convertedNavBarFrame = tableView.convert(navigationBar.bounds, from: navigationBar)
        let samplingY = convertedNavBarFrame.origin.y + convertedNavBarFrame.size.height + 1
        return tableView.indexPathForRow(at: CGPoint(x: 0, y: samplingY))?.row
    }
    
    fileprivate var lastRowIndex: Int {
        return dataSource.tableView(tableView, numberOfRowsInSection: 0) - 1
    }
    
    func scrollToPreviousMessage() {
        guard let currentIndex = firstVisibleRowIndex else { return }
        scrollToRowAtIndex(requestedIndex: currentIndex - 1)
    }
    
    func scrollToNextMessage() {
        guard let currentIndex = firstVisibleRowIndex else { return }
        scrollToRowAtIndex(requestedIndex: currentIndex + 1)
    }
    
    fileprivate func scrollToRowAtIndex(requestedIndex index: Int) {
        let indexPath = IndexPath(row: clamp(index, min: 0, max: lastRowIndex), section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    fileprivate func clamp<T : Comparable>(_ value: T, min: T, max: T) -> T {
        if (value < min) { return min }
        if (value > max) { return max }
        return value
    }
}
