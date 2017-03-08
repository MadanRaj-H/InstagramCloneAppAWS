//
//  FeedViewController.swift
//  InstagramCloneApp
//
//  Created by Madan on 2/19/17.
//  Copyright © 2017 madan. All rights reserved.
//

import UIKit

class FeedViewController: UITableViewController {

    
    var credentialsProvider : AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    var databaseService = DatabaseService()
    var imageFiles = [Posts]()
    var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
    
    
    func refresh(){
        let identity = credentialsProvider.identityId
        let mapper = AWSDynamoDBObjectMapper.default()
        
        self.databaseService.findFollowings(follower: identity!, map: mapper).continueWith { (task:AWSTask) -> Any? in

            if(task.error != nil){
                print(task.error!)
            }
            
            if(task.result != nil) {
                self.imageFiles.removeAll()
                let items = task.result as! [Follower]
                for item in items {
                    let result = self.getPosts(userId: item.following, map: mapper)
                    
                    result.continueWith(block: { (task:AWSTask) -> Any? in
                        
                        if task.result != nil{
                            let posts = task.result as? [Posts]
                        
                            for post in posts! {
                                print(post.fileName)
                                print(post.bucket)
                                self.imageFiles.append(post)
                            }
                        
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                            return nil
                        }
                        return nil
                    })
                }
            }
            return nil
        }
        
        
    }
    
    func getPosts(userId: String, map: AWSDynamoDBObjectMapper) -> AWSTask<AnyObject> {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "userID = :userID"
        scan.expressionAttributeValues = [":userID":userId]
        
        return map.scan(Posts.self, expression: scan).continueWith { (task:AWSTask) -> Any? in
            if (task.error != nil) {
                print(task.error!)
            }
            
            if (task.result != nil) {
                return task.result?.items as! [Posts]
            }
            
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        refresh()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.imageFiles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as? FeedCell {
            let post = imageFiles[indexPath.row]
            let currentLocation = (self.documentsDirectory() as NSString).appendingPathComponent(post.fileName)
            let manager = FileManager.default
            
            if manager.fileExists(atPath: currentLocation) {
                cell.thumbImage.image = UIImage(contentsOfFile: currentLocation)
            }
            else{
                let transferUtility  = AWSS3TransferUtility.default()
                let expression = AWSS3TransferUtilityDownloadExpression()
                expression.progressBlock = {(task: AWSS3TransferUtilityTask, progress: Progress) in
                    print("Progress is: %f", progress.fractionCompleted)
                }
                
                self.completionHandler = { (task,location,data,error) -> Void in
                    DispatchQueue.main.async {
                        print(data!)
                        cell.thumbImage.image = UIImage(data: data!)
                        if let data = UIImagePNGRepresentation(cell.thumbImage.image!) {
                            let location = (self.documentsDirectory() as NSString).appendingPathComponent(post.fileName)
                            do {
                                try data.write(to: URL(fileURLWithPath: location))
                            }catch let err as NSError {
                                print(err.localizedDescription)
                                return;
                            }
                        } else {
                        }
                    }
                }
                
                transferUtility.downloadData(fromBucket: post.bucket, key: post.fileName, expression: expression, completionHandler: completionHandler)
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let directory = paths[0]
        return directory
    }
}
