//
//  FuncViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 1/30/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import DronelinkCore
import Foundation
import UIKit
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MaterialComponents.MaterialTextFields

public class FuncViewController: UIViewController {
    public static func create(droneSessionManager: DroneSessionManager) -> FuncViewController {
        let funcViewController = FuncViewController()
        funcViewController.droneSessionManager = droneSessionManager
        return funcViewController
    }
    
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    private var funcExecutor: FuncExecutor?
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let primaryButton = MDCRaisedButton()
    private let backButton = MDCFlatButton()
    private let nextButton = MDCRaisedButton()
    private let titleImageView = UIImageView()
    private let titleLabel = UILabel()
    private let variableNameLabel = UILabel()
    private let variableDescriptionTextView = UITextView()
    private let variableSegmentedControl = UISegmentedControl()
    private let variableTextField = MDCTextField()
    private let variablePickerView = UIPickerView()
    private let variableDroneButton = MDCButton()
    private let variableDroneLabel = UILabel()
    private let progressLabel = UILabel()
    private let dismissButton = UIButton(type: .custom)
    private let primaryColor = MDCPalette.deepPurple.tint800
    private let funcImage = DronelinkUI.loadImage(named: "function-variant")
    private let cancelImage = DronelinkUI.loadImage(named: "baseline_close_white_36pt")
    private let droneImage = DronelinkUI.loadImage(named: "baseline_navigation_white_36pt")
    
    private var intro = true
    private var step = 0
    private var lastStep: Bool { (step == (funcExecutor?._func.inputs?.count ?? 0) - 1) }
    private var hasInputs: Bool { funcExecutor?._func.inputs?.count ?? 0 > 0 }
    private var input: Mission.FuncInput? { hasInputs ? funcExecutor?._func.inputs?[safeIndex: step] : nil }
    private var executing = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        blurEffectView.clipsToBounds = true
        view.addSubview(blurEffectView)
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        
        titleImageView.image = funcImage
        titleImageView.tintColor = UIColor.white
        view.addSubview(titleImageView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.white
        view.addSubview(titleLabel)
        
        variableNameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        variableNameLabel.textColor = UIColor.white
        view.addSubview(variableNameLabel)
        
        variableDescriptionTextView.textContainerInset = .zero
        variableDescriptionTextView.backgroundColor = UIColor.clear
        variableDescriptionTextView.font = UIFont.boldSystemFont(ofSize: 12)
        variableDescriptionTextView.textColor = UIColor.white.withAlphaComponent(0.85)
        variableDescriptionTextView.isScrollEnabled = true
        variableDescriptionTextView.isEditable = false
        view.addSubview(variableDescriptionTextView)
        
        variableSegmentedControl.tintColor = primaryColor
        variableSegmentedControl.insertSegment(withTitle: "yes".localized, at: 0, animated: false)
        variableSegmentedControl.insertSegment(withTitle: "no".localized, at: 1, animated: false)
        view.addSubview(variableSegmentedControl)
        
        variableTextField.tintColor = UIColor.white
        variableTextField.delegate = self
        variableTextField.returnKeyType = .done
        variableTextField.textColor = UIColor.white
        view.addSubview(variableTextField)

        variablePickerView.dataSource = self
        variablePickerView.delegate = self
        view.addSubview(variablePickerView)

        let scheme = MDCContainerScheme()
        scheme.colorScheme = MDCSemanticColorScheme(defaults: .materialDark201907)
        scheme.colorScheme.primaryColor = .white
        variableDroneButton.applyOutlinedTheme(withScheme: scheme)
        variableDroneButton.translatesAutoresizingMaskIntoConstraints = false
        variableDroneButton.setImage(droneImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        variableDroneButton.imageView?.contentMode = .scaleAspectFit
        variableDroneButton.tintColor = UIColor.white
        variableDroneButton.setTitle("FuncViewController.input.drone".localized, for: .normal)
        variableDroneButton.addTarget(self, action: #selector(onDrone(sender:)), for: .touchUpInside)
        view.addSubview(variableDroneButton)
        
        variableDroneLabel.numberOfLines = 2
        variableDroneLabel.font = UIFont.boldSystemFont(ofSize: 12)
        variableDroneLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        view.addSubview(variableDroneLabel)
        
        progressLabel.font = UIFont.boldSystemFont(ofSize: 12)
        progressLabel.textColor = UIColor.white
        progressLabel.textAlignment = .center
        view.addSubview(progressLabel)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("back".localized, for: .normal)
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.addTarget(self, action: #selector(onBack(sender:)), for: .touchUpInside)
        view.addSubview(backButton)
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setBackgroundColor(primaryColor)
        nextButton.tintColor = UIColor.white
        nextButton.addTarget(self, action: #selector(onNext(sender:)), for: .touchUpInside)
        view.addSubview(nextButton)
        
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.setBackgroundColor(primaryColor)
        primaryButton.tintColor = UIColor.white
        primaryButton.addTarget(self, action: #selector(onPrimary(sender:)), for: .touchUpInside)
        view.addSubview(primaryButton)
        
        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(DronelinkUI.loadImage(named: "baseline_close_white_36pt"), for: .normal)
        dismissButton.addTarget(self, action: #selector(onDismiss), for: .touchUpInside)
        view.addSubview(dismissButton)
    }
        
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Dronelink.shared.add(delegate: self)
        droneSessionManager.add(delegate: self)
        update()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Dronelink.shared.remove(delegate: self)
        droneSessionManager.remove(delegate: self)
        funcExecutor?.remove(delegate: self)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 10
        
        blurEffectView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleImageView.snp.remakeConstraints { make in
            make.height.equalTo(24)
            make.width.equalTo(titleImageView.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(25)
            make.left.equalTo(titleImageView.snp.right).offset(defaultPadding)
            make.right.equalTo(dismissButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(titleImageView.snp.top)
        }
        
        dismissButton.snp.remakeConstraints { make in
            make.height.equalTo(24)
            make.width.equalTo(dismissButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
        
        variableNameLabel.snp.remakeConstraints { make in
            make.left.equalTo(titleImageView.snp.left).offset(5)
            make.right.equalTo(dismissButton.snp.right)
            make.top.equalTo(titleLabel.snp.bottom).offset(defaultPadding)
            make.height.equalTo(20)
        }
        
        variableDescriptionTextView.snp.remakeConstraints { make in
            make.left.equalTo(titleImageView.snp.left)
            make.right.equalTo(dismissButton.snp.right)
            if intro {
                make.top.equalTo(titleLabel.snp.bottom).offset(defaultPadding)
                make.height.equalTo(45)
            }
            else {
                make.top.equalTo(variableNameLabel.snp.bottom).offset(4)
                make.height.equalTo(30)
            }
        }
        
        let variableControl = !intro && (input?.descriptors.description?.isEmpty ?? true) ? variableNameLabel : variableDescriptionTextView
        
        variableSegmentedControl.snp.remakeConstraints { make in
            make.left.equalTo(variableControl.snp.left).offset(defaultPadding)
            make.right.equalTo(variableControl.snp.right).offset(-defaultPadding)
            make.top.equalTo(variableControl.snp.bottom).offset(defaultPadding)
            make.height.equalTo(30)
        }
        
        variableTextField.snp.remakeConstraints { make in
            make.left.equalTo(variableControl.snp.left).offset(defaultPadding)
            make.right.equalTo(variableControl.snp.right).offset(-defaultPadding)
            make.top.equalTo(variableControl.snp.bottom).offset(-5)
            make.height.equalTo(30)
        }
        
        variablePickerView.snp.remakeConstraints { make in
            make.left.equalTo(variableControl.snp.left).offset(defaultPadding)
            make.right.equalTo(variableControl.snp.right).offset(-defaultPadding)
            make.top.equalTo(variableControl.snp.bottom).offset(-defaultPadding)
            make.height.equalTo(80)
        }
        
        variableDroneButton.snp.remakeConstraints { make in
            make.left.equalTo(variableControl.snp.left)
            make.width.equalTo(110)
            make.top.equalTo(variableControl.snp.bottom).offset(5)
            make.height.equalTo(40)
        }
        
        variableDroneLabel.snp.remakeConstraints { make in
            make.left.equalTo(variableDroneButton.snp.right).offset(defaultPadding)
            make.right.equalTo(variableControl.snp.right)
            make.top.equalTo(variableDroneButton)
            make.bottom.equalTo(variableDroneButton)
        }
        
        backButton.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(35)
            make.width.equalTo(85)
        }
        
        progressLabel.snp.remakeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(defaultPadding)
            make.right.equalTo(nextButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(backButton)
            make.bottom.equalTo(backButton)
        }
        
        nextButton.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(backButton)
            make.width.equalTo(lastStep ? 200 : 85)
            make.bottom.equalTo(backButton)
        }
        
        primaryButton.snp.remakeConstraints { make in
            make.height.equalTo(35)
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            if (intro && (input?.descriptors.description?.isEmpty ?? true)) {
                make.top.equalTo(titleLabel.snp.bottom).offset(defaultPadding * 2)
            }
            else {
                make.top.equalTo(variableControl.snp.bottom)
            }
        }
        
        update()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onPrimary(sender: Any) {
        guard let funcExecutor = funcExecutor else {
            return
        }
        
        if (intro && hasInputs) {
            intro = false
            view.setNeedsUpdateConstraints()
            return
        }
        
        if (!executing) {
            executing = true
            view.setNeedsUpdateConstraints()
            funcExecutor.execute(droneSession: session) { error in
                DispatchQueue.main.async {
                    DronelinkUI.shared.showSnackbar(text: error)
                    self.executing = false
                    self.view.setNeedsUpdateConstraints()
                }
            }
        }
    }
    
    @objc func onBack(sender: Any) {
        step -= 1
        readValue()
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onNext(sender: Any) {
        if (!writeValue(next: true)) {
            return
        }
        
        if (lastStep) {
            onPrimary(sender: sender)
            return
        }
        
        step += 1
        readValue()
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onDrone(sender: Any) {
        if session == nil {
            DronelinkUI.shared.showSnackbar(text: "FuncViewController.input.drone.unavailable".localized)
            return
        }
        
        writeValue()
        readValue()
    }
    
    @objc func onDismiss() {
        Dronelink.shared.unloadFunc()
    }
    
    func writeValue(next: Bool = false) -> Bool {
        guard let input = input else {
            return false
        }
        
        var value: Any? = nil
        switch input.variable.valueType {
            case .boolean:
                if (variableSegmentedControl.selectedSegmentIndex != UISegmentedControl.noSegment) {
                    value = variableSegmentedControl.selectedSegmentIndex == 0
                }
                break
                
            case .number:
                if let text = variableTextField.text, !text.isEmpty {
                    value = Double(text)
                }
                break
                
            case .string:
                if input.enumValues == nil {
                    if let text = variableTextField.text, !text.isEmpty {
                        value = text
                    }
                }
                else {
                    let index = variablePickerView.selectedRow(inComponent: 0) - 1
                    if index >= 0 {
                        value = input.enumValues?[index]
                    }
                }
                break
                
            case .drone:
                if next {
                    if funcExecutor?.readValue(index: step) == nil && !input.optional {
                        DronelinkUI.shared.showSnackbar(text: "FuncViewController.input.required".localized)
                        return false
                    }
                    return true
                }
                value = session
                break
        }
        
        if !input.optional && value == nil {
            DronelinkUI.shared.showSnackbar(text: "FuncViewController.input.required".localized)
            return false
        }
        
        funcExecutor?.writeValue(index: step, value: value)
        return true
    }
    
    func readValue() {
        variableTextField.text = ""
        variableSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        variablePickerView.reloadAllComponents()
        variableDroneLabel.text = ""
        
        guard let value = funcExecutor?.readValue(index: step) else { return }
        
        if input?.variable.valueType == .drone {
            if let valueString = value as? String {
                variableDroneLabel.text = valueString
            }
            
            if let valueArray = value as? [Any] {
                if let valueString = valueArray.first as? String {
                    variableDroneLabel.text = "(\(valueArray.count)) \(valueString)"
                }
            }
            return
        }
        
        if let valueBoolean = value as? Bool {
            variableSegmentedControl.selectedSegmentIndex = valueBoolean ? 0 : 1
        }
        
        if let valueDouble = value as? Double {
            variableTextField.text = "\(valueDouble)"
        }
        
        if let valueString = value as? String {
            variableTextField.text = valueString
            input?.enumValues?.enumerated().forEach { (index, enumValue) in
                if enumValue == valueString {
                    variablePickerView.selectRow(index + 1, inComponent: 0, animated: false)
                }
            }
        }
    }
    
    func update() {
        guard let funcExecutor = funcExecutor else {
            return
        }
        
        titleLabel.text = funcExecutor._func.descriptors.name

        variableNameLabel.isHidden = true
        variableDescriptionTextView.isHidden = true
        variableSegmentedControl.isHidden = true
        variableTextField.isHidden = true
        variablePickerView.isHidden = true
        variableDroneButton.isHidden = true
        variableDroneLabel.isHidden = true
        
        if intro {
            variableDescriptionTextView.isHidden = false
            backButton.isHidden = true
            nextButton.isHidden = true
            progressLabel.isHidden = true
            primaryButton.isHidden = false
            primaryButton.setTitle((executing ? "FuncViewController.primary.executing" : hasInputs ? "FuncViewController.primary.intro" : "FuncViewController.primary.execute").localized, for: .normal)
            variableDescriptionTextView.text = funcExecutor._func.descriptors.description
        }
        else {
            primaryButton.isHidden = true
            backButton.isHidden = false
            backButton.isEnabled = step > 0
            nextButton.isHidden = false
            progressLabel.isHidden = lastStep
            progressLabel.text = "\(step + 1) / \(funcExecutor._func.inputs?.count ?? 0)"
            nextButton.setTitle((lastStep ? "FuncViewController.primary.execute" : "next").localized, for: .normal)

            if let input = input {
                variableNameLabel.isHidden = false
                variableNameLabel.text = input.descriptors.name
                if !(input.descriptors.description?.isEmpty ?? true) {
                    variableDescriptionTextView.isHidden = false
                    variableDescriptionTextView.text = input.descriptors.description
                }

                switch input.variable.valueType {
                case .boolean:
                    variableSegmentedControl.isHidden = false
                    break
                    
                case .number:
                    variableTextField.isHidden = false
                    variableTextField.keyboardType = .decimalPad
                    break
                    
                case .string:
                    if input.enumValues == nil {
                        variableTextField.isHidden = false
                        variableTextField.keyboardType = .default
                    }
                    else {
                        variablePickerView.isHidden = false
                    }
                    break
                    
                case .drone:
                    variableDroneButton.isHidden = false
                    variableDroneLabel.isHidden = false
                    break
                }
            }
        }
    }
}

extension FuncViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        guard let input = input else {
            return 0
        }
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let input = input else {
            return 0
        }
        return (input.enumValues?.count ?? 0) + 1
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let input = input else {
            return ""
        }
        
        if row == 0 {
            return ""
        }
        return input.enumValues?[row - 1] ?? ""
    }
}

extension FuncViewController: DronelinkDelegate {
    public func onRegistered(error: String?) {}
    
    public func onMissionLoaded(executor: MissionExecutor) {
        Dronelink.shared.unloadFunc()
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {
        funcExecutor = executor
        intro = !hasInputs || !(executor._func.descriptors.description?.isEmpty ?? true)
        executor.add(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onFuncUnloaded(executor: FuncExecutor) {
        funcExecutor = nil
        executor.remove(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension FuncViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension FuncViewController: FuncExecutorDelegate {
    public func onFuncExecuted(executor: FuncExecutor) {
    }
}

extension FuncViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
