//
//  IndicatorWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 6/11/21.
//  Copyright © 2021 Dronelink. All rights reserved.
//

import Foundation

open class IndicatorWidget: UpdatableWidget {
    public let titleLabel = UILabel()
    public let valueLabel = UILabel()
    public var valueGenerator: (() -> String?)?
    
    public func setup(parent: UIView, title: String, valueGenerator: (() -> String?)?) {
        parent.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.text = title
        self.valueGenerator = valueGenerator
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = .white
        titleLabel.alpha = 0.6
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 7.4, weight: .regular)
        titleLabel.adjustsFontSizeToFitWidth = true
        
        valueLabel.textColor = .white
        valueLabel.textAlignment = .left
        valueLabel.font = UIFont.systemFont(ofSize: 13.8, weight: .bold)
        valueLabel.adjustsFontSizeToFitWidth = true
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { [weak self] make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        
        view.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { [weak self] make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom)
        }
    }
    
    @objc open override func update() {
        super.update()
        valueLabel.text = valueGenerator?() ?? ""
    }
}

public class DefaultIndicatorsWidget: DefaultChannelWidget {
    public override var channel: UInt? {
        get {
            super.channel
        }
        set {
            super.channel = newValue
            gimbalOrientationWidget?.channel = newValue
            cameraIsoWidget?.channel = newValue
            cameraShutterWidget?.channel = newValue
            cameraApertureWidget?.channel = newValue
            cameraExposureCompensationWidget?.channel = newValue
            cameraWhiteBalanceWidget?.channel = newValue
        }
    }
    
    private let gimbalOrientationWidget = WidgetFactory.shared.createGimbalOrientationWidget(channel: nil)
    private let cameraIsoWidget = WidgetFactory.shared.createCameraISOWidget(channel: nil)
    private let cameraShutterWidget = WidgetFactory.shared.createCameraShutterWidget(channel: nil)
    private let cameraApertureWidget = WidgetFactory.shared.createCameraApertureWidget(channel: nil)
    private let cameraExposureCompensationWidget = WidgetFactory.shared.createCameraExposureCompensationWidget(channel: nil)
    private let cameraWhiteBalanceWidget = WidgetFactory.shared.createCameraWhiteBalanceWidget(channel: nil)
    public var itemSpacing = 8
    public var itemPadding = 2
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard
            let gimbalOrientationWidget = gimbalOrientationWidget,
            let cameraIsoWidget = cameraIsoWidget,
            let cameraShutterWidget = cameraShutterWidget,
            let cameraApertureWidget = cameraApertureWidget,
            let cameraExposureCompensationWidget = cameraExposureCompensationWidget,
            let cameraWhiteBalanceWidget = cameraWhiteBalanceWidget
        else {
            return
        }
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        view.addSubview(gimbalOrientationWidget.view)
        gimbalOrientationWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalToSuperview().offset(itemPadding)
        }
        
        view.addSubview(cameraIsoWidget.view)
        cameraIsoWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(gimbalOrientationWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraShutterWidget.view)
        cameraShutterWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(cameraIsoWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraApertureWidget.view)
        cameraApertureWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(cameraShutterWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraExposureCompensationWidget.view)
        cameraExposureCompensationWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(cameraApertureWidget.view.snp.right).offset(itemSpacing)
        }
        
        view.addSubview(cameraWhiteBalanceWidget.view)
        cameraWhiteBalanceWidget.view.snp.makeConstraints { [weak self] make in
            make.top.equalToSuperview().offset(itemPadding)
            make.bottom.equalToSuperview().offset(-itemPadding)
            make.left.equalTo(cameraExposureCompensationWidget.view.snp.right).offset(itemSpacing)
            make.right.equalToSuperview().offset(-itemPadding)
        }
    }
}
