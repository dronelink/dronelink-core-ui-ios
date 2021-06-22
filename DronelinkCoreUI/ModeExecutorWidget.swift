//
//  ModeExecutorWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/7/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import DronelinkCore
import Foundation
import CoreLocation
import UIKit
import SnapKit
import Agrume
import MaterialComponents.MaterialPalettes
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialProgressView
import MaterialComponents.MDCActivityIndicator

public class ModeExecutorWidget: UpdatableWidget, ExecutorWidget {
    public override var updateInterval: TimeInterval { 0.5 }
    
    public var layout: DynamicSizeWidgetLayout = .small
    
    public var preferredSize: CGSize {
        if (portrait && tablet) {
            return CGSize(width: 0, height: layout == .small ? 0 : 80)
        }
        
        if (portrait) {
            return CGSize(width: 0, height: layout == .small ? 100 : 80)
        }
        
        return CGSize(width: tablet ? 350 : 0, height: layout == .small ? 80 : (tablet ? 180 : 0))
    }
    
    private let activityIndicator = MDCActivityIndicator()
    private let primaryButton = MDCFloatingButton()
    private let layoutToggleButton = UIButton()
    private let countdownProgressView = MDCProgressView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let executionDurationLabel = UILabel()
    private let messagesTextView = UITextView()
    private let dismissButton = UIButton(type: .custom)
    
    private let primaryEngagedColor = DronelinkUI.Constants.secondaryColor
    private let primaryDisengagedColor = DronelinkUI.Constants.primaryColor
    private let progressEngagedColor = MDCPalette.pink.accent400
    private let progressDisengagedColor = MDCPalette.deepPurple.accent200
    private let cancelImage = DronelinkUI.loadImage(named: "baseline_close_white_36pt")
    private let engageImage = DronelinkUI.loadImage(named: "baseline_play_arrow_white_36pt")
    private let disengageImage = DronelinkUI.loadImage(named: "baseline_pause_white_36pt")
    
    private var countdownTimer: Timer?
    private var countdownRemaining = 0
    private var countdownMax = 60
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        countdownProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.75)
        countdownProgressView.isHidden = true
        view.addSubview(countdownProgressView)

        activityIndicator.radius = 20
        activityIndicator.strokeWidth = 5
        activityIndicator.cycleColors = [progressEngagedColor!]
        view.addSubview(activityIndicator)
        
        primaryButton.tintColor = UIColor.white
        primaryButton.addTarget(self, action: #selector(onPrimary(sender:)), for: .touchUpInside)
        view.addSubview(primaryButton)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textColor = UIColor.white
        view.addSubview(titleLabel)
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.minimumScaleFactor = 0.5
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.textColor = UIColor.white
        view.addSubview(subtitleLabel)
        
        executionDurationLabel.font = executionDurationLabel.font.withSize(15)
        executionDurationLabel.textColor = titleLabel.textColor
        executionDurationLabel.minimumScaleFactor = 0.5
        executionDurationLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(executionDurationLabel)
        
        messagesTextView.backgroundColor = UIColor.clear
        messagesTextView.font = UIFont.systemFont(ofSize: 12)
        messagesTextView.textColor = UIColor.white
        messagesTextView.isScrollEnabled = true
        messagesTextView.isEditable = false
        view.addSubview(messagesTextView)
        
        layoutToggleButton.addTarget(self, action: #selector(onLayoutToggle), for: .touchUpInside)
        view.addSubview(layoutToggleButton)
        
        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(DronelinkUI.loadImage(named: "baseline_close_white_36pt"), for: .normal)
        dismissButton.addTarget(self, action: #selector(onDismiss), for: .touchUpInside)
        view.addSubview(dismissButton)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let labelHeight = 30
        
        primaryButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(60)
            make.width.equalTo(primaryButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(15)
        }
        
        activityIndicator.snp.remakeConstraints { [weak self] make in
            make.edges.equalTo(primaryButton)
        }
        
        layoutToggleButton.snp.remakeConstraints { [weak self] make in
            make.top.equalToSuperview()
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
            make.bottom.equalTo(executionDurationLabel.snp.bottom)
        }
        
        executionDurationLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(labelHeight)
            make.width.equalTo(executionDurationLabel.snp.height).multipliedBy(1.75)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalTo(primaryButton.snp.top)
        }
        
        titleLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(labelHeight)
            make.left.equalTo(primaryButton.snp.right).offset(defaultPadding)
            make.right.equalTo(executionDurationLabel.snp.left).offset(-defaultPadding / 2)
            make.top.equalTo(primaryButton.snp.top)
        }
        
        subtitleLabel.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(labelHeight)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        countdownProgressView.snp.remakeConstraints { [weak self] make in
            make.left.equalTo(primaryButton.snp.right).offset(defaultPadding)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(4)
            make.centerY.equalTo(subtitleLabel.snp.centerY)
        }
        
        messagesTextView.snp.remakeConstraints { [weak self] make in
            make.top.equalTo(90)
            make.left.equalToSuperview().offset(defaultPadding * 3)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.bottom.equalToSuperview().offset(-defaultPadding)
        }
        
        dismissButton.snp.remakeConstraints { [weak self] make in
            make.height.equalTo(24)
            make.width.equalTo(dismissButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
    }
    
    @objc func onPrimary(sender: Any) {
        guard let modeExecutor = modeExecutor else { return }
        
        if countdownTimer != nil {
            stopCountdown()
            return
        }
        
        if modeExecutor.engaged {
            modeExecutor.disengage(reason: Kernel.Message(title: "ModeDisengageReason.user.disengaged".localized))
            return
        }
        
        guard let session = session else {
            return
        }
        
        if let engageDisallowedReasons = modeExecutor.engageDisallowedReasons(droneSession: session), engageDisallowedReasons.count > 0 {
            let reason = engageDisallowedReasons.first!
            DronelinkUI.shared.showDialog(title: reason.title, details: reason.details)
            return
        }

        startCountdown()
    }
    
    private func startCountdown() {
        countdownRemaining = countdownMax
        Dronelink.shared.announce(message: "\(countdownRemaining / 20)")
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard
                let modeExecutorWidget = self,
                let _ = modeExecutorWidget.modeExecutor,
                let _ = modeExecutorWidget.session
            else {
                self?.stopCountdown()
                return
            }
            
            modeExecutorWidget.countdownRemaining -= 1
            if (modeExecutorWidget.countdownRemaining == 0) {
                modeExecutorWidget.stopCountdown(aborted: false)
                modeExecutorWidget.engage()
            }
            else {
                modeExecutorWidget.update()
                if (modeExecutorWidget.countdownRemaining % 20 == 0) {
                    Dronelink.shared.announce(message: "\(modeExecutorWidget.countdownRemaining / 20)")
                }
            }
        }
        update()
    }
    
    private func stopCountdown(aborted: Bool = true) {
        countdownTimer?.invalidate()
        countdownTimer = nil
        update()
        if (aborted) {
            Dronelink.shared.announce(message: "ExecutableWidget.start.cancelled".localized)
        }
    }
    
    private func engage() {
        DispatchQueue.main.async { [weak self] in
            guard
                let modeExecutor = self?.modeExecutor,
                let session = self?.session
            else {
                return
            }

            do {
                try modeExecutor.engage(droneSession: session) { disallowed in
                    DronelinkUI.shared.showDialog(title: disallowed.title, details: disallowed.details)
                    DispatchQueue.main.async {
                        self?.update()
                    }
                }
            }
            catch DronelinkError.droneSerialNumberUnavailable {
                DronelinkUI.shared.showDialog(title: "ExecutableWidget.start.engage.droneSerialNumberUnavailable.title".localized, details: "ExecutableWidget.start.engage.droneSerialNumberUnavailable.message".localized)
                self?.update()
            }
            catch {
                self?.update()
            }
        }
    }
    
    @objc func onLayoutToggle() {
        layout = layout == .small ? .medium : .small
        view.superview?.setNeedsUpdateConstraints()
    }
    
    @objc func onDismiss() {
        Dronelink.shared.unloadMode()
    }
    
    @objc open override func update() {
        super.update()
        
        guard let modeExecutor = modeExecutor else {
            return
        }

        titleLabel.text = modeExecutor.descriptors.display

        if countdownTimer != nil {
            activityIndicator.isHidden = true
            primaryButton.isHidden = false
            subtitleLabel.isHidden = true
            executionDurationLabel.isHidden = true
            countdownProgressView.isHidden = false
            dismissButton.isHidden = false
            messagesTextView.isHidden = true

            activityIndicator.stopAnimating()
            let progress = Float(countdownMax - countdownRemaining) / Float(countdownMax)
            primaryButton.isEnabled = true
            primaryButton.setBackgroundColor(primaryDisengagedColor.interpolate(primaryEngagedColor, percent: CGFloat(progress)))
            primaryButton.setImage(cancelImage, for: .normal)
            titleLabel.text = String(format: "ExecutableWidget.start.countdown".localized, Int(ceil(Double(countdownRemaining) / 20)))
            countdownProgressView.setProgress(progress, animated: true)
            countdownProgressView.progressTintColor = progressDisengagedColor?.interpolate(progressEngagedColor, percent: CGFloat(progress))
            return
        }

        if modeExecutor.engaging {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            primaryButton.isHidden = true
            subtitleLabel.isHidden = false
            executionDurationLabel.isHidden = true
            countdownProgressView.isHidden = true
            dismissButton.isHidden = true
            messagesTextView.isHidden = true

            subtitleLabel.text = "ExecutableWidget.start.engaging".localized
            return
        }

        activityIndicator.isHidden = true
        primaryButton.isHidden = false
        subtitleLabel.isHidden = false
        executionDurationLabel.isHidden = !modeExecutor.engaged
        countdownProgressView.isHidden = true
        dismissButton.isHidden = modeExecutor.engaged
        messagesTextView.isHidden = false

        activityIndicator.stopAnimating()
        primaryButton.isEnabled = session != nil
        let executionDuration = modeExecutor.executionDuration
        executionDurationLabel.text = Dronelink.shared.format(formatter: "timeElapsed", value: executionDuration, defaultValue: "ExecutableWidget.executionDuration.empty".localized)

        if modeExecutor.engaged {
            subtitleLabel.text = modeExecutor.summaryMessage?.display ?? ""
            messagesTextView.text = layout == .small ? nil : modeExecutor.executingMessageGroups.map({ $0.display }).joined(separator: "")
            primaryButton.setBackgroundColor(primaryEngagedColor)
            primaryButton.setImage(disengageImage, for: .normal)
        }
        else {
            subtitleLabel.text = session == nil ? "ModeExecutorWidget.disconnected".localized : "ModeExecutorWidget.ready".localized
            messagesTextView.text = nil
            primaryButton.setBackgroundColor(primaryDisengagedColor)
            primaryButton.setImage(engageImage, for: .normal)
        }
    }

    open override func onModeEngaging(executor: ModeExecutor) {
        super.onModeEngaging(executor: executor)
        Dronelink.shared.announce(message: "ModeExecutorWidget.engaging".localized)
    }
    
    open override func onModeDisengaged(executor: ModeExecutor, engagement: ModeExecutor.Engagement, reason: Kernel.Message) {
        super.onModeDisengaged(executor: executor, engagement: engagement, reason: reason)
        if (reason.title != "ModeDisengageReason.user.disengaged".localized) {
            DronelinkUI.shared.showDialog(title: reason.title, details: reason.details)
        }
        
        Dronelink.shared.announce(message: "ModeExecutorWidget.disengaged".localized)
    }
}
