//
//  ViewController.swift
//  InstagramCloneApp
//
//  Created by Madan on 2/13/17.
//  Copyright © 2017 madan. All rights reserved.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController,GIDSignInDelegate,GIDSignInUIDelegate,AWSIdentityProviderManager{
    
    var googleToken = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
    }
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            
              googleToken = user.authentication.idToken
              signInForCognito(user: user)
            
//            let userId = user.userID
//            let idToken = user.authentication.idToken
//            let fullName = user.profile.name
//            let givenName = user.profile.givenName
//            let familyName = user.profile.familyName
//            let email = user.profile.email
//            
//            print(userId!,fullName!,givenName!,familyName!,email!,idToken!)
        } else {
            print("\(error.localizedDescription)")
        }
        
    }
    
    func logins() -> AWSTask<NSDictionary> {
        let result = NSDictionary(dictionary: [AWSIdentityProviderGoogle : googleToken])
        return AWSTask(result: result)
    }
    
    @IBAction func signOutBtnPressed(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signOut()
    }
    
    func signInForCognito(user : GIDGoogleUser!) {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .APSoutheast2,
                                                                identityPoolId:"ap-southeast-2:31b25d2c-9dd9-4953-a62c-68b3353fb0b0",identityProviderManager : self)
        let configuration = AWSServiceConfiguration(region:.APSoutheast2, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        credentialsProvider.getIdentityId().continueWith { (task:AWSTask) -> Any? in
            if task.error != nil {
                print("task erorr")
                return nil
            }
            
            let syncClient = AWSCognito.default()
            
            // Create a record in a dataset and synchronize with the server
            let dataset = syncClient.openOrCreateDataset("instagramCloneAppMobileDataSet")
            dataset.setString(user.profile.name!, forKey:"name")
            dataset.setString(user.profile.email!, forKey:"email")
            dataset.synchronize().continueWith {(task: AWSTask!) -> AnyObject! in
                if task.error != nil {
                    print(task.error!)
                } else {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "UserViewController", sender: nil)
                    }
                }
                return nil
            }
            return nil
        }
    }

}

