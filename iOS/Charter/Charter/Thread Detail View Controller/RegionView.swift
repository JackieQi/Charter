//
//  RegionView.swift
//  CollapsibleTextView
//
//  Created by Matthew Palmer on 6/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

protocol RegionViewDataSource: class {
    func numberOfRegionsInRegionView(_ regionView: RegionView) -> Int
    func regionView(_ regionView: RegionView, viewForRegionAtIndex: Int) -> UIView
}

protocol RegionViewDelegate: class {
    func regionView(_ regionView: RegionView, didFinishReplacingRegionAtIndex: Int)
}

/// A vertical stack view abstracted into regions.
class RegionView: UIView {
    weak var dataSource: RegionViewDataSource? {
        didSet {
            if dataSource !== oldValue {
                reloadData()
            }
        }
    }
    
    weak var delegate: RegionViewDelegate?
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.backgroundColor = .red
        stackView.axis = .vertical
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        postInit()
    }
    
    override class var requiresConstraintBasedLayout : Bool { return true }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(frame: CGRect.zero)
        postInit()
    }
    
    fileprivate func postInit() {
        addSubview(stackView)
        translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let top = NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        let left = NSLayoutConstraint(item: stackView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0)
        let right = NSLayoutConstraint(item: stackView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: stackView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        
        addConstraints([top, left, right, bottom])
    }
    
    func reloadData() {
        guard let dataSource = dataSource else { return }
        
        stackView.subviews.forEach { $0.removeFromSuperview() }
        
        let numberOfRegions = dataSource.numberOfRegionsInRegionView(self)
        for index in 0..<numberOfRegions {
            let region = dataSource.regionView(self, viewForRegionAtIndex: index)
            stackView.addArrangedSubview(region)
        }
    }
    
    func replaceRegionAtIndex(_ index: Int, withView replacementView: UIView) {
        let originalView = stackView.arrangedSubviews[index]
        replacementView.isHidden = true
        originalView.isHidden = true
        
        self.stackView.insertArrangedSubview(replacementView, at: index)
        self.stackView.removeArrangedSubview(originalView)
        replacementView.isHidden = false
        self.delegate?.regionView(self, didFinishReplacingRegionAtIndex: index)
    }
}
