//
//  ChatModel.swift
//  WoongTalk
//
//  Created by woong on 11/11/2018.
//  Copyright © 2018 woong. All rights reserved.
//

import UIKit

class ChatModel: NSObject {

    public var users: Dictionary<String,Bool> = [:] // 채팅에 참여한 사람들
    public var comments: Dictionary<String, Comment> = [:]  // 채팅방의 대화내용
    
    public class Comment {
        public var uid: String?
        public var message: String?
    }
}
