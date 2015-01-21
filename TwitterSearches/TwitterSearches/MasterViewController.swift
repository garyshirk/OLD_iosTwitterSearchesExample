//  MasterViewController.swift
//  TwitterSearches
//
import UIKit

class MasterViewController: UITableViewController,
                            ModelDelegate, UIGestureRecognizerDelegate {

    // detailviewcontroller contains webView to show search results
    var detailViewController: DetailViewController? = nil
    let twitterSearchURL = "http://mobile.twitter.com/search/?q="
    
    var model: Model! = nil
    
    // conform to ModelDelegate
    func modelDataChanged() {
        tableView.reloadData()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addButtonPressed:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
        
        model = Model(delegate: self);
        model.synchronize()
    }
    
    // display UIAlertController to get new search from user
    func addButtonPressed(sender: AnyObject) {
        displayAddEditSearchAlert(isNew: true, index: nil)
    }
    
    // handle long press for editing or sharing a search
    func tableViewCellLongPressed(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began && !tableView.editing {
            
            let cell = sender.view as UITableViewCell
            
            if let indexPath = tableView.indexPathForCell(cell) {
                displayLongPressOptions(indexPath.row)
            }
        }
    }
    
    func displayLongPressOptions(row: Int) {
        // create UIAlertController for user input
        let alertController = UIAlertController(title: "Options", message: "Edit or Share you search", preferredStyle: UIAlertControllerStyle.Alert)
        
        // create cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let editAction = UIAlertAction(title: "Edit", style: UIAlertActionStyle.Default, handler: {(action) in  self.displayAddEditSearchAlert(isNew: false, index: row)})
        alertController.addAction(editAction)
        
        let shareAction = UIAlertAction(title: "Share", style: UIAlertActionStyle.Default, handler: {(action) in self.shareSearch(row)})
        alertController.addAction(shareAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // displays add/edit dialog
    func displayAddEditSearchAlert(# isNew: Bool, index: Int?) {
        // create UIAlertController for user input
        let alertController = UIAlertController(
            title: isNew ? "Add Search" : "Edit Search",
            message: isNew ? "" : "Modify your query",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        // create UITextFields in which user can enter a new search
        alertController.addTextFieldWithConfigurationHandler(
            {(textField) in
                if isNew {
                    textField.placeholder = "Enter Twitter search query"
                } else {
                    textField.text = self.model.queryForTagAtIndex(index!)
                }
        })
        
        alertController.addTextFieldWithConfigurationHandler(
            {(textField) in
                if isNew {
                    textField.placeholder = "Tag your query"
                } else {
                    textField.text = self.model.tagAtIndex(index!)
                    textField.enabled = false
                    textField.textColor = UIColor.lightGrayColor()
                }
        })
        
        // create Cancel action
        let cancelAction = UIAlertAction(title: "Cancel",
            style: UIAlertActionStyle.Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let saveAction = UIAlertAction(title: "Save",
            style: UIAlertActionStyle.Default,
            handler: {(action) in
                let query =
                (alertController.textFields?[0] as UITextField).text
                let tag =
                (alertController.textFields?[1] as UITextField).text
                
                // ensure query and tag are not empty
                if !query.isEmpty && !tag.isEmpty {
                    self.model.saveQuery(
                        query, forTag: tag, syncToCloud: true)
                    
                    if isNew {
                        let indexPath =
                        NSIndexPath(forRow: 0, inSection: 0)
                        self.tableView.insertRowsAtIndexPaths([indexPath],
                            withRowAnimation: .Automatic)
                    }
                }
        })
        alertController.addAction(saveAction)
        
        presentViewController(alertController, animated: true,
            completion: nil)
    }
    
    // displays share sheet
    func shareSearch(index: Int) {
        
        let message = "Check out the results of this Twitter search"
        let urlString = twitterSearchURL + urlEncodeString(model.queryForTagAtIndex(index)!)
        let itemsToShare = [message, urlString];
        
        // create UIActivityViewController so user can share search
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    // returns a URL encoded version of the query String
    func urlEncodeString(string: String) -> String {
        return string.stringByAddingPercentEncodingWithAllowedCharacters(
            NSCharacterSet.URLQueryAllowedCharacterSet())!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDetail" {
            
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                
                // get query string
                let query = String(model.queryForTagAtIndex(indexPath.row)!)
                
                // create NSURL to perform twitter search
                controller.detailItem = NSURL(string: twitterSearchURL + urlEncodeString(query))
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel!.text = model.tagAtIndex(indexPath.row)
        
        // long press gesture recognizer
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "tableViewCellLongPressed:")
        longPressGestureRecognizer.minimumPressDuration = 0.5
        cell.addGestureRecognizer(longPressGestureRecognizer)
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            model.deleteSearchAtIndex(indexPath.row)
            
            // remove UITableView row
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        }
        //else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        //}
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        // tell model to reorder tags
        model.moveTagAtIndex(sourceIndexPath.row, toDestinationIndex: destinationIndexPath.row)
    }
}

