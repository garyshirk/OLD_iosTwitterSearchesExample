//
//  DetailViewController.swift
//  TwitterSearches
//
//  Created by Gary Shirk on 1/19/15.
//  Copyright (c) 2015 garyshirk. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIWebViewDelegate {
    
    
    @IBOutlet weak var webView: UIWebView!
    
    var detailItem: NSURL?

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self;
    
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let url = detailItem {
            webView.loadRequest(NSURLRequest(URL: url))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        webView.stopLoading()
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        webView.loadHTMLString("<html><body><p>Error when performing search: " + error.description + "</body></html>", baseURL: nil)
    }
}

