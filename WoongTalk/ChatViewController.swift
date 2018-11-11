//
//  ChatViewController.swift
//  WoongTalk
//
//  Created by woong on 11/11/2018.
//  Copyright © 2018 woong. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var sendButton: UIButton!
    
    public var destinationUid: String! // 대화할 상대의 uid
    override func viewDidLoad() {
        super.viewDidLoad()

        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }
    
    @objc func createRoom() {
        let createRoomInfo = [
            "uid": Auth.auth().currentUser?.uid,
            "destinationUid": destinationUid
        ]
        Database.database().reference().child("chatRooms").childByAutoId().setValue(createRoomInfo)
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
