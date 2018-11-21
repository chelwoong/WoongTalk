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

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var uid: String?
    var chatRoomUid: String?
    
    var comments : [ChatModel.Comment] = []
    var userModel : UserModel?

    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textfieldMessage: UITextField!
    
    public var destinationUid: String! // 대화할 상대의 uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        checkChatRoom()
        // tabbar off
        self.tabBarController?.tabBar.isHidden = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    // 시작
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let center = NotificationCenter.default
        
        print("viewWillAppear")
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // 종료
    // 다시 tabbar on
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc
    func keyboardWillShow(notification: Notification) {
        
        guard let keyboardInfo = notification.userInfo else {
            return
        }
        
        
        if let keyboardSize = (keyboardInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            print("// keyboardSize: \(keyboardSize.height)")
            self.bottomConstraint.constant = keyboardSize.height
        }
        
        UIView.animate(withDuration: 0, animations: {
            self.view.layoutIfNeeded()
        }, completion: {
            (completion) in
            
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item: self.comments.count-1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
            }
        })
    }
    
    @objc
    func keyboardWillHide(notification: Notification) {
        print("// willHide")
        self.bottomConstraint.constant = 20
        self.view.layoutIfNeeded()
    }
    
    @objc
    func dismissKeyboard() {
        print("// dismisskeyboard")
        self.view.endEditing(true)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (self.comments[indexPath.row].uid == uid) {
            let view = tableview.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            view.labelMessage.text = self.comments[indexPath.row].message
            view.labelMessage.numberOfLines = 0
            if let time = self.comments[indexPath.row].timestamp {
              view.labelTimestamp.text = time.toDayTime
            }
            
            return view
        } else {
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.labelName.text = userModel?.userName
            view.labelMessage.text = self.comments[indexPath.row].message
            view.labelMessage.numberOfLines = 0
            let url = URL(string: ((self.userModel?.profileImageUrl)!))
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
                DispatchQueue.main.async {
                    view.imageviewProfile.image = UIImage(data: data!)
                    view.imageviewProfile.layer.cornerRadius = view.imageviewProfile.frame.width/2
                    view.imageviewProfile.clipsToBounds = true
                }
            }).resume()
            if let time = self.comments[indexPath.row].timestamp {
                view.labelTimestamp.text = time.toDayTime
            }
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    @objc func createRoom() {
        let createRoomInfo: Dictionary<String,Any> = [ "users": [
            uid! : true,
            destinationUid! : true
            ]
        ]
        
        if (chatRoomUid == nil) {
            print("roomUid == nil")
            // 생성되는동안 버튼이 눌리면 안됨
            self.sendButton.isEnabled = false
            // 방 생성 코드
            Database.database().reference().child("chatRooms").childByAutoId().setValue(createRoomInfo, withCompletionBlock: { (err, ref) in
                if(err == nil) {
                    print("err == nil")
                    self.checkChatRoom()
                }
            })
            
        } else {
            print("roomUid != nil")
            let value : Dictionary<String,Any> = [
                "uid": uid!,
                "message": textfieldMessage.text!,
                "timestamp": ServerValue.timestamp()
            ]
            Database.database().reference().child("chatRooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value, withCompletionBlock: { (err, ref) in
                self.textfieldMessage.text = ""
                
            })
        }
    }
    
    func checkChatRoom() {
        print("checkChatRoom: \(self.chatRoomUid ?? "nil")")
        print("destinationUid: \(self.destinationUid ?? "nil")")
        Database.database().reference().child("chatRooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: { (dataSnapshot) in
            for item in dataSnapshot.children.allObjects as! [DataSnapshot]{
                
                // 내가 대화할 상대방을 체크하는 코드
                if let chatRoomdic = item.value as? [String:AnyObject] {
                    let chatModel = ChatModel(JSON: chatRoomdic)
                    if(chatModel?.users[self.destinationUid!] == true) {
                        self.chatRoomUid = item.key
                        // 방 키를 받아왔으면 다시 버튼 on
                        self.sendButton.isEnabled = true
                        
                        self.getDestinationInfo()
                        
                    }
                }
            }
        })
  
    }
    
    
    func getDestinationInfo() {
        print("getDestinationInfo: \(self.destinationUid ?? "nil")")
        Database.database().reference().child("users").child(self.destinationUid!).observe(DataEventType.value, with: { (dataSnapshot) in
            self.userModel = UserModel()
            self.userModel?.setValuesForKeys(dataSnapshot.value as! [String:Any])
            self.getMessageList()
        })
    }
    
    func getMessageList() {
        print("getMessageList: \(self.chatRoomUid ?? "nil")")
        Database.database().reference().child("chatRooms").child(self.chatRoomUid!).child("comments").observe(DataEventType.value, with: { (dataSnapshot) in
            print("in getMessageList snap: \(dataSnapshot.exists())")
            
            if dataSnapshot.exists() == false {
                let value : Dictionary<String,Any> = [
                    "uid": self.uid!,
                    "message": self.textfieldMessage.text!,
                    "timestamp": ServerValue.timestamp()
                ]
                Database.database().reference().child("chatRooms").child(self.chatRoomUid!).child("comments").childByAutoId().setValue(value, withCompletionBlock: { (err, ref) in
                    self.textfieldMessage.text = ""

                })
            } else {
                // 데이터가 쌓일 수 있으니 초기화
                self.comments.removeAll()
                
                for item in dataSnapshot.children.allObjects as! [DataSnapshot] {
                    let comment = ChatModel.Comment(JSON: item.value as! [String : AnyObject])
                    self.comments.append(comment!)
                }
                self.tableview.reloadData()
                
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item: self.comments.count-1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
                }
            }
            
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

extension Int {
    
    var toDayTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        let date = Date(timeIntervalSince1970: Double(self)/1000)
        return dateFormatter.string(from: date)
        
    }
}

class MyMessageCell: UITableViewCell {
    
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var labelTimestamp: UILabel!
}

class DestinationMessageCell: UITableViewCell {
    
    @IBOutlet weak var imageviewProfile: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var labelTimestamp: UILabel!
}
