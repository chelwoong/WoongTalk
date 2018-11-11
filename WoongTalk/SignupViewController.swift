//
//  SignupViewController.swift
//  WoongTalk
//
//  Created by woong on 05/11/2018.
//  Copyright © 2018 woong. All rights reserved.
//

import UIKit
import Firebase

class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var signup: UIButton!
    @IBOutlet weak var cancel: UIButton!
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: make statusBar
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (m) in
            m.right.top.left.equalTo(self.view)
            m.height.equalTo(40)
        }
        color = remoteConfig["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color)
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imagePicker)))
        
        signup.backgroundColor = UIColor(hex: color)
        cancel.backgroundColor = UIColor(hex: color)
        
        signup.addTarget(self, action: #selector(signupEvent), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)

        // Do any additional setup after loading the view.
    }
    
    @objc
    func imagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        imageView.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        if let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imageView.image = originalImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    func signupEvent() {
        print("signupEvent")
        Auth.auth().createUser(withEmail: email.text!, password: password.text!) { (authResult, error) in
            guard let uid = authResult?.user.uid else {
                return
            }
            
            let image = self.imageView.image?.jpegData(compressionQuality: 0.1)
            
            Storage.storage().reference().child("userImages").child(uid).putData(image!, metadata: nil, completion: { (metadata, error) in
                print("putData")
                Storage.storage().reference().child("userImages").child(uid).downloadURL(completion: { (url, error) in
                    guard let imageUrl = url?.absoluteString else {
                        return
                    }
                    print("downloadData \(String(describing: imageUrl))")
                    let value = ["userName":self.name.text!, "profileImageUrl":imageUrl]
                    Database.database().reference().child("users").child(uid).setValue(value, withCompletionBlock: { (err, ref) in
                        if (err == nil) {
                            self.cancelEvent()
                        }
                    })
                })
            })
            
           
        }
    }
    
    @objc
    func cancelEvent() {
        self.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
