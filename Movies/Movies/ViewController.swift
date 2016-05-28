//
//  ViewController.swift
//  Movies
//
//  Created by Jovanny Espinal on 5/27/16.
//  Copyright © 2016 Jovanny Espinal. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    lazy var movieResult = [[String: AnyObject]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        
        textField.rac_textSignal()
            .filter( { (input) -> Bool in
                let text = input as! String
                
                return text.characters.count >= 2
            })
            .throttle(0.5)
            .flattenMap({ (input) -> RACStream! in
                let text = input as! String
                
                return self.signalForQuery(text)
            })
            .deliverOn(RACScheduler.mainThreadScheduler())
            .subscribeNext({ (input) -> Void in
                let result = input as! [String:AnyObject]
                
                self.movieResult = result["results"] as! [[String:AnyObject]]
                
                self.tableView.reloadData()
                }, error: { (error) -> Void in
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
                    
                    let alertAction = UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil)
                    
                    alertController.addAction(alertAction)
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
            })
        
        self.rac_signalForSelector(#selector(UITableViewDelegate.tableView(_:didSelectRowAtIndexPath:)), fromProtocol: UITableViewDelegate.self)
            .subscribeNext { (input) -> Void in
                let arguments = input as! RACTuple
                
                let indexPath = arguments.second as! NSIndexPath
                
                let title = self.movieResult[indexPath.row]["original_title"] as! String
                
                print("You have chosen the move: \(title)")
            }
        
        tableView.delegate = self   
    }
    
    func signalForQuery(query: String) -> RACSignal {
        let apiKey = "0759d9c7260fd564aeaa4194783cad28"
        let encodedQuery = query.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        let url = NSURL(string: "https://api.themoviedb.org/3/search/movie?api_key=\(apiKey)&query=\(encodedQuery)")!
        
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithURL(url, completionHandler: { (data, urlResponse, error) -> Void in
                if let error = error {
                    subscriber.sendError(error)
                } else {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0))
                        
                        subscriber.sendNext(json)
                    } catch let raisedError as NSError {
                        subscriber.sendError(raisedError)
                    }
                }
                
                subscriber.sendCompleted()
                
            })
            
            task.resume()
            
            return RACDisposable(block: {
                task.cancel()
            })
            
        })
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieResult.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
        }
        
        cell?.textLabel?.text = movieResult[indexPath.row]["original_title"] as? String
        
        return cell!
    }
}

