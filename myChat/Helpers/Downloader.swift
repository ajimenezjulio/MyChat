//
//  Downloader.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 21/04/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
// This is for showing the loadind part of the message
import MBProgressHUD
import AVFoundation

let storage = Storage.storage()

// Image
func uploadImage(image: UIImage, chatRoomId: String, view: UIView, completion: @escaping(_ imageLink: String?) -> Void) {
    // Instantiate the progressHUD
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    
    progressHUD.mode = .determinateHorizontalBar
    let dateString = dateFormatter().string(from: Date())
    
    // Location to save the image
    let photoFileName = "PictureMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".jpg"
    
    // Access to the reference and create the child with the new path (the reference kFILEREFERENCE you can get it from Firebase in the "Storage" section)
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
    
    let imageData = image.jpegData(compressionQuality: 0.7)
    
    var task: StorageUploadTask!
    task = storageRef.putData(imageData!, metadata: nil, completion: { (metadata, error) in
        // Stop listening for any changes in the storage directory
        task.removeAllObservers()
        // Hide the progress bar
        progressHUD.hide(animated: true)
        
        // Check for errors
        if error != nil {
            print("Error uploading image \(error!.localizedDescription)")
            return
        }
        
        // If everything ok, get the URL of the image
        storageRef.downloadURL(completion: { (url, error) in
            // Check for the url, if not we need to tell our callback that we are done
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            // If we have a download Url, we call our completion and pass the url
            completion(downloadUrl.absoluteString)
        })
    })
    // We need this in order to present the progressHUD the information about how many percent has been upload
    task.observe(.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
}



func downloadImage(imageUrl: String, completion: @escaping(_ image: UIImage?) -> Void) {
    // Convert to NSURL
    let imageURL = NSURL(string: imageUrl)
    
    let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    // Check if exists
    if fileExistsAtPath(path: imageFileName) {
        // Exists
        // Check for the file
        if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)){
            // Callback the completion
            completion(contentsOfFile)
        }
    } else {
        // Not exists
        // Create a background queue
        let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: imageURL! as URL)
            
            // Check data
            if data != nil {
                // Save it locally
                var docURL = getDocumentsURL()
                // False because it's not a directory, just a file
                docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                // Atomatically means, that if there's a file with the same name, it will create a temporary file and once it was succesful, then it will delete the old file.
                data!.write(to: docURL, atomically: true)
                
                // Return the image
                let imageToReturn = UIImage(data: data! as Data)
                DispatchQueue.main.async {
                    completion(imageToReturn)
                }
            } else {
                DispatchQueue.main.async {
                    print("No image in database")
                    // Return nil
                    completion(nil)
                }
            }
        }
    }
    // Before donwloading the image, first check if the file already exists in the device
}



// MARK: Helpers

// Append the fileName to the Documents URL for a new file
func fileInDocumentsDirectory(fileName: String) -> String {
    let fileURL = getDocumentsURL().appendingPathComponent(fileName)
    return fileURL.path
}

// Get the general Documents URL
func getDocumentsURL() -> URL {
    let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    return documentURL!
}

func fileExistsAtPath(path: String) -> Bool {
    // By default, assume the file doesn't exist
    var doesExist = false
    
    let filePath = fileInDocumentsDirectory(fileName: path)
    let fileManager = FileManager.default
    
    // Check if the file exists
    if fileManager.fileExists(atPath: filePath) {
        doesExist = true
    } else {
        doesExist = false
    }
    
    return doesExist
}
