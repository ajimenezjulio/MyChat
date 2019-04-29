//
//  IncomingMessages.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 01/04/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessage {
    
    var collectionView: JSQMessagesCollectionView
    
    init(collectionView_: JSQMessagesCollectionView) {
        self.collectionView = collectionView_
    }
    
    
    
    // MARK: CreateMessage
    func createMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage? {
        
        var message: JSQMessage?
        
        // Check for the type of mesasge we receive
        let type = messageDictionary[kTYPE] as! String
        
        switch type {
        case kTEXT:
            message = createTextMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        case kPICTURE:
            message = createPictureMessage(messageDictionary: messageDictionary)
        case kVIDEO:
            print("Create video message")
        case kAUDIO:
            print("Create audio message")
        case kLOCATION:
            print("Create location message")
            
        default:
            print("Unknown message type")
        }
        
        // Check if message variable is not equal to nil
        if message != nil {
            return message
        }
        
        return nil
    }
    
    
    
    // MARK: Create Message Types
    func createTextMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        // Check if we already have a date value
        var date: Date!
        
        if let created = messageDictionary[kDATE] {
            // If the date characters are different from 14 (our date format), then create a new one
            if (created as! String).count != 14 {
                date = Date()
            } else {
                // Convert from string to date
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        // Get the text
        let text = messageDictionary[kMESSAGE] as! String
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: text)
    }
    
    
    func createPictureMessage(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        // Check if we already have a date value
        var date: Date!
        
        if let created = messageDictionary[kDATE] {
            // If the date characters are different from 14 (our date format), then create a new one
            if (created as! String).count != 14 {
                date = Date()
            } else {
                // Convert from string to date
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        // This is for abling landscape and portrait image view, its a custom class. First instantiate to nil
        let mediaItem = PhotoMediaItem(image: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userId!)
        
        // Download image
        downloadImage(imageUrl: messageDictionary[kPICTURE] as! String) { (image) in
            // Check for the image
            if image != nil {
                // Set the media item to the image we already get
                mediaItem!.image = image!
                // Refresh the view
                self.collectionView.reloadData()
            }
        }
        // Return the message
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    
    
    // MARK: Helpers
    
    func returnOutgoingStatusForUser(senderId: String) -> Bool {
        // If we are the sender then it's an outgoing returns true, else false
        return senderId == FUser.currentId()
    }
    
}
