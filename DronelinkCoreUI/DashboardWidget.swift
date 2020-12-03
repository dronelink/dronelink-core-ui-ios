//
//  DashboardWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/2/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import Foundation
import DronelinkCore
import SwiftyUserDefaults
import MaterialComponents

extension DefaultsKeys {
    var dronelinkDashboardWidgetLegacyDeviceWarningViewed: DefaultsKey<Bool> { .init("dronelinkDashboardWidget.legacyDeviceWarningViewed", defaultValue: false) }
    var dronelinkDashboardWidgetLegacyDeviceWarningDismissed: DefaultsKey<Bool> { .init("dronelinkDashboardWidget.legacyDeviceWarningDismissed", defaultValue: false) }
    var dronelinkDashboardWidgetContentLayout: DefaultsKey<String> { .init("dronelinkDashboardWidget.contentLayout", defaultValue: ContentLayout.cameraFeedMap.rawValue) }
    var dronelinkDashboardWidgetMapStyle: DefaultsKey<String> { .init("dronelinkDashboardWidget.mapStyle", defaultValue: MapStyle.mapbox.rawValue) }
}


extension DashboardWidget {
    private var legacyDeviceWarningViewed: Bool {
        get { Defaults[\.dronelinkDashboardWidgetLegacyDeviceWarningViewed] }
        set { Defaults[\.dronelinkDashboardWidgetLegacyDeviceWarningViewed]  = newValue }
    }
    
    private var legacyDeviceWarningDismissed: Bool {
        get { Defaults[\.dronelinkDashboardWidgetLegacyDeviceWarningDismissed] }
        set { Defaults[\.dronelinkDashboardWidgetLegacyDeviceWarningDismissed]  = newValue }
    }
    
    private var contentLayout: ContentLayout {
        get { contentLayoutStatic ? .cameraFeedMap : (ContentLayout(rawValue: Defaults[\.dronelinkDashboardWidgetContentLayout]) ?? .cameraFeed) }
        set { Defaults[\.dronelinkDashboardWidgetContentLayout] = newValue.rawValue }
    }
    
    private var contentLayoutStatic: Bool { portrait }
    
    private var mapStyle: MapStyle {
        get { MapStyle(rawValue: Defaults[\.dronelinkDashboardWidgetMapStyle]) ?? .mapbox }
        set { Defaults[\.dronelinkDashboardWidgetMapStyle] = newValue.rawValue }
    }
}


private enum MapStyle: String {
    case mapbox = "mapbox",
         microsoft = "microsoft",
         none = "none"
}

private enum ContentLayout: String {
    case cameraFeed = "cameraFeed",
         cameraFeedMap = "cameraFeedMap",
         mapCameraFeed = "mapCameraFeed"
    
    var next: ContentLayout {
        switch self {
        case .cameraFeed: return .cameraFeedMap
        case .cameraFeedMap: return .mapCameraFeed
        case .mapCameraFeed: return .cameraFeed
        }
    }
    
    var cameraFeedPrimary: Bool {
        switch self {
        case .cameraFeed, .cameraFeedMap: return true
        case .mapCameraFeed: return false
        }
    }
}

public class DashboardWidget: DelegateWidget {
    public static func create(microsoftMapCredentialsKey: String? = nil) -> DashboardWidget {
        let dashboardViewController = DashboardWidget()
        dashboardViewController.microsoftMapCredentialsKey = microsoftMapCredentialsKey
        dashboardViewController.modalPresentationStyle = .fullScreen
        return dashboardViewController
    }
    
    private var portrait: Bool { return UIScreen.main.bounds.width < UIScreen.main.bounds.height }
    private var tablet: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    private var statusWidgetHeight: CGFloat { return tablet ? 50 : 40 }
    private let defaultPadding = 10
    
    private var microsoftMapCredentialsKey: String?
    
    private let _dismissButton = UIButton(type: .custom)
    public var dismissButton: UIButton { _dismissButton }
    
    private let topBarView = UIView()
    private let contentLayoutVisibilityButton = UIButton(type: .custom)
    private let contentLayoutExpandButton = UIButton(type: .custom)
    private let primaryContentView = UIView()
    private let secondaryContentView = UIView()
    private let cameraControlsView = UIView()
    private let cameraGeneralSettingsButton = UIButton(type: .custom)
    private let cameraExposureSettingsButton = UIButton(type: .custom)
    private var overlayViewController: UIViewController?
    private let hideOverlayButton = UIButton(type: .custom)
    
    private let disconnectedImageView = UIImageView()
    private var cameraFeedWidget: Widget?
    private var cameraFeedContentView: UIView { contentLayout.cameraFeedPrimary ? primaryContentView : secondaryContentView }
    private var mapWidget: Widget?
    private var mapContentView: UIView? {
        switch contentLayout {
        case .cameraFeed: return nil
        case .cameraFeedMap: return secondaryContentView
        case .mapCameraFeed: return primaryContentView
        }
    }
    private var statusBackgroundWidget: Widget?
    private var statusForegroundWidget: Widget?
    private var remainingFlightTimeWidget: Widget?
    private var flightModeWidget: Widget?
    private var gpsWidget: Widget?
    private var visionWidget: Widget?
    private var uplinkWidget: Widget?
    private var downlinkWidget: Widget?
    private var batteryWidget: Widget?
    private var primaryIndicatorWidgets: [(widget: Widget, widthRatio: CGFloat)] {
        var widgets: [(widget: Widget, widthRatio: CGFloat)] = []
        if let widget = flightModeWidget { widgets.append((widget: widget, widthRatio: 4.5)) }
        if let widget = gpsWidget { widgets.append((widget: widget, widthRatio: 1.75)) }
        if let widget = visionWidget { widgets.append((widget: widget, widthRatio: 1.35)) }
        if let widget = uplinkWidget { widgets.append((widget: widget, widthRatio: 2.5)) }
        if let widget = downlinkWidget { widgets.append((widget: widget, widthRatio: 2.75)) }
        if let widget = batteryWidget { widgets.append((widget: widget, widthRatio: 2.75)) }
        return widgets
    }
    private var cameraModeWidget: Widget?
    private var cameraCaptureWidget: Widget?
    private var compassWidget: Widget?
    
    private var funcViewController: FuncViewController?
    private var funcExpanded = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }

        view.backgroundColor = UIColor.black
        
        hideOverlayButton.addTarget(self, action: #selector(onHideOverlay(sender:)), for: .touchUpInside)
        view.addSubview(hideOverlayButton)
        hideOverlayButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(primaryContentView)
        
        secondaryContentView.addShadow()
        view.addSubview(secondaryContentView)
        
        disconnectedImageView.setImage(DronelinkUI.loadImage(named: "baseline_usb_white_48pt")!)
        disconnectedImageView.tintColor = UIColor.white
        disconnectedImageView.alpha = 0.5
        disconnectedImageView.contentMode = .center
        primaryContentView.addSubview(disconnectedImageView)
        disconnectedImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentLayoutVisibilityButton.backgroundColor = DronelinkUI.Constants.overlayColor.withAlphaComponent(0.5)
        contentLayoutVisibilityButton.tintColor = UIColor.white
        contentLayoutVisibilityButton.setImage(DronelinkUI.loadImage(named: "baseline_map_white_36pt"), for: .normal)
        contentLayoutVisibilityButton.addTarget(self, action: #selector(onContentLayoutVisibility(sender:)), for: .touchUpInside)
        view.addSubview(contentLayoutVisibilityButton)
        contentLayoutVisibilityButton.snp.remakeConstraints { make in
            make.left.equalTo(secondaryContentView.snp.left).offset(8)
            make.bottom.equalTo(secondaryContentView.snp.bottom).offset(-8)
            make.width.equalTo(30)
            make.height.equalTo(contentLayoutVisibilityButton.snp.width)
        }
        
        contentLayoutExpandButton.backgroundColor = DronelinkUI.Constants.overlayColor.withAlphaComponent(0.5)
        contentLayoutExpandButton.tintColor = UIColor.white
        contentLayoutExpandButton.setImage(DronelinkUI.loadImage(named: "baseline_zoom_out_map_white_36pt"), for: .normal)
        contentLayoutExpandButton.addTarget(self, action: #selector(onContentLayoutExpand(sender:)), for: .touchUpInside)
        view.addSubview(contentLayoutExpandButton)
        contentLayoutExpandButton.snp.remakeConstraints { make in
            make.right.equalTo(secondaryContentView.snp.right).offset(-8)
            make.top.equalTo(secondaryContentView.snp.top).offset(8)
            make.width.equalTo(30)
            make.height.equalTo(contentLayoutExpandButton.snp.width)
        }

        cameraControlsView.addShadow()
        cameraControlsView.backgroundColor = DronelinkUI.Constants.overlayColor
        cameraControlsView.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.addSubview(cameraControlsView)
        
        cameraGeneralSettingsButton.setTitle("DashboardWidget.cameraGeneralSettings".localized, for: .normal)
        cameraGeneralSettingsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        cameraGeneralSettingsButton.addTarget(self, action: #selector(onCameraGeneralSettings(sender:)), for: .touchUpInside)
        cameraControlsView.addSubview(cameraGeneralSettingsButton)
        cameraGeneralSettingsButton.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.width.equalTo(48)
        }
        
        cameraExposureSettingsButton.tintColor = UIColor.white
        cameraExposureSettingsButton.setImage(DronelinkUI.loadImage(named: "baseline_tune_white_36pt"), for: .normal)
        cameraExposureSettingsButton.addTarget(self, action: #selector(onCameraExposureSettings(sender:)), for: .touchUpInside)
        cameraControlsView.addSubview(cameraExposureSettingsButton)
        cameraExposureSettingsButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
            make.centerX.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(28)
        }

        view.addSubview(topBarView)
        topBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(statusWidgetHeight)
        }

        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(DronelinkUI.loadImage(named: "dronelink-logo"), for: .normal)
        dismissButton.imageView?.contentMode = .scaleAspectFit
        dismissButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        dismissButton.addTarget(self, action: #selector(onDismiss(sender:)), for: .touchUpInside)
        view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.width.equalTo(statusWidgetHeight * 1.25)
            make.height.equalTo(statusWidgetHeight)
        }

        updateDynamicViews()
        showLegacyDeviceWarning()
    }
    
    func showLegacyDeviceWarning() {
        if Device.legacy {
            if !legacyDeviceWarningDismissed {
                legacyDeviceWarningViewed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    DronelinkUI.shared.showDialog(
                        title: "DashboardWidget.device.legacy.title".localized,
                        details: "DashboardWidget.device.legacy.details".localized,
                        actions: [
                            MDCAlertAction(title: "DashboardWidget.device.legacy.confirm".localized, emphasis: .high, handler: { action in
                            }),
                            MDCAlertAction(title: "DashboardWidget.device.legacy.confirm.dismiss".localized, emphasis: .low, handler: { action in
                                self.legacyDeviceWarningDismissed = true
                            })
                        ])
                }
            }
        }
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.setNeedsUpdateConstraints()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.setNeedsUpdateConstraints()
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        updateDynamicViews()
    }
    
    func onMainMenu() {
        if let widget = widgetFactory.createMainMenuWidget(current: nil) {
            if let wrapperWidget = widget as? WrapperWidget {
                wrapperWidget.viewController?.modalPresentationStyle = .formSheet
            }
            present(widget, animated: true, completion: nil)
        }
    }
    
    @objc func onCameraGeneralSettings(sender: Any) {
        if let widget = widgetFactory.createCameraGeneralSettingsWidget(current: nil) {
            showOverlay(viewController: widget)
        }
        else {
            //FIXME show message that it isn't implemented yet
        }
    }
    
    @objc func onCameraExposureSettings(sender: Any) {
        if let widget = widgetFactory.createCameraExposureSettingsWidget(current: nil) {
            showOverlay(viewController: widget)
        }
        else {
            //FIXME show message that it isn't implemented yet
        }
    }
    
    private func showOverlay(viewController: UIViewController) {
        overlayViewController = viewController
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.view.addShadow()
        
        view.bringSubviewToFront(hideOverlayButton)
        if let overlayView = overlayViewController?.view {
            view.bringSubviewToFront(overlayView)
            overlayView.snp.remakeConstraints { make in
                let bounds = UIScreen.main.bounds
                let width = min(bounds.width - 30, max(bounds.width / 2, 400))
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(width)
                make.height.equalTo(min(bounds.height - 125, width))
            }
        }
        
        hideOverlayButton.isHidden = false
    }
    
    @objc func onHideOverlay(sender: Any!) {
        overlayViewController?.removeFromParent()
        overlayViewController?.view.removeFromSuperview()
        overlayViewController = nil
        hideOverlayButton.isHidden = true
    }
    
    @objc func onContentLayoutVisibility(sender: Any) {
        contentLayout = contentLayout == .cameraFeed ? .cameraFeedMap : .cameraFeed
        updateDynamicViews()
    }
    
    @objc func onContentLayoutExpand(sender: Any) {
        contentLayout = contentLayout.cameraFeedPrimary ? .mapCameraFeed : .cameraFeedMap
        updateDynamicViews()
    }
    
    private func refreshWidget(current: Widget? = nil, next: Widget? = nil, subview: UIView? = nil) -> Widget? {
        let subview: UIView = subview ?? view
        if current != next {
            current?.uninstallFromParent()
            next?.install(inParent: self, insideSubview: subview)
        }
        
        if let next = next {
            if next.view.superview != subview {
                next.view.removeFromSuperview()
                subview.addSubview(next.view)
            }
        }
        
        return next
    }
    
    private func refreshWidgets() {
        cameraFeedWidget = refreshWidget(current: cameraFeedWidget, next: widgetFactory.createCameraFeedWidget(current: cameraFeedWidget, primary: contentLayout.cameraFeedPrimary), subview: cameraFeedContentView)
        cameraFeedWidget?.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        if let contentView = mapContentView, mapStyle != .none {
            switch mapStyle {
            case .mapbox:
                mapWidget = refreshWidget(current: mapWidget, next: (mapWidget as? MapboxMapWidget) ?? MapboxMapWidget(), subview: mapContentView)
                break

            case .microsoft:
                mapWidget = refreshWidget(current: mapWidget, next: nil)
                break

            case .none:
                break
            }
        }
        else {
            mapWidget = refreshWidget(current: mapWidget, next: nil)
        }
        mapWidget?.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        statusBackgroundWidget = refreshWidget(current: statusBackgroundWidget, next: widgetFactory.createStatusBackgroundWidget(current: statusBackgroundWidget), subview: topBarView)
        statusBackgroundWidget?.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        statusForegroundWidget = refreshWidget(current: statusForegroundWidget, next: widgetFactory.createStatusForegroundWidget(current: statusForegroundWidget), subview: topBarView)
        statusForegroundWidget?.view.snp.remakeConstraints { make in
            let constrainTo: UIView = statusBackgroundWidget?.view ?? view
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(dismissButton.snp.right).offset(5)
            make.right.equalToSuperview()
            make.height.equalTo(statusWidgetHeight)
        }
        (statusForegroundWidget as? StatusLabelWidget)?.onTapped = onMainMenu

        remainingFlightTimeWidget = refreshWidget(current: remainingFlightTimeWidget, next: widgetFactory.createRemainingFlightTimeWidget(current: remainingFlightTimeWidget))
        remainingFlightTimeWidget?.view.snp.remakeConstraints { make in
            let topOffset = -9
            if portrait, let cameraFeedView = cameraFeedWidget?.view {
                make.top.equalTo(cameraFeedView.snp.top).offset(topOffset)
            }
            else {
                make.top.equalTo(topBarView.snp.bottom).offset(topOffset)
            }
            make.left.equalTo(topBarView.snp.left)
            make.right.equalTo(topBarView.snp.right)
        }
        
        flightModeWidget = refreshWidget(current: flightModeWidget, next: widgetFactory.createFlightModeWidget(current: flightModeWidget))
        gpsWidget = refreshWidget(current: gpsWidget, next: widgetFactory.createGPSWidget(current: gpsWidget))
        visionWidget = refreshWidget(current: visionWidget, next: widgetFactory.createVisionWidget(current: visionWidget))
        uplinkWidget = refreshWidget(current: uplinkWidget, next: widgetFactory.createUplinkWidget(current: uplinkWidget))
        downlinkWidget = refreshWidget(current: downlinkWidget, next: widgetFactory.createDownlinkWidget(current: downlinkWidget))
        batteryWidget = refreshWidget(current: batteryWidget, next: widgetFactory.createBatteryWidget(current: batteryWidget))
        
        var primaryIndicatorWidgetPrevious: Widget?
        primaryIndicatorWidgets.reversed().forEach { item in
            item.widget.view.snp.remakeConstraints { make in
                let paddingRight: CGFloat = 5
                if let widgetPrevious = primaryIndicatorWidgetPrevious {
                    make.right.equalTo(widgetPrevious.view.snp.left).offset(-paddingRight)
                }
                else {
                    make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-paddingRight)
                }
                let topPadding: CGFloat = 0.25
                make.top.equalTo(topBarView.snp.top).offset((portrait && !tablet ? statusWidgetHeight : 0) + (statusWidgetHeight * topPadding))
                let height = statusWidgetHeight * (1 - (2 * topPadding))
                make.height.equalTo(height)
                make.width.equalTo(item.widget.view.snp.height).multipliedBy(item.widthRatio)
                
            }
            primaryIndicatorWidgetPrevious = item.widget
        }
        
        cameraModeWidget = refreshWidget(current: cameraModeWidget, next: widgetFactory.createCameraModeWidget(current: cameraModeWidget), subview: cameraControlsView)
        cameraModeWidget?.view.snp.remakeConstraints { make in
            make.top.equalTo(cameraGeneralSettingsButton.snp.bottom).offset(-6)
            make.left.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
        }

        cameraCaptureWidget = refreshWidget(current: cameraCaptureWidget, next: widgetFactory.createCameraCaptureWidget(current: cameraCaptureWidget), subview: cameraControlsView)
        cameraCaptureWidget?.view.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(cameraCaptureWidget!.view.snp.width)
            make.bottom.equalTo(cameraExposureSettingsButton.snp.top).offset(-12)
        }

        compassWidget = refreshWidget(current: compassWidget, next: widgetFactory.createCompassWidget(current: compassWidget))
    }
    
    @objc func onDismiss(sender: Any) {
        Dronelink.shared.unload()
        dismiss(animated: true)
    }
    
    public override func onOpened(session: DroneSession) {
        super.onOpened(session: session)
        DispatchQueue.main.async { self.updateDynamicViews() }
    }
    
    public override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
        DispatchQueue.main.async { self.updateDynamicViews() }
    }
    
    public override func onMissionEngaged(executor: MissionExecutor, engagement: Executor.Engagement) {
        super.onMissionEngaged(executor: executor, engagement: engagement)
        DispatchQueue.main.async { self.updateDismissButton() }
    }
    
    public override func onMissionDisengaged(executor: MissionExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onMissionDisengaged(executor: executor, engagement: engagement, reason: reason)
        DispatchQueue.main.async { self.updateDismissButton() }
    }
    
    public override func onModeEngaged(executor: ModeExecutor, engagement: Executor.Engagement) {
        super.onModeEngaged(executor: executor, engagement: engagement)
        DispatchQueue.main.async { self.updateDismissButton() }
    }
    
    public override func onModeDisengaged(executor: ModeExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onModeDisengaged(executor: executor, engagement: engagement, reason: reason)
        DispatchQueue.main.async { self.updateDismissButton() }
    }
    
    func updateDismissButton() {
        dismissButton.isEnabled = !Dronelink.shared.engaged
    }
    
    func updateDynamicViews() {
        refreshWidgets()
        
        disconnectedImageView.isHidden = session != nil
        contentLayoutVisibilityButton.isHidden = contentLayoutStatic
        contentLayoutExpandButton.isHidden = contentLayoutStatic || contentLayout == .cameraFeed

        let darkBackground = UIColor(red: 20, green: 20, blue: 20)
        let darkerBackground = UIColor(red: 10, green: 10, blue: 10)
        primaryContentView.backgroundColor = contentLayout.cameraFeedPrimary ? darkerBackground : darkBackground
        primaryContentView.snp.remakeConstraints { make in
            if (portrait && !tablet) {
                make.top.equalTo(topBarView.safeAreaLayoutGuide.snp.bottom).offset(statusWidgetHeight * 2)
            }
            else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }

            if (portrait) {
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(UIScreen.main.bounds.width * 2/3)
            }
            else {
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }

        secondaryContentView.isHidden = contentLayout == .cameraFeed
        secondaryContentView.backgroundColor = contentLayout.cameraFeedPrimary ? darkBackground : darkerBackground
        secondaryContentView.snp.remakeConstraints { make in
            if (portrait) {
                make.top.equalTo(primaryContentView.snp.bottom).offset(tablet ? 0 : statusWidgetHeight * 2)
                make.right.equalToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            else {
                if tablet {
                    make.width.equalTo(view.snp.width).multipliedBy(funcViewController == nil || !funcExpanded ? 0.4 : 0.30)
                }
                else {
                    make.width.equalTo(view.snp.width).multipliedBy(funcViewController == nil || !funcExpanded ? 0.28 : 0.18)
                }

                make.height.equalTo(secondaryContentView.snp.width).multipliedBy(0.5)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                if !portrait, funcExpanded, let funcViewController = funcViewController {
                    make.left.equalTo(funcViewController.view.snp.right).offset(defaultPadding)
                }
                else {
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                }
            }
        }

        cameraControlsView.snp.remakeConstraints { make in
            make.centerY.equalTo(primaryContentView.snp.centerY)
            if (portrait || tablet) {
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
            }
            else {
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            }
            make.height.equalTo(205)
            make.width.equalTo(70)
        }

        compassWidget?.view.snp.remakeConstraints { make in
            if (portrait && tablet) {
                make.bottom.equalTo(secondaryContentView.snp.top).offset(-defaultPadding)
                make.height.equalTo(primaryContentView.snp.width).multipliedBy(0.15)
                make.right.equalTo(cameraControlsView.snp.right)
                make.width.equalTo(compassWidget!.view.snp.height)
                return
            }

            if (portrait) {
                make.bottom.equalTo(secondaryContentView.snp.top).offset(-5)
                make.height.equalTo(compassWidget!.view.snp.width)
                make.centerX.equalTo(cameraControlsView.snp.centerX)
                make.width.equalTo(cameraControlsView.snp.width)
                return
            }

            make.bottom.equalTo(secondaryContentView.snp.bottom)
            make.height.equalTo(primaryContentView.snp.width).multipliedBy(tablet ? 0.12 : 0.09)
            make.right.equalTo(tablet ? cameraControlsView.snp.right : cameraControlsView.snp.left).offset(tablet ? 0 : -defaultPadding)
            make.width.equalTo(compassWidget!.view.snp.height)
        }
    }
}
