//
//  User.swift
//  InstagramCloneApp
//
//  Created by mh53653 on 2/15/17.
//  Copyright © 2017 madan. All rights reserved.
//

import Foundation
class User : AWSDynamoDBObjectModel , AWSDynamoDBModeling {
    
    var id : String = ""
    var name : String = ""
    
    override init!() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [AnyHashable : Any]!, error: ()) throws {
        super.init()
        id = dictionaryValue["id"] as! String
        name = dictionaryValue["name"] as! String
    }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func dynamoDBTableName() -> String {
        return "Users"
    }
    
    static func hashKeyAttribute() -> String {
        return "id"
    }
    
}
