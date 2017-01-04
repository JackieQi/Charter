//
//  NRLabel.swift
//  Charter
//
//  Created by Matthew Palmer on 12/03/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

// Source: http://stackoverflow.com/a/21267507

class NRLabel : UILabel {
    var textInsets: UIEdgeInsets = UIEdgeInsets.zero
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var rect = textInsets.apply(bounds)
        rect = super.textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        return textInsets.inverse.apply(rect)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: textInsets.apply(rect))
    }
    
}

extension UIEdgeInsets {
    var inverse: UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
    func apply(_ rect: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(rect, self)
    }
}
