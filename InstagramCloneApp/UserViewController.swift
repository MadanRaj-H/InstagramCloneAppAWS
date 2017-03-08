//
//  UserViewController.swift
//  InstagramCloneApp
//
//  Created by Madan on 2/15/17.
//  Copyright © 2017 madan. All rights reserved.
//

import UIKit

class UserViewController: UIViewController, UITableViewDataSource , UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let credentialProvider : AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    let databaseService = DatabaseService()
    
    var users = [User]()
    var isFollowing  = ["":false]
    var refreshControl : UIRefreshControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull To Refresh")
        refreshControl.addTarget(self, action: #selector(UserViewController.refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        refresh()
    }
    
    func refresh() {
        let identityId = credentialProvider.identityId
        let mapper = AWSDynamoDBObjectMapper.default()
        let scan = AWSDynamoDBScanExpression()
        
        mapper.scan(User.self, expression: scan).continueWith { (dynamoDBTask : AWSTask) -> Any? in
            if dynamoDBTask.error != nil {
                print(dynamoDBTask.error!)
            }
            
            if dynamoDBTask.result != nil {
                self.users.removeAll()
                let dynamoResults  = dynamoDBTask.result!
                
                for user in dynamoResults.items as! [User] {
                    if user.id != identityId {
                        self.users.append(user)
                    }
                }
               
            }
            
            return nil
        }
        
        
        databaseService.findFollowings(follower: identityId!, map: mapper).continueWith { (task : AWSTask) -> Any? in
            if task.error != nil {
                print(task.error!)
            }
            
            if task.result != nil {
                for item in task.result as! [Follower] {
                    self.isFollowing[item.following] = true
                }
            }
            
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
            return nil
        }
        
    }
    
    
    func addFollowing(following : String) {
        let identityId = credentialProvider.identityId
        let mapper = AWSDynamoDBObjectMapper.default()
        
        let follower  = Follower()
        follower?.id = NSUUID().uuidString
        follower?.follower = identityId!
        follower?.following = following
        
        mapper.save(follower!)
    }
    
    
    func removeFollowing(following: String) {
        let identityId = credentialProvider.identityId
        let mapper = AWSDynamoDBObjectMapper.default()
        
        databaseService.findFollower(follower: identityId!, following: following, map: mapper).continueWith { (task:AWSTask) -> Any? in
            if (task.error != nil) {
                print(task.error!)
            }
            if (task.result != nil) {
                let followings = task.result as! [Follower]
                for following in followings {
                    mapper.remove(following)
                }
            }
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        cell.textLabel?.text = users[indexPath.row].name;
        
        let followedObjectId = users[indexPath.row].id
        
        if isFollowing[followedObjectId] == true {
            
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let followedObjectId = users[indexPath.row].id
        if isFollowing[followedObjectId] == nil || isFollowing[followedObjectId] == false {
            isFollowing[followedObjectId] = true
            cell?.accessoryType = UITableViewCellAccessoryType.checkmark
            addFollowing(following: users[indexPath.row].id)
        } else {
            isFollowing[followedObjectId] = false
            cell?.accessoryType = UITableViewCellAccessoryType.none
            removeFollowing(following: users[indexPath.row].id)
        }
    }
}
