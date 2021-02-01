//
//  Extensions.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 2/6/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import Foundation
import JavaScriptCore
import CoreLocation
import UIKit
import os
import MaterialComponents
import Kingfisher

extension String {
    internal static let LocalizationMissing = "MISSING STRING LOCALIZATION"
    
    var localized: String {
        let value = DronelinkUI.bundle.localizedString(forKey: self, value: String.LocalizationMissing, table: nil)
        //assert(value != String.LocalizationMissing, "String localization missing: \(self)")
        return value
    }
}

extension UIApplication {
    public var currentViewController: UIViewController? {
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            return topController
        }
        
        return nil
    }
}

public extension UIView {
    func addShadow(color: UIColor = UIColor.black, opacity: Float = 0.75, radius: CGFloat = 3) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = CGSize(width: 0, height: radius)
        layer.masksToBounds = false
    }
    
    func animateLayout(duration: TimeInterval = 0.2) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseInOut, animations: {
            self.layoutIfNeeded()
        })
    }
}

extension UIViewController {
    public func install(inParent: UIViewController, insideSubview: UIView? = nil) {
        willMove(toParent: inParent)
        inParent.addChild(self)
        (insideSubview ?? inParent.view).addSubview(view)
        didMove(toParent: inParent)
    }
    
    public func uninstallFromParent() {
        removeFromParent()
        view.removeFromSuperview()
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#000000"
        }
        
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
    
    public func interpolate(_ end: UIColor?, percent: CGFloat) -> UIColor? {
        guard let end = end else {
            return self
        }
        
        let f = min(max(0, percent), 1)
        
        guard let c1 = self.cgColor.components, let c2 = end.cgColor.components else { return nil }
        
        let r: CGFloat = CGFloat(c1[0] + (c2[0] - c1[0]) * f)
        let g: CGFloat = CGFloat(c1[1] + (c2[1] - c1[1]) * f)
        let b: CGFloat = CGFloat(c1[2] + (c2[2] - c1[2]) * f)
        let a: CGFloat = CGFloat(c1[3] + (c2[3] - c1[3]) * f)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension MDCActivityIndicator: Placeholder {
}
