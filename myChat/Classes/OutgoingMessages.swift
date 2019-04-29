//
//  OutgoingMessages.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 01/04/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import Foundation

class OutgoingMessage {
    
    let messageDictionary: NSMutableDictionary
    
    
    
    // MARK: Initializers
    
    // Text Message
    init(message: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // Picture Message
    init(message: String, pictureLink: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        messageDictionary = NSMutableDictionary(objects: [message, pictureLink, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kPICTURE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    
    
    // MARK: SendMessage
    func sendMessage(chatRoomId: String, messageDictionary: NSMutableDictionary, memberIds: [String], membersToPush: [String]) {
        // Generate a unique ID for the chat
        let messageId = UUID().uuidString
        messageDictionary[kMESSAGEID] = messageId
        
        // Save this message for each user (this is necessary because when we delete some message we remove it just for us not for the entire people in the chatRoom)
        for memberId in memberIds {
            // Save the message (First we access to the message collection which has the user references, each reference has all the chatRoomsId in which the current user is in, and the chatRooms contain the messageId)
            reference(.Message).document(memberId).collection(chatRoomId).document(messageId).setData(messageDictionary as! [String: Any])
        }
        
        // Update recent chat
        
        // Send push notifications
    }
}
