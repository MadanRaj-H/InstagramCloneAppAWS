//
//  PostViewController.swift
//  InstagramCloneApp
//
//  Created by Madan on 2/15/17.
//  Copyright © 2017 madan. All rights reserved.
//

import UIKit

class PostViewController: UIViewController, UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textMessage: UITextField!
    
    var imagePicker : UIImagePickerController!
    
    var activityIndicator : UIActivityIndicatorView!
    
    let credentialProvider : AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    let bucketName = "instagramclonemobileapp"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40));
        activityIndicator.activityIndicatorViewStyle = .gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        self.view.addSubview(activityIndicator)
        
    }
    
    @IBAction func saveBtnPressed(_ sender: UIButton) {
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        let fileName = NSUUID().uuidString + ".png"
        var location = ""
        
        if let data = UIImagePNGRepresentation(self.imageView.image!) {
            location = (self.documentsDirectory() as NSString).appendingPathComponent(fileName)
            do {
                try data.write(to: URL(fileURLWithPath: location))
            }catch let err as NSError {
                print(err.localizedDescription)
                displayAlert(title: "Error", body: "Image not available")
                return;
            }
        } else {
            displayAlert(title: "Error", body: "Image not available")
        }
        
        let uploadFileURL = URL(fileURLWithPath: location)
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task: AWSS3TransferUtilityTask, progress: Progress) in
            print("Progress is: %f", progress.fractionCompleted)
        }
        
        let completionHandler = { (task,error) -> Void in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
            
                if error != nil {
                    print(error!)
                    self.displayAlert(title: "Error", body: "image upload failed")
                } else {
                    self.saveToPostsDatabase(key: fileName)
                }
            }
        } as AWSS3TransferUtilityUploadCompletionHandlerBlock
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadFile(uploadFileURL, bucket: bucketName, key: fileName, contentType: "image/png", expression: expression, completionHandler : completionHandler).continueWith { (task) -> Any? in
            if task.error != nil {
                print(task.error!)
            }
            if (task.result != nil)  {
                print("upload started")
            }
            return nil;
        }
    }
    
    
    func saveToPostsDatabase(key : String) {
        let mapper = AWSDynamoDBObjectMapper.default()
        let identityID = credentialProvider.identityId
        let post = Posts()
        post?.id = key
        post?.bucket = bucketName
        post?.fileName = key
        post?.userID = identityID
        post?.message = self.textMessage.text != nil ? self.textMessage.text : ""
        
        mapper.save(post!).continueWith { (task) -> Any? in
            if task.error != nil {
                print(task.error!)
            }
            if (task.result != nil)  {
                print("upload success")
                DispatchQueue.main.async {
                    self.displayAlert(title: "Success", body: "Uplaoded image successfully")
                }
            }
            return nil;
        }
    }
    
    func displayAlert(title : String, body message : String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (alert) in
            self.navigationController!.popViewController(animated: true)
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func imageBtnPressed(_ sender: UIButton) {
        present(imagePicker, animated: true, completion: nil);
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = img;
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let directory = paths[0]
        return directory
    }
}
