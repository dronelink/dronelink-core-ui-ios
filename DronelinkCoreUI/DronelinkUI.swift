//
//  DronelinkUI.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 10/28/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import Foundation
import UIKit
import UserNotifications
import MaterialComponents.MaterialDialogs
import MaterialComponents.MaterialSnackbar
import MaterialComponents.MaterialPalettes
import DronelinkCore
import Agrume
import Kingfisher

extension DronelinkUI {
    public static let shared = DronelinkUI()
    public static let bundle = Bundle(for: DronelinkUI.self)
    public static func loadImage(named: String, renderingMode: UIImage.RenderingMode = .alwaysTemplate) -> UIImage? {
        return UIImage(named: named, in: DronelinkUI.bundle, compatibleWith: nil)?.withRenderingMode(renderingMode)
    }
    
    public static let Constants = (
        cornerRadius: CGFloat(10.0),
        overlayColor: UIColor.black.withAlphaComponent(0.6),
        primaryColor: MDCPalette.deepPurple.tint800,
        secondaryColor: MDCPalette.pink.accent400
    )
}

public class DronelinkUI: NSObject {
    private var background = false
    
    public override init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                else {
                    //TODO implement
                }
            }
        })

        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        AgrumeServiceLocator.shared.setDownloadHandler { url, completion in
            KingfisherManager.shared.retrieveImage(with: url) {
                if let image = try? $0.get().image {
                    completion(image)
                    return
                }
                
                KingfisherManager.shared.downloader.downloadImage(with: url, options: [], completionHandler:  {
                    completion(try? $0.get().image)
                })
            }
        }
    }
    
    @objc func willEnterForeground(_ notification: Notification) {
        background = false
    }
    
    @objc func didEnterBackground(_ notification: Notification) {
        background = true
    }
    
    public func cacheImages(urls: [URL]) {
        ImagePrefetcher(urls: urls).start()
    }

    public func showDialog(title: String, details: String? = nil, actions: [MDCAlertAction]? = nil, emphasis: MDCActionEmphasis = .medium) {
        if background {
            showNotification(title: title, details: details)
            return
        }
        
        DispatchQueue.main.async {
            let alert = MDCAlertController(title: title, message: details)
            if let actions = actions {
                actions.forEach { action in
                    alert.addAction(action)
                }
            }
            else {
                alert.addAction(MDCAlertAction(title: "dismiss".localized, emphasis: emphasis, handler: { action in
                    
                }))
            }
            let scheme = MDCContainerScheme()
            alert.applyTheme(withScheme: scheme)
            UIApplication.shared.currentViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    public func showSnackbar(text: String) {
        DispatchQueue.main.async {
            let message = MDCSnackbarMessage()
            message.text = text
            let action = MDCSnackbarMessageAction()
            action.handler = {() in
                
            }
            action.title = "dismiss".localized
            message.action = action
            message.duration = 8.0
            MDCSnackbarManager.default.show(message)
        }
    }
    
    public func showNotification(title: String, details: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let details = details {
            content.body = details
        }
        
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)), withCompletionHandler: nil)
    }
}
