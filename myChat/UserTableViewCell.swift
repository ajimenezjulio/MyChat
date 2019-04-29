//
//  UserTableViewCell.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 23/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    var indexPath: IndexPath!
    
    let tapGestureRecognizer = UITapGestureRecognizer()
    
    // This is a viewDidLoad function but for cells
    override func awakeFromNib() {
        super.awakeFromNib()
        // Add target to tapGestureRecognizer
        tapGestureRecognizer.addTarget(self, action: #selector(self.avatarTap))
        // Activate interaction in avatarImageView
        avatarImageView.isUserInteractionEnabled = true
        // Add the same functionality of our gestureRecognizer to the avatarImageView
        avatarImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    // Generate the cell, requires a user and an index path
    func generateCellWith(fUser: FUser, indexPath: IndexPath) {
        // Set the index path
        self.indexPath = indexPath
        // Set the name
        self.fullNameLabel.text = fUser.fullname
        // Set the image (from base64 str to UIImage)
        if fUser.avatar != "" {
            imageFromData(pictureData: fUser.avatar) { (avatarImage) in
                if avatarImage != nil {
                    // circleMasked is an extension we create for shaping circular the image
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    func avatarTap() {
        print("avatar tap at \(indexPath)")
    }
    
}
