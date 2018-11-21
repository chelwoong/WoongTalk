//
//  ChatRoomsViewController.swift
//  WoongTalk
//
//  Created by woong on 20/11/2018.
//  Copyright © 2018 woong. All rights reserved.
//

import UIKit
import Firebase

class ChatRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var uid: String!
    var chatrooms : [ChatModel]! = []

    @IBOutlet weak var tableview: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.uid = Auth.auth().currentUser?.uid
        self.getChatroomsList()

        // Do any additional setup after loading the view.
    }
    
    func getChatroomsList() {
        
        print("current uid: \(String(describing: self.uid!))")
        Database.database().reference().child("chatRooms").queryOrdered(byChild: "users/"+uid).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            
            self.chatrooms.removeAll()
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatroomdic = item.value as? [String: AnyObject] {
                    let chatModel = ChatModel(JSON: chatroomdic)
                    self.chatrooms.append(chatModel!)
                }
            }
            self.tableview.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        
        var destinationUid: String?
        
        for item in chatrooms[indexPath.row].users {
            
            if(item.key != self.uid) {
                destinationUid = item.key
            }
            
        }
        
        Database.database().reference().child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: {
            (datasnapshot) in
            
            let userModel = UserModel()
            //            print("databsnapshot.value: \(String(describing: datasnapshot.value))")
            print("userModel before: \(String(describing: userModel.uid))")
            userModel.setValuesForKeys(datasnapshot.value as! [String: AnyObject])
            print("userModel after: \(String(describing: userModel.uid))")
            
            cell.labelTitle.text = userModel.userName
            let url = URL(string: userModel.profileImageUrl!)
            
            print("url: \(String(describing: url))")
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
                DispatchQueue.main.sync {
                    cell.imageview.image = UIImage(data: data!)
                    cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
                    cell.imageview.layer.masksToBounds = true
                }
            }).resume()
            
            
            let lastMessageKey = self.chatrooms[indexPath.row].comments.keys.sorted(){$0>$1} // $0>$1 오름차순, $0<$1 내림차순
            cell.labelLastmessage.text = self.chatrooms[indexPath.row].comments[lastMessageKey[0]]?.message
            
        })
        
        
        
        
        return cell
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 새로 처음부터 로딩
        viewDidLoad()
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

class CustomCell: UITableViewCell {
    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelLastmessage: UILabel!
}
