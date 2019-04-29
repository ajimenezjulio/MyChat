//
//  RecentChatTableViewCell.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 27/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import UIKit

// We need a delegate (so create a protocol) to notify from our cell to the ChatsViewController when the avatarImage is pressed.
// Name the protocol as the class where it's being used (this one)
protocol RecentChatTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}


class RecentChatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageCounterLabel: UILabel!
    @IBOutlet weak var messageCounterBackground: UIView!
    
    // This variable will be useful for our gesture recognizers, it store the tapped indexPath
    var indexPath: IndexPath!
    let tapGesture = UITapGestureRecognizer()
    var delegate: RecentChatTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Make it circled
        messageCounterBackground.layer.cornerRadius = messageCounterBackground.frame.width / 2
        
        // Add gesture recognizer
        tapGesture.addTarget(self, action: #selector(self.avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    
    // MARK: Generate cell

    func generateCell(recentChat: NSDictionary, indexPath: IndexPath) {
        self.indexPath = indexPath
        
        // Set the labels
        self.nameLabel.text = recentChat[kWITHUSERFULLNAME] as? String
        self.lastMessageLabel.text = recentChat[kLASTMESSAGE] as? String
        
        // Set the avatarImage
        if let avatarString = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarString as! String) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
        
        // Set the counter only if its non-zero
        if recentChat[kCOUNTER] as! Int != 0 {
            self.messageCounterLabel.text = "\(recentChat[kCOUNTER] as! Int)"
            self.messageCounterBackground.isHidden = false
            self.messageCounterLabel.isHidden = false
        } else {
            self.messageCounterBackground.isHidden = true
            self.messageCounterLabel.isHidden = true
        }
        
        // Set the date
        var date: Date!
        
        // If we already have a date
        if let created = recentChat[kDATE] {
            // If it's different from our date format, something's not right or it's empty and create a new one
            if (created as! String).count != 14 {
                date = Date()
            } else {
                // If everything's ok, transform string to date
                date = dateFormatter().date(from: created as! String)!
            }
        } else {
            // If there's no date then just create a new one
            date = Date()
        }
        
        // Compares de actual date with the created one and returns personalised messages, based on elapsed time (seconds, mins, hours or days)
        self.dateLabel.text = timeElapsed(date: date)
    }
    
    
    @objc func avatarTap() {
        delegate?.didTapAvatarImage(indexPath: indexPath)
    }
    
}
