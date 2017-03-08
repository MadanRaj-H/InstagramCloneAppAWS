//
//  DatabaseService.swift
//  InstagramCloneApp
//
//  Created by Madan on 2/19/17.
//  Copyright © 2017 madan. All rights reserved.
//

import Foundation
class DatabaseService {
    
    func findFollowings(follower : String , map : AWSDynamoDBObjectMapper) -> AWSTask<AnyObject> {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "follower = :follower"
        scan.expressionAttributeValues = [":follower":follower]
        
        return map.scan(Follower.self, expression: scan).continueWith(block: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error!)
            }
            
            if task.result != nil {
                return task.result?.items as! [Follower]
            }
            return nil
        });

    }
    
    func findFollower(follower: String, following: String, map: AWSDynamoDBObjectMapper) -> AWSTask<AnyObject> {
        let scan = AWSDynamoDBScanExpression()
        scan.filterExpression = "follower = :follower AND following = :following"
        scan.expressionAttributeValues = [":follower":follower,":following":following]
        
        return map.scan(Follower.self, expression: scan).continueWith(block: { (task: AWSTask) -> Any? in
            if (task.error != nil) {
                print(task.error!)
            }
            
            if (task.result != nil) {
                return task.result?.items as! [Follower]
            }
            return nil
        });
    }
}
