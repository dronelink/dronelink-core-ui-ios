//
//  EmbedViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 2/19/21.
//

import Foundation
import UIKit
import WebKit
import MaterialComponents.MaterialActivityIndicator

public class EmbedViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    private let activityIndicator = MDCActivityIndicator()
    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    public var networkError: String?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        activityIndicator.cycleColors = [MDCPalette.pink.accent400!]
        activityIndicator.indicatorMode = .indeterminate
        activityIndicator.radius = 22
        activityIndicator.strokeWidth = 2.5
        activityIndicator.isUserInteractionEnabled = false
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { [weak self] make in
            make.width.equalTo(45)
            make.height.equalTo(45)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        activityIndicator.startAnimating()
        
        webView.isHidden = true
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.snp.makeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone(sender:)))
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        webView.stopLoading()
        webView.removeFromSuperview()
    }
    
    @objc func onDone(sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    public func load(_ request: URLRequest) {
        webView.load(request)
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {}
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.removeFromSuperview()
            self?.webView.isHidden = false
        }
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DronelinkUI.shared.showSnackbar(text: networkError ?? error.localizedDescription)
    }
}
