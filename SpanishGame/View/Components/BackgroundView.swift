//
//  BackgroundView.swift
//  SpanishGame
//
//  Created by Murat Can Zahmakıran on 2.08.2022.
//

import UIKit

@IBDesignable
final class BackgroundView: UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get { layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }

    @IBInspectable
    var borderColor: UIColor? {
        get { layer.borderColor.map { UIColor(cgColor: $0) } }
        set { layer.borderColor = newValue?.cgColor }
    }
    
    @IBInspectable
    var borderWidth: UIColor? {
        get { layer.borderColor.map { UIColor(cgColor: $0) } }
        set { layer.borderColor = newValue?.cgColor }
    }
}
