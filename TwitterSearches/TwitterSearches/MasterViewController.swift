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
    
    var objects = NSMutableArray()
    
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

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
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
        
    }
    
    // displays share sheet
    func shareSearch(index: Int) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        objects.insertObject(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = objects[indexPath.row] as NSDate
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                controller.detailItem = object
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
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let object = objects[indexPath.row] as NSDate
        cell.textLabel!.text = object.description
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeObjectAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

