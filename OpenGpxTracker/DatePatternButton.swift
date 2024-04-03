//
//  DateFieldButton.swift
//  Gpx Tracker
//
//  Developed by Andrea Piani in La Palma - 18 01 2024
//
import UIKit

/// Each individual button that represents a date pattern
class DatePatternButton: UIButton {
    
    /// DateFormatter-friendly pattern of that the button holds.
    ///
    /// such as `YYYY` or `s`
    var pattern = String()
    
    /// For dealing with button tap highlight
    override var isSelected: Bool {
        didSet {
            if #available(iOS 13.0, *) {
                backgroundColor = isSelected ?  .highlightKeyboardColor : .keyboardColor
            } else {
                backgroundColor = isSelected ?  .highlightLightKeyboard : .lightKeyboard
            }
        }
    }
    
    /// For dealing with button tap highlight
    override var isHighlighted: Bool {
        didSet {
            if #available(iOS 13.0, *) {
                backgroundColor = isHighlighted ?  .highlightKeyboardColor : .keyboardColor
            } else {
                backgroundColor = isHighlighted ?  .highlightLightKeyboard : .darkKeyboard
            }
        }
    }
    
}
