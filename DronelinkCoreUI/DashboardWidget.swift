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
    
    private var statusWidgetHeight: CGFloat { return tablet ? 50 : 40 }
    
    private var microsoftMapCredentialsKey: String?
    
    private let _dismissButton = UIButton(type: .custom)
    public var dismissButton: UIButton { _dismissButton }
    
    private let topBarView = UIView()
    private let contentSettingsButton = UIButton(type: .custom)
    private let contentLayoutVisibilityButton = UIButton(type: .custom)
    private let contentLayoutMapHideImage = DronelinkUI.loadImage(named: "eye-off")
    private let contentLayoutMapShowImage = DronelinkUI.loadImage(named: "baseline_map_white_36pt")
    private let contentLayoutExpandButton = UIButton(type: .custom)
    private let primaryContentView = UIView()
    private let reticleImageView = UIImageView()
    private let secondaryContentView = UIView()
    private let cameraControlsView = UIView()
    private let cameraMenuButton = UIButton(type: .custom)
    private let cameraExposureMenuButton = UIButton(type: .custom)
    private let offsetsButton = UIButton(type: .custom)
    private var offsetsButtonEnabled = false
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
        if let widget = flightModeWidget { widgets.append((widget: widget, widthRatio: 4)) }
        if let widget = gpsWidget { widgets.append((widget: widget, widthRatio: 2.5)) }
        if let widget = visionWidget { widgets.append((widget: widget, widthRatio: 1.35)) }
        if let widget = uplinkWidget { widgets.append((widget: widget, widthRatio: 2.5)) }
        if let widget = downlinkWidget { widgets.append((widget: widget, widthRatio: 2.5)) }
        if let widget = batteryWidget { widgets.append((widget: widget, widthRatio: 3.4)) }
        return widgets
    }
    private var cameraAutoExposureWidget: Widget?
    private var cameraExposureFocusWidget: Widget?
    private var cameraFocusModeWidget: Widget?
    private var cameraStorageWidget: Widget?
    private var cameraExposureWidget: Widget?
    private var cameraIndicatorWidgets: [(widget: Widget, width: Bool)] {
        var widgets: [(widget: Widget, width: Bool)] = []
        if let widget = cameraExposureWidget { widgets.append((widget: widget, width: false)) }
        if let widget = cameraStorageWidget { widgets.append((widget: widget, width: false)) }
        if let widget = cameraAutoExposureWidget { widgets.append((widget: widget, width: true)) }
        if let widget = cameraExposureFocusWidget { widgets.append((widget: widget, width: true)) }
        if let widget = cameraFocusModeWidget { widgets.append((widget: widget, width: true)) }
        return widgets
    }
    private var cameraModeWidget: Widget?
    private var cameraCaptureWidget: Widget?
    private var compassWidget: Widget?
    private var telemetryWidget: Widget?
    private var executorWidget: ExecutorWidget?
    private var executorLayout: ExecutorWidgetLayout { executorWidget?.layout ?? .small }
    private var droneOffsetsWidget1: Widget?
    private var droneOffsetsWidget2: Widget?
    private var cameraOffsetsWidget: Widget?
    private var rtkStatusWidget: Widget?
    
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
        
        reticleImageView.isUserInteractionEnabled = false
        reticleImageView.contentMode = .scaleAspectFit
        view.addSubview(reticleImageView)
        reticleImageView.snp.makeConstraints { make in
            make.center.equalTo(primaryContentView)
            make.height.equalTo(primaryContentView)
        }
        
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
        
        contentSettingsButton.addShadow()
        contentSettingsButton.tintColor = UIColor.white
        contentSettingsButton.setImage(DronelinkUI.loadImage(named: "baseline_settings_white_36pt"), for: .normal)
        contentSettingsButton.addTarget(self, action: #selector(onContentSettings(sender:)), for: .touchUpInside)
        view.addSubview(contentSettingsButton)
        contentSettingsButton.snp.remakeConstraints { make in
            make.left.equalTo(secondaryContentView.snp.left).offset(8)
            make.top.equalTo(secondaryContentView.snp.top).offset(8)
            make.width.equalTo(30)
            make.height.equalTo(contentSettingsButton.snp.width)
        }

        contentLayoutVisibilityButton.addShadow()
        contentLayoutVisibilityButton.tintColor = UIColor.white
        contentLayoutVisibilityButton.setImage(contentLayoutMapShowImage, for: .normal)
        contentLayoutVisibilityButton.addTarget(self, action: #selector(onContentLayoutVisibility(sender:)), for: .touchUpInside)
        view.addSubview(contentLayoutVisibilityButton)
        contentLayoutVisibilityButton.snp.remakeConstraints { make in
            make.left.equalTo(secondaryContentView.snp.left).offset(8)
            make.bottom.equalTo(secondaryContentView.snp.bottom).offset(-8)
            make.width.equalTo(30)
            make.height.equalTo(contentLayoutVisibilityButton.snp.width)
        }
        
        contentLayoutExpandButton.addShadow()
        contentLayoutExpandButton.tintColor = UIColor.white
        contentLayoutExpandButton.setImage(DronelinkUI.loadImage(named: "vector-arrange-below"), for: .normal)
        contentLayoutExpandButton.addTarget(self, action: #selector(onContentLayoutExpand(sender:)), for: .touchUpInside)
        view.addSubview(contentLayoutExpandButton)
        contentLayoutExpandButton.snp.remakeConstraints { make in
            make.right.equalTo(secondaryContentView.snp.right).offset(-8)
            make.top.equalTo(secondaryContentView.snp.top).offset(8)
            make.width.equalTo(30)
            make.height.equalTo(contentLayoutExpandButton.snp.width)
        }

        view.addSubview(cameraControlsView)
        
        cameraMenuButton.addShadow()
        cameraMenuButton.setTitle("DashboardWidget.cameraMenu".localized, for: .normal)
        cameraMenuButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        cameraMenuButton.addTarget(self, action: #selector(onCameraMenu(sender:)), for: .touchUpInside)
        cameraControlsView.addSubview(cameraMenuButton)
        cameraMenuButton.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.width.equalTo(48)
        }
        
        cameraExposureMenuButton.addShadow()
        cameraExposureMenuButton.tintColor = UIColor.white
        cameraExposureMenuButton.setImage(DronelinkUI.loadImage(named: "baseline_tune_white_36pt"), for: .normal)
        cameraExposureMenuButton.addTarget(self, action: #selector(onCameraExposureMenu(sender:)), for: .touchUpInside)
        cameraControlsView.addSubview(cameraExposureMenuButton)
        cameraExposureMenuButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
            make.centerX.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(28)
        }
        
        offsetsButton.addShadow()
        offsetsButton.setImage(DronelinkUI.loadImage(named: "baseline_control_camera_white_36pt"), for: .normal)
        offsetsButton.addTarget(self, action: #selector(onOffsets(sender:)), for: .touchUpInside)
        view.addSubview(offsetsButton)
        offsetsButton.snp.makeConstraints { make in
            make.top.equalTo(cameraControlsView.snp.bottom).offset(15)
            make.centerX.equalTo(cameraControlsView.snp.centerX)
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

        dismissButton.addShadow()
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
    
    func onMainMenu() {
        if let widget = widgetFactory.createMainMenuWidget(current: nil) {
            if let wrapperWidget = widget as? WrapperWidget {
                wrapperWidget.viewController?.modalPresentationStyle = .formSheet
            }
            present(widget, animated: true, completion: nil)
        }
    }
    
    @objc func onCameraMenu(sender: Any) {
        if let widget = widgetFactory.createCameraMenuWidget(current: nil) {
            showOverlay(viewController: widget)
        }
    }
    
    @objc func onCameraExposureMenu(sender: Any) {
        if let widget = widgetFactory.createCameraExposureMenuWidget(current: nil) {
            showOverlay(viewController: widget)
        }
    }
    
    @objc func onOffsets(sender: Any) {
        toggleOffsets()
    }
    
    private func toggleOffsets(visible: Bool? = nil) {
        if let visible = visible {
            if (visible && droneOffsetsWidget1 != nil) || (!visible && droneOffsetsWidget1 == nil) {
                return
            }
        }
        
        if let droneOffsetsWidget = droneOffsetsWidget1 {
            droneOffsetsWidget.uninstallFromParent()
            self.droneOffsetsWidget1 = nil
        }
        else {
            let droneOffsetsWidget = DroneOffsetsWidget()
            droneOffsetsWidget.styles = tablet ? [.position] : [.altYaw, .position]
            droneOffsetsWidget.install(inParent: self)
            self.droneOffsetsWidget1 = droneOffsetsWidget
        }
        
        if tablet {
            if let droneOffsetsWidget = self.droneOffsetsWidget2 {
                droneOffsetsWidget.uninstallFromParent()
                self.droneOffsetsWidget2 = nil
            }
            else {
                let droneOffsetsWidget = DroneOffsetsWidget()
                droneOffsetsWidget.styles = [.altYaw]
                droneOffsetsWidget.install(inParent: self)
                self.droneOffsetsWidget2 = droneOffsetsWidget
            }
        }
        
        if let cameraOffsetsWidget = self.cameraOffsetsWidget {
            cameraOffsetsWidget.uninstallFromParent()
            self.cameraOffsetsWidget = nil
        }
        else {
            let cameraOffsetsWidget = CameraOffsetsWidget()
            cameraOffsetsWidget.install(inParent: self)
            self.cameraOffsetsWidget = cameraOffsetsWidget
        }
        
        view.setNeedsUpdateConstraints()
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
    
    @objc func onContentSettings(sender: Any) {
        let alert = UIAlertController(title: "DashboardWidget.contentSettings".localized, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender as? UIView
        
        if mapWidget is MicrosoftMapWidget {
            alert.addAction(UIAlertAction(title: "DashboardWidget.map.mapbox".localized, style: .default, handler: { _ in
                self.mapStyle = .mapbox
                self.view.setNeedsUpdateConstraints()
            }))
        }
        else if mapWidget is MapboxMapWidget {
            alert.addAction(UIAlertAction(title: "DashboardWidget.map.microsoft".localized, style: .default, handler: { _ in
                self.mapStyle = .microsoft
                self.view.setNeedsUpdateConstraints()
            }))
        }

        (mapWidget as? ConfigurableWidget)?.configurationActions.forEach { alert.addAction($0) }

        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler: { _ in

        }))

        present(alert, animated: true)
    }
    
    @objc func onContentLayoutVisibility(sender: Any) {
        contentLayout = contentLayout == .cameraFeed ? .cameraFeedMap : .cameraFeed
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onContentLayoutExpand(sender: Any) {
        contentLayout = contentLayout.cameraFeedPrimary ? .mapCameraFeed : .cameraFeedMap
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onDismiss(sender: Any) {
        Dronelink.shared.unload()
        dismiss(animated: true)
    }
    
    open override func onOpened(session: DroneSession) {
        super.onOpened(session: session)
        DispatchQueue.main.async { self.view.setNeedsUpdateConstraints() }
    }
    
    open override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
        DispatchQueue.main.async { self.view.setNeedsUpdateConstraints() }
    }
    
    open override func onInitialized(session: DroneSession) {
        super.onInitialized(session: session)
        
        if let cameraState = session.cameraState(channel: 0), !cameraState.value.isSDCardInserted {
            DronelinkUI.shared.showDialog(title: "DashboardWidget.camera.noSDCard.title".localized, details: "DashboardWidget.camera.noSDCard.details".localized)
        }
    }
    
    open override func onMissionLoaded(executor: MissionExecutor) {
        super.onMissionLoaded(executor: executor)
        DispatchQueue.main.async { self.apply(userInterfaceSettings: executor.userInterfaceSettings) }
    }
    
    open override func onMissionUnloaded(executor: MissionExecutor) {
        super.onMissionUnloaded(executor: executor)
        DispatchQueue.main.async { self.apply(userInterfaceSettings: nil) }
    }
    
    open override func onMissionEngaged(executor: MissionExecutor, engagement: Executor.Engagement) {
        super.onMissionEngaged(executor: executor, engagement: engagement)
        DispatchQueue.main.async { self.view.setNeedsUpdateConstraints() }
    }
    
    open override func onMissionDisengaged(executor: MissionExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onMissionDisengaged(executor: executor, engagement: engagement, reason: reason)
        DispatchQueue.main.async { self.view.setNeedsUpdateConstraints() }
    }
    
    open override func onModeLoaded(executor: ModeExecutor) {
        super.onModeLoaded(executor: executor)
        DispatchQueue.main.async { self.apply(userInterfaceSettings: executor.userInterfaceSettings) }
    }
    
    open override func onModeUnloaded(executor: ModeExecutor) {
        super.onModeUnloaded(executor: executor)
        DispatchQueue.main.async { self.apply(userInterfaceSettings: nil) }
    }
    
    open override func onModeEngaged(executor: ModeExecutor, engagement: Executor.Engagement) {
        super.onModeEngaged(executor: executor, engagement: engagement)
        DispatchQueue.main.async { self.updateDismissButton() }
    }
    
    open override func onModeDisengaged(executor: ModeExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onModeDisengaged(executor: executor, engagement: engagement, reason: reason)
        DispatchQueue.main.async { self.updateDismissButton() }
    }
    
    open override func onFuncLoaded(executor: FuncExecutor) {
        super.onFuncLoaded(executor: executor)
        DispatchQueue.main.async {
            self.apply(userInterfaceSettings: executor.userInterfaceSettings)
        }
    }
    
    open override func onFuncUnloaded(executor: FuncExecutor) {
        super.onFuncUnloaded(executor: executor)
        DispatchQueue.main.async {
            if Dronelink.shared.executor == nil {
                self.apply(userInterfaceSettings: nil)
            }
            else {
                self.view.setNeedsUpdateConstraints()
            }
        }
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
    
    private func apply(userInterfaceSettings: Kernel.UserInterfaceSettings?) {
        reticleImageView.image = nil
        if let reticleImageUrl = userInterfaceSettings?.reticleImageUrl {
            reticleImageView.kf.setImage(with: URL(string: reticleImageUrl))
        }
        
        if let droneOffsetsVisible = userInterfaceSettings?.droneOffsetsVisible {
            offsetsButtonEnabled = droneOffsetsVisible
            toggleOffsets(visible: droneOffsetsVisible)
        }
        else {
            offsetsButtonEnabled = false
            toggleOffsets(visible: false)
        }
        
        view.setNeedsUpdateConstraints()
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
                mapWidget = refreshWidget(current: mapWidget, next: (mapWidget as? MicrosoftMapWidget) ?? MicrosoftMapWidget(), subview: mapContentView)
                (mapWidget as? MicrosoftMapWidget)?.mapView.credentialsKey = microsoftMapCredentialsKey ?? ""
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

        remainingFlightTimeWidget = refreshWidget(current: remainingFlightTimeWidget, next: widgetFactory.createRemainingFlightTimeWidget(current: remainingFlightTimeWidget))
        remainingFlightTimeWidget?.view.snp.remakeConstraints { make in
            let topOffset = -9
            if portrait, !tablet, let cameraFeedView = cameraFeedWidget?.view {
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
                let paddingRight: CGFloat = tablet ? 9 : 7
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
        
        statusBackgroundWidget = refreshWidget(current: statusBackgroundWidget, next: widgetFactory.createStatusBackgroundWidget(current: statusBackgroundWidget), subview: topBarView)
        statusBackgroundWidget?.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        statusForegroundWidget = refreshWidget(current: statusForegroundWidget, next: widgetFactory.createStatusForegroundWidget(current: statusForegroundWidget), subview: topBarView)
        statusForegroundWidget?.view.snp.remakeConstraints { make in
            let constrainTo: UIView = statusBackgroundWidget?.view ?? view
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(dismissButton.snp.right).offset(5)
            if (portrait && !tablet) {
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            }
            else {
                make.right.equalTo(primaryIndicatorWidgetPrevious?.view.snp.left ?? constrainTo.snp.right).offset(-defaultPadding)
            }
            make.height.equalTo(statusWidgetHeight)
        }
        (statusForegroundWidget as? StatusLabelWidget)?.onTapped = onMainMenu
        
        cameraExposureWidget = refreshWidget(current: cameraExposureWidget, next: widgetFactory.createCameraExposureWidget(current: cameraExposureWidget))
        
        cameraStorageWidget = refreshWidget(current: cameraStorageWidget, next: widgetFactory.createCameraStorageWidget(current: cameraStorageWidget))
        
        cameraAutoExposureWidget = refreshWidget(current: cameraAutoExposureWidget, next: widgetFactory.createCameraAutoExposureWidget(current: cameraAutoExposureWidget))
        
        cameraExposureFocusWidget = refreshWidget(current: cameraExposureFocusWidget, next: widgetFactory.createCameraExposureFocusWidget(current: cameraExposureFocusWidget))
        
        cameraFocusModeWidget = refreshWidget(current: cameraFocusModeWidget, next: widgetFactory.createCameraFocusModeWidget(current: cameraFocusModeWidget))
        
        let cameraWidgetSize = statusWidgetHeight * 0.65
        var cameraIndicatorWidgetPrevious: Widget?
        cameraIndicatorWidgets.reversed().forEach { item in
            item.widget.view.snp.remakeConstraints { make in
                if let previousWidget = cameraIndicatorWidgetPrevious {
                    make.top.equalTo(previousWidget.view.snp.top)
                    make.right.equalTo(previousWidget.view.snp.left).offset(-defaultPadding / 2)
                }
                else {
                    make.top.equalTo((primaryIndicatorWidgetPrevious?.view ?? topBarView).snp.bottom).offset(portrait && !tablet ? 14 : 20)
                    make.right.equalToSuperview().offset(portrait && !tablet ? -5 : -defaultPadding)
                }
                make.height.equalTo(cameraWidgetSize)
                if item.width {
                    make.width.equalTo(cameraWidgetSize)
                }
            }
            
            cameraIndicatorWidgetPrevious = item.widget
        }
        
        cameraModeWidget = refreshWidget(current: cameraModeWidget, next: widgetFactory.createCameraModeWidget(current: cameraModeWidget), subview: cameraControlsView)
        cameraModeWidget?.view.snp.remakeConstraints { make in
            make.top.equalTo(cameraMenuButton.snp.bottom).offset(-13)
            make.left.equalToSuperview().offset(3)
            make.height.equalTo(cameraModeWidget!.view.snp.width)
            make.right.equalToSuperview().offset(-3)
        }

        cameraCaptureWidget = refreshWidget(current: cameraCaptureWidget, next: widgetFactory.createCameraCaptureWidget(current: cameraCaptureWidget), subview: cameraControlsView)
        cameraCaptureWidget?.view.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(cameraCaptureWidget!.view.snp.width).offset(20)
            make.bottom.equalTo(cameraExposureMenuButton.snp.top).offset(-5)
        }

        compassWidget = refreshWidget(current: compassWidget, next: widgetFactory.createCompassWidget(current: compassWidget))
       
        telemetryWidget = refreshWidget(current: telemetryWidget, next: widgetFactory.createTelemetryWidget(current: telemetryWidget))
        
        executorWidget = refreshWidget(current: executorWidget, next: widgetFactory.createExecutorWidget(current: executorWidget)) as? ExecutorWidget
        
        rtkStatusWidget = refreshWidget(current: rtkStatusWidget, next: widgetFactory.createRTKStatusWidget(current: rtkStatusWidget))
        rtkStatusWidget?.view.snp.remakeConstraints { make in
            make.bottom.equalTo(cameraControlsView.snp.top).offset(-defaultPadding)
            make.right.equalTo(cameraControlsView.snp.right)
            make.height.equalTo(cameraWidgetSize)
            make.width.equalTo(100)
        }
    }
    
    func updateDismissButton() {
        dismissButton.isEnabled = !Dronelink.shared.engaged
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()

        refreshWidgets()
        
        disconnectedImageView.isHidden = true //session != nil
        contentSettingsButton.isHidden = !contentLayoutStatic && contentLayout == .cameraFeed
        contentLayoutVisibilityButton.isHidden = contentLayoutStatic
        contentLayoutVisibilityButton.setImage(contentLayout == .cameraFeed ? contentLayoutMapShowImage : contentLayoutMapHideImage, for: .normal)
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
                    make.width.equalTo(view.snp.width).multipliedBy(executorLayout == .large ? 0.30 : 0.4)
                }
                else {
                    make.width.equalTo(view.snp.width).multipliedBy(executorLayout == .large ? 0.18 : 0.28)
                }

                make.height.equalTo(secondaryContentView.snp.width).multipliedBy(0.5)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                if !portrait, executorLayout == .large, let executorWidget = executorWidget {
                    make.left.equalTo(executorWidget.view.snp.right).offset(defaultPadding)
                }
                else {
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                }
            }
        }
        
        cameraMenuButton.isHidden = !widgetFactory.cameraMenuWidgetEnabled
        cameraExposureMenuButton.isHidden = !widgetFactory.cameraExposureMenuWidgetEnabled

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
        
        offsetsButton.isHidden = !offsetsButtonEnabled
        offsetsButton.tintColor = droneOffsetsWidget1 == nil ? UIColor.white : DronelinkUI.Constants.secondaryColor
        
        telemetryWidget?.view.snp.remakeConstraints { make in
            if (portrait) {
                make.bottom.equalTo(secondaryContentView.snp.top).offset(tablet ? -defaultPadding : -2)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
            }
            else {
                make.bottom.equalTo(secondaryContentView.snp.bottom)
                make.left.equalTo((secondaryContentView.isHidden ? contentLayoutVisibilityButton : secondaryContentView).snp.right).offset(defaultPadding)
            }
            make.height.equalTo(tablet ? 85 : 75)
            make.width.equalTo(tablet ? 350 : 275)
        }
        
        if let droneOffsetsWidget1 = droneOffsetsWidget1 {
            droneOffsetsWidget1.view.snp.remakeConstraints { make in
                make.height.equalTo(240)
                make.width.equalTo(200)
                if portrait {
                    make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
                    make.top.equalTo(secondaryContentView.snp.top).offset(defaultPadding)
                }
                else {
                    make.right.equalTo(cameraControlsView.snp.left).offset(-defaultPadding)
                    make.top.equalTo(topBarView.snp.bottom).offset(45)
                }
            }
            
            if let droneOffsetsWidget2 = droneOffsetsWidget2 {
                droneOffsetsWidget2.view.snp.remakeConstraints { make in
                    make.height.equalTo(droneOffsetsWidget1.view)
                    make.width.equalTo(droneOffsetsWidget1.view)
                    make.right.equalTo(droneOffsetsWidget1.view)
                    make.top.equalTo(droneOffsetsWidget1.view.snp.bottom).offset(defaultPadding)
                }
            }
            
            if let cameraOffsetsWidget = cameraOffsetsWidget {
                cameraOffsetsWidget.view.snp.remakeConstraints { make in
                    make.height.equalTo(65)
                    make.width.equalTo(droneOffsetsWidget1.view)
                    make.right.equalTo(droneOffsetsWidget1.view)
                    make.top.equalTo((droneOffsetsWidget2 ?? droneOffsetsWidget1).view.snp.bottom).offset(defaultPadding)
                }
            }
        }
        
        executorWidget?.view.snp.remakeConstraints { make in
            let preferredSize = (executorWidget as? ExecutorWidget)?.preferredSize ?? CGSize(width: 0, height: 0)
            if executorWidget is FuncExecutorWidget {
                let large = tablet || portrait
                if (executorLayout == .large) {
                    if (portrait) {
                        make.height.equalTo(tablet ? 550 : 300)
                    }
                    else {
                        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    }
                }
                else {
                    make.height.equalTo(185)
                }
                
                if (portrait && tablet) {
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                    make.width.equalTo(large ? 350 : 310)
                    return
                }
                
                if (portrait) {
                    make.right.equalToSuperview()
                    make.left.equalToSuperview()
                    make.top.equalTo(secondaryContentView.snp.top)
                    return
                }
                
                make.top.equalTo(topBarView.snp.bottom).offset(defaultPadding)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                make.width.equalTo(large ? 350 : 310)
                return
            }
            
            if (portrait && tablet) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                make.width.equalToSuperview().multipliedBy(0.35)
                if (executorLayout == .small) {
                    make.height.equalTo(preferredSize.height)
                }
                else {
                    make.top.equalTo(secondaryContentView.snp.top).offset(defaultPadding)
                }
                return
            }
            
            if (portrait) {
                make.right.equalToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalToSuperview()
                if (executorLayout == .small) {
                    make.height.equalTo(preferredSize.height)
                }
                else {
                    make.height.equalTo(secondaryContentView.snp.height).multipliedBy(0.5)
                }
                return
            }
            
            make.top.equalTo(topBarView.snp.bottom).offset(defaultPadding)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
            if (tablet) {
                make.width.equalTo(preferredSize.width)
            }
            else {
                make.width.equalToSuperview().multipliedBy(0.4)
            }
            
            if (executorLayout == .small) {
                make.height.equalTo(preferredSize.height)
            }
            else {
                if (tablet) {
                    make.height.equalTo(preferredSize.height)
                }
                else {
                    make.bottom.equalTo(secondaryContentView.snp.top).offset(-Double(defaultPadding) * 1.5)
                }
            }
        }
    }
    
    //work-around for this: https://github.com/flutter/flutter/issues/35784
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}
