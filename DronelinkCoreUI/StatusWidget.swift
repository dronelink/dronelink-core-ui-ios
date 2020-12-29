//
//  StatusColorWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/1/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MarqueeLabel

extension Kernel.MessageLevel {
    internal var statusColor: UIColor? {
        switch self {
        case .info:
            return MDCPalette.green.accent400
        case .warning:
            return MDCPalette.amber.accent400
        case .danger, .error:
            return MDCPalette.red.accent400
        }
    }
}

extension Kernel.Message {
    internal var status: StatusWidget.Status { StatusWidget.Status(message: display, color: level.statusColor) }
}

public class StatusWidget: UpdatableWidget {
    public struct Status {
        let message: String
        let color: UIColor?
    }
    
    internal var status: Status {
        let dronelinkStatusMessages = Dronelink.shared.statusMessages
        if let statusMessage = dronelinkStatusMessages?.filter({ $0.level.compare(to: .warning) > 0 }).first {
            return statusMessage.status
        }
        
        guard
            let state = session?.state?.value
        else {
            return statuses.disconnected
        }
        
        if let statusMessage = targetDroneSessionManager?.statusMessages?.filter({ $0.level != .info }).sorted(by: { (l, r) -> Bool in l.level.compare(to: r.level) > 0 }).first {
            return statusMessage.status
        }
        
        if let statusMessage = dronelinkStatusMessages?.first {
            return statusMessage.status
        }
        
        return state.isFlying ? statuses.manualFlight : statuses.ready
    }
    
    public override var updateInterval: TimeInterval { 0.5 }
    
    public var statuses = (
        disconnected: Status(message: "StatusWidget.disconnected".localized, color: MDCPalette.deepPurple.accent400),
        ready: Status(message: "StatusWidget.ready".localized, color: MDCPalette.green.accent400),
        manualFlight: Status(message: "StatusWidget.manual".localized, color: MDCPalette.green.accent400)
    )
}

public class StatusGradientWidget: StatusWidget {
    public let gradient = CAGradientLayer()
    public var opacity: CGFloat = 0.73
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.clipsToBounds = true
        
        gradient.colors = [DronelinkUI.Constants.overlayColor.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    @objc open override func update() {
        super.update()
        
        gradient.frame = view.frame
        
        guard let color = status.color else {
            gradient.colors = [DronelinkUI.Constants.overlayColor.cgColor]
            return
        }
        
        gradient.colors = [color.withAlphaComponent(opacity).cgColor, UIColor.clear.cgColor]
    }
}

public class StatusLabelWidget: StatusWidget {
    public let label = MarqueeLabel(frame: CGRect.zero, duration: 8.0, fadeLength: 10.0)
    public var colorEnabled = false
    public var onTapped: (() -> ())?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.clipsToBounds = true
        
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = UIColor.clear
        
        label.addShadow()
        label.leadingBuffer = 8
        label.trailingBuffer = label.leadingBuffer
        label.speed = MarqueeLabel.SpeedLimit.rate(60)
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onViewTapped(_:))))
    }
    
    @objc open override func update() {
        super.update()
        let status = self.status
        label.text = status.message
        if colorEnabled {
            view.backgroundColor = status.color
        }
    }
    
    @objc func onViewTapped(_ sender: UITapGestureRecognizer) {
        onTapped?()
    }
}
