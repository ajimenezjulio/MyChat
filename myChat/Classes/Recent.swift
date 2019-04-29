//
//  Recent.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 27/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import Foundation

func startPrivateChat(user1: FUser, user2: FUser) -> String {
    // Get ids of both user
    let userId1 = user1.objectId
    let userId2 = user2.objectId
    
    // Variable for the id of the chat between these two users
    var chatRoomId = ""
    
    // I'm not sure what exactly compares does but returns always a -1 if one user starts the chat and 1 if the other one starts, so gives you the lexical order and you can then sum it to always create the same id
    let value = userId1.compare(userId2).rawValue
    // Sum the ids to always get the same id
    if value < 0 {
        chatRoomId = userId1 + userId2
    } else {
        chatRoomId = userId2 + userId1
    }
    
    // Set the members
    let members = [userId1, userId2]
    
    // Create recent chats
    createRecent(members: members, chatRoomId: chatRoomId, withUserUserName: "", type: kPRIVATE,
                 users: [user1, user2], avatarOfGroup: nil)
    
    return chatRoomId
}


// Create recent chats, the type parameter is for "private" or "group" chat
func createRecent(members:[String], chatRoomId: String, withUserUserName: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
    // In order to manipulate the members we need a temp variable
    var tempMembers = members
    
    // Access to the recent area in firebase and check if the chatRoom already exist
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        // Check if we got a snapshot
        guard let snapshot = snapshot else { return }
        
        // Now check if the snapshot is not empty
        if !snapshot.isEmpty {
            // Iterating for every recent chat the user have
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                // If recent belongs to our currentUser
                if let currentUserId = currentRecent[kUSERID] {
                    // Remove user if it has a recent object
                    if tempMembers.contains(currentUserId as! String) {
                        tempMembers.remove(at: tempMembers.index(of: currentUserId as! String)!)
                    }
                }
            }
        }
        
        // Create recent items for remaining users
        for userId in tempMembers {
            // Create the item
            createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUserName: withUserUserName, type: type, users: users, avatarOfGroup: avatarOfGroup)
        }
    }
}


func createRecentItem(userId: String, chatRoomId: String, members: [String], withUserUserName: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
    
    // Create a reference to our recents in firebase and also point (initialise) to the documents area to generate a new id
    let localReference = reference(.Recent).document()
    // Get the previous automatic generated id
    let recentId = localReference.documentID
    // Create the date
    let date = dateFormatter().string(from: Date())
    
    var recent: [String: Any]!
    
    if type == kPRIVATE {
        // Private
        var withUser: FUser?
        // Check for which user we are creating the recent
        if users != nil && users!.count > 0 {
            // If is for our current user (by default the first user is our current user)
            if userId == FUser.currentId() {
                withUser = users!.last!
            } else {
                // We are creating for the other user
                withUser = users!.first!
            }
        }
        // Creating the dictionary
        
        // kCOUNTER will be the blue badge of the number of unread messages
        recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUser!.fullname, kWITHUSERUSERID: withUser!.objectId, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: withUser!.avatar] as [String: Any]
        
    } else {
        // Group
        
        // If there's an avatar in the group
        if avatarOfGroup != nil {
            recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUserUserName, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: avatarOfGroup!] as [String: Any]
        }
    }
    
    // Save recent chat
    localReference.setData(recent)
}



// MARK: Restart Recent Chat

func restartRecentChat(recent: NSDictionary) {
    // Check for the type of chat to restart (private case)
    // We use KMEMBERSTOPUSH because it has the info about the users that are not muted, if someone of the users mutes the chat we will not recreate the chat for him
    if recent[kTYPE] as! String == kPRIVATE {
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserName: FUser.currentUser()!.firstname, type: kPRIVATE, users: [FUser.currentUser()!], avatarOfGroup: nil)
    }
    
    // In case of group type
    if recent[kTYPE] as! String == kGROUP {
        createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserName: recent[kWITHUSERUSERNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: recent[kAVATAR] as? String)
    }
}



// MARK: Delete Recent Chat

func deleteRecentChat(recentChatDictionary: NSDictionary) {
    // Check for the id
    if let recentId = recentChatDictionary[kRECENTID] {
        // If everything ok, delete
        reference(.Recent).document(recentId as! String).delete()
    }
}

