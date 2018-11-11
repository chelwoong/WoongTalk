//
//  ChatViewController.swift
//  WoongTalk
//
//  Created by woong on 11/11/2018.
//  Copyright © 2018 woong. All rights reserved.
//

import UIKit
import Firebase

var uid: String?
var chatRoomUid: String?

class ChatViewController: UIViewController {

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textfieldMessage: UITextField!
    
    public var destinationUid: String! // 대화할 상대의 uid
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        checkChatRoom()
        // Do any additional setup after loading the view.
    }
    
    @objc func createRoom() {
        let createRoomInfo: Dictionary<String,Any> = [ "users": [
            uid! : true,
            destinationUid! : true
            ]
        ]
        
        if (chatRoomUid == nil) {
            Database.database().reference().child("chatRooms").childByAutoId().setValue(createRoomInfo)
        } else {
            let value : Dictionary<String,Any> = [
                "comment":[
                    "uid": uid!,
                    "message": textfieldMessage.text!
                ]
            ]
            Database.database().reference().child("chatRomms").child(chatRoomUid!).child("comments").setValue(value)
        }
        
    }
    
    func checkChatRoom() {
        Database.database().reference().child("chatRooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: ({ (dataSnapshot) in
            for item in dataSnapshot.children.allObjects as! [DataSnapshot]{
                chatRoomUid = item.key
            }
        }))
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
