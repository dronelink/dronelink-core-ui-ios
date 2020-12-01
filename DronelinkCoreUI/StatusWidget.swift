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
    internal struct Status {
        let message: String
        let color: UIColor?
    }
    
    internal var status: Status {
        let dronelinkStatusMessages = Dronelink.shared.statusMessages
        if let statusMessage = dronelinkStatusMessages?.filter({ $0.level.compare(to: .warning) > 0 }).first {
            return statusMessage.status
        }
        
        guard
            let droneSessionManager = primaryDroneSessionManager,
            let state = droneSessionManager.session?.state?.value
        else {
            return Status(message: "StatusWidget.disconnected".localized, color: nil)
        }
        
        if let statusMessage = droneSessionManager.statusMessages?.filter({ $0.level != .info }).sorted(by: { (l, r) -> Bool in l.level.compare(to: r.level) > 0 }).first {
            return statusMessage.status
        }
        
        if let statusMessage = dronelinkStatusMessages?.first {
            return statusMessage.status
        }
        
        return Status(message: (state.isFlying ? "StatusWidget.manual" : "StatusWidget.ready").localized, color: MDCPalette.green.accent400)
    }
    
    internal override var updateInterval: TimeInterval { 0.5 }
}

public class StatusColorWidget: StatusWidget {
    private let gradient = CAGradientLayer()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        gradient.colors = [DronelinkUI.Constants.overlayColor.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    @objc override func update() {
        super.update()
        
        //FIXME covers the whole screen briefly?
        gradient.frame = view.bounds
        
        guard let color = status.color else {
            gradient.colors = [DronelinkUI.Constants.overlayColor.cgColor]
            return
        }
        
        gradient.colors = [color.withAlphaComponent(0.5).cgColor, DronelinkUI.Constants.overlayColor.cgColor]
    }
}

public class StatusTextWidget: StatusWidget {
    public var label: MarqueeLabel?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let label = MarqueeLabel(frame: view.frame, duration: 8.0, fadeLength: 10.0)
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.label = label
    }
    
    @objc override func update() {
        super.update()
        label?.text = status.message
    }
}
