//
//  VideoMessage.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 30/04/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class VideoMessage: JSQMediaItem {
    var image: UIImage?
    var videoImageView: UIImageView?
    var status: Int?
    var fileURL: NSURL?
    
    init(withFileURL: NSURL, maskOutgoing: Bool) {
        super.init(maskAsOutgoing: maskOutgoing)
        self.fileURL = withFileURL
        self.videoImageView = nil
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mediaView() -> UIView! {
        if let st = status {
            // Status 1 means not ready to play
            if st == 1 {
                return nil
            }
            if st == 2 && (self.videoImageView == nil) {
                let size = self.mediaViewDisplaySize()
                // Check if our messages are outgoing or not
                let outgoing = self.appliesMediaViewMaskAsOutgoing
                
                // Get play icon
                let icon = UIImage.jsq_defaultPlay()?.jsq_imageMasked(with: .white)
                let iconView = UIImageView(image:icon)
                iconView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                iconView.contentMode = .center
                
                // Set imageView (set our thumbnail)
                let imageView = UIImageView(image: self.image!)
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView.contentMode = .scaleAspectFill
                // With this it will not go out of our imageViewBounds
                imageView.clipsToBounds = true
                imageView.addSubview(iconView)
                
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imageView, isOutgoing: outgoing)
                self.videoImageView = imageView
            }
        }
        return self.videoImageView
    }
}
