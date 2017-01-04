//
//  MessagePreviewTableViewCell.swift
//  Swift Mailing List
//
//  Created by Matthew Palmer on 5/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

class MessagePreviewTableViewCell: UITableViewCell {
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageCountLabel: UILabel!
    @IBOutlet weak var labelStackView: UIStackView!
    
    class func nib() -> UINib {
        return UINib(nibName: "MessagePreviewTableViewCell", bundle: nil)
    }
    
    func setName(_ name: String) {
        nameLabel.font = UIFont.smallCapsFontOfSize(14)
        nameLabel.text = name.lowercased()
    }
    
    func setTime(_ time: String) {
        timeLabel.font = UIFont.smallCapsFontOfSize(14)
        timeLabel.text = time.lowercased()
    }
    
    func setMessageCount(_ count: String) {
        messageCountLabel.layer.cornerRadius = 15
        messageCountLabel.text = count
        messageCountLabel.font = UIFont.smallCapsFontOfSize(14)
        messageCountLabel.layer.masksToBounds = true
    }
    
    func setLabels(_ labels: [(string: String, textColor: UIColor, backgroundColor: UIColor)]) {
        let font = UIFont.systemSmallCapsMediumWeightFontOfSize(14)
        labelStackView.spacing = 10
        labelStackView.distribution = .equalSpacing
        
        let labs: [UILabel] = labels.map {
            let l = NRLabel()
            l.font = font
            l.textColor = $0.textColor
            l.text = $0.string
            l.layer.borderColor = $0.textColor.cgColor
            l.layer.borderWidth = 1.0
            l.layer.cornerRadius = 3.0
            l.layer.masksToBounds = true
            l.layer.backgroundColor = $0.backgroundColor.cgColor
            l.textInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            return l
        }
        
        labelStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        labs.forEach { labelStackView.addArrangedSubview($0) }
    }
    
    func setSubject(_ text: String) {
        subjectLabel.text = text
    }
}
