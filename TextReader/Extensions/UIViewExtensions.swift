//
//  UIViewExtensions.swift
//  TextReader
//
//  Created by Eric Internicola on 6/6/20.
//  Copyright © 2020 Eric Internicola. All rights reserved.
//

import Cartography
import UIKit


extension UIView {
    
    /// Toasts a message to the user.
    /// - Parameters:
    ///   - hostView: The view that's hosting the toast.
    ///   - message: The message to be delivered to the user.
    ///   - duration: The length of time that the toas shows.
    func toast(in hostView: UIView, withMessage message: String, for duration: TimeInterval = 0.75) {
        let darkView = UIView()
        darkView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        let messageView = UIView()
        let label = UILabel()
        
        label.font = .boldSystemFont(ofSize: 24)
        label.numberOfLines = 0
        label.textColor = .white
        label.text = message
        label.textAlignment = .center
        
        hostView.addSubview(darkView)
        darkView.addSubview(messageView)
        messageView.addSubview(label)
        
        messageView.layer.borderColor = UIColor.gray.cgColor
        messageView.layer.borderWidth = 1
        messageView.layer.cornerRadius = 24
        
        constrain(darkView, hostView, messageView, label) { darkView, hostView, messageView, label in
            darkView.top == hostView.top
            darkView.left == hostView.left
            darkView.right == hostView.right
            darkView.bottom == hostView.bottom
            
            messageView.top >= hostView.top + 16
            messageView.bottom <= hostView.bottom - 16
            messageView.left >= hostView.left + 16
            messageView.right <= hostView.right - 16
            
            messageView.centerX == hostView.centerX
            messageView.centerY == hostView.centerY
            
            label.top == messageView.top + 32
            label.left == messageView.left + 24
            label.right == messageView.right - 32
            label.bottom == messageView.bottom - 24
        }
        
        darkView.alpha = 0.0
        
        UIView.animate(withDuration: 0.3) {
            darkView.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(withDuration: 0.3, animations: {
                darkView.alpha = 0
            }, completion: { _ in
                messageView.removeFromSuperview()
            })
        }
    }
    
}
