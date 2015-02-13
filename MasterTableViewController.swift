//
//  MasterTableViewController.swift
//  Notes
//
//  Created by Darrell Nicholas on 2/11/15.
//  Copyright (c) 2015 Darrell Nicholas. All rights reserved.
//

import UIKit

class MasterTableViewController: UITableViewController, PFLogInViewControllerDelegate,
    PFSignUpViewControllerDelegate {
    
    var noteObjects: NSMutableArray! = NSMutableArray()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // every time a view appears its going to check and see if there is a user.
        // if there is no user, it's going to create a login and signup vc and present the login view controller
        
        if (PFUser.currentUser() == nil) {
            
            var logInViewController = PFLogInViewController()
            logInViewController.delegate = self
            
            var signUpViewController = PFSignUpViewController()
            signUpViewController.delegate = self
            
            logInViewController.signUpController = signUpViewController
            self.presentViewController(logInViewController, animated: true, completion: nil)
        } else {
            self.fetchAllObjectFromLocalDatastore()
            self.fetchAllObjects()
        }
    }
    
    // create methods to fetch local datastore and Parse backend
    func fetchAllObjectFromLocalDatastore() {
        // create a query object on the class we named "Note" on Parse
        var query: PFQuery = PFQuery(className: "Note")
        
        // query the local datastore not the backend
        query.fromLocalDatastore()
        // where the username is equal to the user logged into the app
        query.whereKey("username", equalTo: PFUser.currentUser().username)
        
        // do the fetch in the background and we get an array back as an NSArray(see comment)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if (error == nil) {
                var temp:NSArray = objects as NSArray // here's where we get the objects as an NSArray
                self.noteObjects = temp.mutableCopy() as NSMutableArray // make a mutable copy and set it to our 'noteObjects'
                self.tableView.reloadData() // then reload the table view with new fetched objects
            } else {
                println(error.userInfo)
            }
            
        }
    }
    
    func fetchAllObjects() {
        // Pin is Parse's way of syncing, this just starts us off with a fresh set of objects. (Asynchronous)
        PFObject.unpinAllObjectsInBackgroundWithBlock(nil)
        
        // then query the background and get fresh set of objects and pin them all to the backend.
        var query:PFQuery = PFQuery(className: "Note")
        
        query.whereKey("username", equalTo: PFUser.currentUser().username)
        // find Asynchronously in the background
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if (error == nil) {
                // syncs all objects to the backend
                PFObject.pinAllInBackground(objects, block: nil)
                
                // call the method right before this one
                self.fetchAllObjectFromLocalDatastore()
            } else {
                println(error.userInfo)
            }
        }
        
    }
    
    //MARK: Login delegates
    func logInViewController(logInController: PFLogInViewController!, shouldBeginLogInWithUsername username: String!, password: String!) -> Bool {
        if (!username.isEmpty || !password.isEmpty) {
            return true
        } else {
            return false
        }
    }
    
    func logInViewController(logInController: PFLogInViewController!, didLogInUser user: PFUser!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func logInViewController(logInController: PFLogInViewController!, didFailToLogInWithError error: NSError!) {
        println("Failed to log in...")
    }
    
    //MARK: Signup delegates
    func signUpViewController(signUpController: PFSignUpViewController!, shouldBeginSignUp info: [NSObject : AnyObject]!) -> Bool {
        if let password = info?["password"] as? String {
            return password.utf16Count >= 8
        } else {
            return false
        }
    }
    
    func signUpViewController(signUpController: PFSignUpViewController!, didSignUpUser user: PFUser!) {
        // if user has signed up we just want to dismiss the view controller
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func signUpViewController(signUpController: PFSignUpViewController!, didFailToSignUpWithError error: NSError!) {
        println("Failed to sign up...")
    }
    
    func signUpViewControllerDidCancelSignUp(signUpController: PFSignUpViewController!) {
        println("User dismissed sign up.")
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.noteObjects.count
    }

 
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as MasterTableViewCell

        var object: PFObject = self.noteObjects.objectAtIndex(indexPath.row) as PFObject
        
        cell.masterTitleLabel.text = object["title"] as? String
        cell.masterTextLabel.text = object["text"] as? String

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.performSegueWithIdentifier("editNote", sender: self) // now I can override the prepareForSegue method to do custom stuff needed for this segue.
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        var upcoming: AddNoteTableViewController = segue.destinationViewController as AddNoteTableViewController
        
        if segue.identifier == "editNote" {
            let indexPath: NSIndexPath = self.tableView.indexPathForSelectedRow()!
            
            var object:PFObject = self.noteObjects.objectAtIndex(indexPath.row) as PFObject
            
            upcoming.object = object
            
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
