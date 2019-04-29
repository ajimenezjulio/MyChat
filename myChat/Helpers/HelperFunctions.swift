//
//  HelperFunctions.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 22/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore

//MARK: GLOBAL FUNCTIONS

private let dateFormat = "yyyyMMddHHmmss"

// Returns a date from a string in the corresponding format
func dateFormatter() -> DateFormatter {
    
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
    dateFormatter.dateFormat = dateFormat
    return dateFormatter
}


// Takes first name and last name and returns an Image with the initals of both names
func imageFromInitials(firstName: String?, lastName: String?, withBlock: @escaping (_ image: UIImage) -> Void) {
    
    var string: String!
    var size = 36
    
    // Get first character of both names if presented and make them bigger
    if firstName != nil && lastName != nil {
        string = String(firstName!.first!).uppercased() + String(lastName!.first!).uppercased()
    } else {
        string = String(firstName!.first!).uppercased()
        size = 72
    }
    
    // Create the image
    let lblNameInitialize = UILabel()
    lblNameInitialize.frame.size = CGSize(width: 100, height: 100)
    lblNameInitialize.textColor = .white
    lblNameInitialize.font = UIFont(name: lblNameInitialize.font.fontName, size: CGFloat(size))
    lblNameInitialize.text = string
    lblNameInitialize.textAlignment = NSTextAlignment.center
    lblNameInitialize.backgroundColor = UIColor.lightGray
    lblNameInitialize.layer.cornerRadius = 25
    
    UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
    lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    // Return image
    withBlock(img!)
}

// Converts a base64 string to an image
func imageFromData(pictureData: String, withBlock: (_ image: UIImage?) -> Void) {
    
    var image: UIImage?
    
    let decodedData = NSData(base64Encoded: pictureData, options: NSData.Base64DecodingOptions(rawValue: 0))
    
    image = UIImage(data: decodedData! as Data)
    
    withBlock(image)
}

func timeElapsed(date: Date) -> String {
    
    // Seconds that have been passed
    let seconds = NSDate().timeIntervalSince(date)
    
    var elapsed: String?
    
    // Seconds and minutes validations
    if (seconds < 60) {
        elapsed = "Just now"
    } else if (seconds < 60 * 60) {
        let minutes = Int(seconds / 60)
        
        var minText = "min"
        if minutes > 1 {
            minText = "mins"
        }
        elapsed = "\(minutes) \(minText)"
    
    // Hours validation
    } else if (seconds < 24 * 60 * 60) {
        let hours = Int(seconds / (60 * 60))
        var hourText = "hour"
        if hours > 1 {
            hourText = "hours"
        }
        elapsed = "\(hours) \(hourText)"
    } else {
        // Else just plot the date
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "dd/MM/YYYY"
        
        elapsed = "\(currentDateFormater.string(from: date))"
    }
    
    return elapsed!
}

//for avatars
func dataImageFromString(pictureString: String, withBlock: (_ image: Data?) -> Void) {
    
    let imageData = NSData(base64Encoded: pictureString, options: NSData.Base64DecodingOptions(rawValue: 0))
    
    withBlock(imageData as Data?)
}


//for calls and chats, returns an array of dictionaries from the snapshots
func dictionaryFromSnapshots(snapshots: [DocumentSnapshot]) -> [NSDictionary] {
    
    var allMessages: [NSDictionary] = []
    for snapshot in snapshots {
        allMessages.append(snapshot.data() as! NSDictionary)
    }
    return allMessages
}

func formatCallTime(date: Date) -> String {
    
    let seconds = NSDate().timeIntervalSince(date)
    
    var elapsed: String?
    
    
    if (seconds < 60) {
        elapsed = "Just now"
    }  else if (seconds < 24 * 60 * 60) {
        
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "HH:mm"
        
        elapsed = "\(currentDateFormater.string(from: date))"
    } else {
        let currentDateFormater = dateFormatter()
        currentDateFormater.dateFormat = "dd/MM/YYYY"
        
        elapsed = "\(currentDateFormater.string(from: date))"
    }
    
    return elapsed!
}


//MARK: UIImageExtension

extension UIImage {
    
    var isPortrait:  Bool    { return size.height > size.width }
    var isLandscape: Bool    { return size.width > size.height }
    var breadth:     CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize  { return CGSize(width: breadth, height: breadth) }
    var breadthRect: CGRect  { return CGRect(origin: .zero, size: breadthSize) }
    
    // Convert square image to circular image and centers it
    var circleMasked: UIImage? {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait  ? floor((size.height - size.width) / 2) : 0), size: breadthSize)) else { return nil }
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage).draw(in: breadthRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    
    func scaleImageToSize(newSize: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth = newSize.width/size.width
        let aspectheight = newSize.height/size.height
        
        let aspectRatio = max(aspectWidth, aspectheight)
        
        scaledImageRect.size.width = size.width * aspectRatio;
        scaledImageRect.size.height = size.height * aspectRatio;
        scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0;
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0;
        
        UIGraphicsBeginImageContext(newSize)
        draw(in: scaledImageRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}
