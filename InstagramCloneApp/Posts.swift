//
//  Posts.swift
//  InstagramCloneApp
//
//  Created by mh53653 on 2/16/17.
//  Copyright © 2017 madan. All rights reserved.
//

import Foundation
class Posts : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var id : String!
    var userID : String!
    var fileName : String!
    var message : String?
    var bucket : String!
    
    override init!() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [AnyHashable : Any]!, error: ()) throws {
        super.init()
        id = dictionaryValue["id"] as! String
        userID = dictionaryValue["userID"] as! String
        fileName = dictionaryValue["fileName"] as! String
        bucket = dictionaryValue["bucket"] as! String
        if let postMessage = dictionaryValue["message"] as? String{
            message = postMessage
        } else {
            message = ""
        }
    }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func dynamoDBTableName() -> String {
        return "Posts"
    }
    
    class func hashKeyAttribute() -> String {
        return "id"
    }
}
