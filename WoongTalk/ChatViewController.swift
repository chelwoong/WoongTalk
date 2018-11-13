//
//  ChatViewController.swift
//  WoongTalk
//
//  Created by woong on 11/11/2018.
//  Copyright © 2018 woong. All rights reserved.
//

import UIKit
import Firebase



class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var uid: String?
    var chatRoomUid: String?
    
    var comments : [ChatModel.Comment] = []

    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textfieldMessage: UITextField!
    
    public var destinationUid: String! // 대화할 상대의 uid
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let view = tableview.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        view.textLabel?.text = self.comments[indexPath.row].message
        
        return view
    }
    
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
            // 생성되는동안 버튼이 눌리면 안됨
            self.sendButton.isEnabled = false
            // 방 생성 코드
            Database.database().reference().child("chatRooms").childByAutoId().setValue(createRoomInfo, withCompletionBlock: { (err, ref) in
                if(err == nil) {
                    self.checkChatRoom()
                }
                
            })
        } else {
            let value : Dictionary<String,Any> = [
                "uid": uid!,
                "message": textfieldMessage.text!
            ]
            Database.database().reference().child("chatRooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value)
        }
    }
    
    func checkChatRoom() {
        Database.database().reference().child("chatRooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: ({ (dataSnapshot) in
            for item in dataSnapshot.children.allObjects as! [DataSnapshot]{
                
                // 내가 대화할 상대방을 체크하는 코드
                if let chatRoomdic = item.value as? [String:AnyObject] {
                    let chatModel = ChatModel(JSON: chatRoomdic)
                    if(chatModel?.users[self.destinationUid!] == true) {
                        self.chatRoomUid = item.key
                        // 방 키를 받아왔으면 다시 버튼 on
                        self.sendButton.isEnabled = true
                        
                        self.getMessageList()
                    }
                }
            }
        }))
    }
    
    func getMessageList() {
        Database.database().reference().child("chatRooms").child(self.chatRoomUid!).child("comments").observe(DataEventType.value, with: { (dataSnapshot) in
            
            // 데이터가 쌓일 수 있으니 초기화
            self.comments.removeAll()
            
            for item in dataSnapshot.children.allObjects as! [DataSnapshot] {
                let comment = ChatModel.Comment(JSON: item.value as! [String : AnyObject])
                self.comments.append(comment!)
            }
            self.tableview.reloadData()
        })
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
