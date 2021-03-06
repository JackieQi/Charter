//
//  EmailCollapsibleTextViewDataSource.swift
//  Swift Mailing List
//
//  Created by Matthew Palmer on 6/02/2016.
//  Copyright © 2016 Matthew Palmer. All rights reserved.
//

import UIKit

protocol EmailTextRegionViewDataSourceDelegate: class {
    func emailTextRegionViewDatatSourceNeedsPopoverViewControllerPresented(_ view: UIView, sender: UIView)
}

class EmailTextRegionViewDataSource: NSObject, RegionViewDataSource {
    var preloadedData = [NSAttributedString]()
    enum State {
        case expanded, collapsed, `static`
    }
    
    struct Region {
        var state: State
        var range: NSRange
    }
    
    var regions: [Region] = []
    fileprivate var textString: String = ""
    
    weak var delegate: EmailTextRegionViewDataSourceDelegate?
    
    init(text: String, initiallyCollapsedRegions: [NSRange], codeBlockParser: CodeBlockParser) {
        self.textString = text
        
        super.init()
        
        setRegions(initiallyCollapsedRegions)
        
        let bodyFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        var descriptor = bodyFont.fontDescriptor
        descriptor = descriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits.traitItalic)!
        
        let italicBodyFont = UIFont(descriptor: descriptor, size: bodyFont.pointSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        
        for region in regions {
            let text = textForRegion(region).trimmingCharacters(in: CharacterSet.newlines)
            
            if region.state == .collapsed || region.state == .expanded {
                let attributedString = NSAttributedString(string: text, attributes: [
                    NSFontAttributeName: italicBodyFont,
                    NSForegroundColorAttributeName: UIColor.darkGray,
                    NSParagraphStyleAttributeName: paragraphStyle
                ])
                
                preloadedData.append(attributedString)
            } else {
                let codeBlockAttributes = [
                    NSForegroundColorAttributeName: UIColor.black,
                    NSBackgroundColorAttributeName: UIColor(hue:0, saturation:0, brightness:0.96, alpha:1),
                    NSFontAttributeName: UIFont(name: "Menlo-Regular", size: bodyFont.pointSize)!
                ]
                
                let blockRanges = codeBlockParser.codeBlockRangesInText(text)
                let attributedString = NSMutableAttributedString(string: text)
                attributedString.addAttribute(NSFontAttributeName, value: bodyFont, range: NSMakeRange(0, text.characters.count))
                
                attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, text.characters.count))
                attributedString.applyEachAttribute(codeBlockAttributes, toEachRange: blockRanges)
                
                let inlineCodeRanges = codeBlockParser.inlineCodeRangesInText(text)
                attributedString.applyEachAttribute(codeBlockAttributes, toEachRange: inlineCodeRanges)
                
                preloadedData.append(attributedString)
            }
        }
    }
    
    func numberOfRegionsInRegionView(_ regionView: RegionView) -> Int {
        return regions.count
    }
    
    func regionView(_ regionView: RegionView, viewForRegionAtIndex index: Int) -> UIView {
        let region = regions[index]
        
        let text = textForRegion(region)
        if region.state == .collapsed {
            return collapsedRegionForIndex(index)
        } else if region.state == .expanded {
            return expandedRegionForIndex(index, text: text)
        } else {
            return staticRegionForIndex(index, text: text)
        }
    }
    
    func staticRegionForIndex(_ index: Int, text: String) -> UIView {
        let view = UITextView()
        view.isEditable = false
        view.isScrollEnabled = false
        view.isSelectable = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)

        let attributedString = preloadedData[index]
        
        view.attributedText = attributedString
        view.dataDetectorTypes = UIDataDetectorTypes.link
        return view
    }
    
    func expandedRegionForIndex(_ index: Int, text: String) -> UIView {
        let textView = UITextView()
        textView.isEditable = false
        textView.attributedText = preloadedData[index]
        textView.dataDetectorTypes = UIDataDetectorTypes.link
        
        return textView
    }
    
    func collapsedRegionForIndex(_ index: Int) -> UIView {
        let view = ThreeDotsButton()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.expandIndicator.tag = index
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EmailTextRegionViewDataSource.didTapToExpandRegion(_:)))
        view.expandIndicator.removeGestureRecognizer(tapGestureRecognizer)
        view.expandIndicator.addGestureRecognizer(tapGestureRecognizer)
        return view
    }
    
    func didTapToExpandRegion(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag else { return }
        let text = textForRegion(regions[index])
        guard let view = expandedRegionForIndex(index, text: text) as? UITextView else {
            return
        }
        
        delegate?.emailTextRegionViewDatatSourceNeedsPopoverViewControllerPresented(view, sender: gesture.view!)
    }
    
    func textForRegion(_ region: Region) -> String {
        return (textString as NSString).substring(with: region.range)
    }
    
    // Should only be called from init
    fileprivate func setRegions(_ collapsed: [NSRange]) {
        let text = textString
        let collapsedRegions = collapsed
        
        if collapsedRegions.count == 0 {
            regions.append(Region(state: .static, range: NSMakeRange(0, text.characters.count)))
        }
        
        var lastCollapsedRegion: Region!
        
        for index in collapsedRegions.indices {
            // First region
            if index == collapsedRegions.startIndex {
                let range = NSMakeRange(0, collapsedRegions[index].location)
                if range.length != 0 {
                    regions.append(Region(state: .static, range: range))
                }
                
                let c = Region(state: .collapsed, range: collapsedRegions[index])
                regions.append(c)
                lastCollapsedRegion = c
                
                // Only one region
                if index == collapsedRegions.endIndex - 1 {
                    let endOfPrevious = lastCollapsedRegion.range.location + lastCollapsedRegion.range.length
                    let range = NSMakeRange(endOfPrevious, text.characters.count - endOfPrevious)
                    if range.length > 0 {
                        regions.append(Region(state: .static, range: range))
                    }
                }
                
                continue
            }
            
            // Last region
            if index == collapsedRegions.endIndex - 1 {
                let penultimateStaticLocation = lastCollapsedRegion.range.location + lastCollapsedRegion.range.length
                let penultimateStaticLength = collapsedRegions[index].location - penultimateStaticLocation
                let penultimateStaticRange = NSMakeRange(penultimateStaticLocation, penultimateStaticLength)
                if penultimateStaticLocation != 0 {
                    regions.append(Region(state: .static, range: penultimateStaticRange))
                }
                
                let c = Region(state: .collapsed, range: collapsedRegions[index])
                regions.append(c)
                lastCollapsedRegion = c
                
                let lastRegion = regions.last!
                let endOfLastRegion = regions.last!.range.location + lastRegion.range.length
                let range = NSMakeRange(endOfLastRegion, text.characters.count - endOfLastRegion)
                
                if range.length != 0 {
                    regions.append(Region(state: .static, range: range))
                }
                continue
            }
            
            // Middle regions
            
            // Range for the text between the last collapsed region and the beginning of the new collapsed region.
            let location = lastCollapsedRegion.range.location + lastCollapsedRegion.range.length
            let length = collapsedRegions[index].location - location
            let range = NSMakeRange(location, length)
            
            if range.length != 0 {
                regions.append(Region(state: .static, range: range))
            }
            
            let c = Region(state: .collapsed, range: collapsedRegions[index])
            regions.append(c)
            lastCollapsedRegion = c
        }
    }
}
