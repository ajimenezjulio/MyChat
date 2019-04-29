//
//  PhotoMediaItem.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 23/04/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class PhotoMediaItem: JSQPhotoMediaItem {
    // Returns a CGSize, we want to return different sizes depending on if the image is portrait or landscape
    override func mediaViewDisplaySize() -> CGSize {
        let defaultSize: CGFloat = 256
        
        var thumbSize: CGSize = CGSize(width: defaultSize, height: defaultSize)
        
        // Check if the image is right
        if self.image != nil && self.image.size.height > 0 && self.image.size.width > 0 {
            
            let aspect: CGFloat = self.image.size.width / self.image.size.height
            
            // If landscape
            if self.image.size.width > self.image.size.height{
                thumbSize = CGSize(width: defaultSize, height: defaultSize / aspect)
            } else {
                // Portrait
                thumbSize = CGSize(width: defaultSize * aspect, height: defaultSize)
            }
        }
        return thumbSize
    }
    
}
