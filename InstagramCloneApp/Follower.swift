//
//  Follower.swift
//  InstagramCloneApp
//
//  Created by mh53653 on 2/19/17.
//  Copyright © 2017 madan. All rights reserved.
//

import Foundation
class Follower : AWSDynamoDBObjectModel,AWSDynamoDBModeling {
    
    var id  : String = ""
    var follower  : String = ""
    var following   : String = ""
    
    override init!() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [AnyHashable : Any]!, error: ()) throws {
        super.init()
        id = dictionaryValue["id"] as! String
        follower = dictionaryValue["follower"] as! String
        following = dictionaryValue["following"] as! String
    }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func dynamoDBTableName() -> String {
        return "Followers"
    }
    
    class func hashKeyAttribute() -> String {
        return "id"
    }
}
