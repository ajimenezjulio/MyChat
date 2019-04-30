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
            message = createVideoMessage(messageDictionary: messageDictionary)
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
    
    func createVideoMessage(messageDictionary: NSDictionary) -> JSQMessage {
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
        
        // Get video url
        let videoURL = NSURL(fileURLWithPath: messageDictionary[kVIDEO] as! String)
        
        // Creating a video message object
        let mediaItem = VideoMessage(withFileURL: videoURL, maskOutgoing: returnOutgoingStatusForUser(senderId: userId!))
        
        // Download image
        downloadVideo(videoUrl: messageDictionary[kVIDEO] as! String) { (isReadyToPlay, fileName) in
            // Get the fileUrl and update the status
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
            mediaItem.status = kSUCCESS
            mediaItem.fileURL = url
            
            // Get the thumbnail
            imageFromData(pictureData: messageDictionary[kPICTURE] as! String, withBlock: { (image) in
                // Check for the image and assign it
                if image != nil {
                    mediaItem.image = image!
                    // Refresh view
                    self.collectionView.reloadData()
                }
            })
            // Also refresh when we set our video (loading animation needs to dissapear)
            self.collectionView.reloadData()
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
