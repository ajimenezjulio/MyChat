//
//  ChatViewController.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 29/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
// For audio messages
import IQAudioRecorderController
// To see our images messages in full screen
import IDMPhotoBrowser
// AVFoundation and AVKit is for video messages
import AVFoundation
import AVKit
// Get messages from firebase
import FirebaseFirestore



// Fix for iPhone X (space of the bottom chat toolbox)
extension JSQMessagesInputToolbar {
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        if #available(iOS 11.0, *), let window = self.window {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
        }
    }
}
// End iPhone X fix
// ADDITIONALLY, THE toggleSendButtonEnabled (look in search bar in Xcode for this function) WAS CHANGED IN ORDER THE BUTTON WILL BE ACTIVE, EVEN WHEN NO TEXT HAD BEEN INTRODUCED AND CLEAN THE PROJECT AFTER IT.



// FIRST THING TO DO IS REPLACE THE CLASS OF UIVIEWCONTROLLER WITH JSQMESSAGESVIEWCONTROLLER
class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Global variables for the chatRoomId, memberIds and membersToPush. They will be passed from the previous ViewController
    var chatRoomId: String!
    var memberIds: [String]!
    var membersToPush: [String]!
    var titleName: String!
    
    // In case of group chat
    var isGroup: Bool?
    var group: NSDictionary?
    
    // Keep track the users we are chatting with
    var withUsers: [FUser] = []
    
    // Listeners
    var newChatListener: ListenerRegistration?
    // Listener for when the other users are typing
    var typingListener: ListenerRegistration?
    // Listener to change the status in the chat
    var updatedChatListener: ListenerRegistration?
    
    // Types of messages
    let legitTypes = [kTEXT, kPICTURE, kAUDIO, kVIDEO, kLOCATION]
    
    // Boundaries of number of messages
    var maxMessageNumber = 11
    var minMessageNumber = 0
    // Flag for loading older messages
    var loadOld = false
    // Counter of current loaded messages
    var loadedMessagesCount = 0
    
    // Variables to hold the messages
    var messages: [JSQMessage] = []
    // Here we will save the messages but as NSDictionaries
    var objectMessages: [NSDictionary] = []
    // Here we store the messages we load
    var loadedMessages: [NSDictionary] = []
    var allPictureMessages: [String] = []
    
    // Flag for initial load completion
    var initialLoadComplete = false
    
    // Bubbles of messages when you send it and receive in whatsapp they're green and white
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    
    
    // MARK: CustomHeaders
    
    let leftBarButtonView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    
    let avatarButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    
    let titleLabel: UILabel = {
        let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 14)
        return title
    }()
    
    let subtitleLabel: UILabel = {
        let subtitle = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        subtitle.textAlignment = .left
        subtitle.font = UIFont(name: subtitle.font.fontName, size: 10)
        return subtitle
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change the large title mode, we don't want it here. We want the small and tidy style
        navigationItem.largeTitleDisplayMode = .never
        // Set custom button as the back button (Just the back arrow, we don't want to display the name)
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
        
        // Set the avatar ingoing and outgoing size to 0 as initial point
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        // Set custom title
        setCustomTitle()
        
        // Load messages
        loadMessages()
        
        // These two variables are part of JSQMessagesViewController and hence are required to implement
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()!.firstname
        
        // Custom send button (microphone)
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Automatically scroll down to the end of the view
        self.finishReceivingMessage(animated: true)
    }
    

    
    // MARK: JSQMessages DataSource functions
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
       
        let data = messages[indexPath.row]
        
        // Set text color
        // Check if it's an outgoing message
        if data.senderId == FUser.currentId() {
            cell.textView?.textColor = .white
        } else {
            cell.textView?.textColor = .black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        // Display messages
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // Create differents bubbles for incoming and outgoing
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        // Check if it's an outgoing message
        if data.senderId == FUser.currentId() {
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        // Display timestamp every 3 items
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.row]
            return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
        }
        // Otherwise return nil
        return nil
    }
    
    // In order to display timestamp, we need to provide a height to the view which will contain the time label
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.row % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        // Otherwise return 0
        return 0.0
    }
    
    // Show deliever status just in the last message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        // Messages and objectMessages are in sync, so it's the right one
        let message = objectMessages[indexPath.row]
        
        let status: NSAttributedString!
        let attributedStringColor = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        
        // Change the text displayed depending on status
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            // When readed also add the date in the status
            let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)
            status = NSAttributedString(string: statusText, attributes: attributedStringColor)
        default:
            status = NSAttributedString(string: "✔︎")
        }
        
        // Just displayed the text if it's the last message
        if indexPath.row == (messages.count - 1) {
            return status
        } else {
            return NSAttributedString(string: "")
        }
    }
    
    // In order to display the status, we need to provide a height to the view which will contain the status label
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = messages[indexPath.row]
        
        // Check if we are the sender, we just need the status label in the outgoing (our) messages
        if data.senderId == FUser.currentId() {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    
    
    // MARK: JSQMessages Delegate Functions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        // Create instance of camera
        let camera = Camera(delegate_: self)
        
        // Create a show menu (with no title or message)
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Create actions
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            camera.PresentMultyCamera(target: self, canEdit: false)
        }
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            // Present photo library
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            // Present video library
            camera.PresentVideoLibrary(target: self, canEdit: false)
        }
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            print("Share Location")
        }
        // We don't have to do anything, by default cancel just dismiss the menuView
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        // Add the images to the actions
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        // Asseble everything
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(shareLocation)
        optionMenu.addAction(cancelAction)
        
        // We need to check if it's an iPad before presenting, because the settings change (even if the app is only for iPhone apple requires this in order that iPads can run it in compatibility mode)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if let currentPopoverPresentationController = optionMenu.popoverPresentationController {
                currentPopoverPresentationController.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverPresentationController.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverPresentationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        } else {
            // If it's iphone just present normally
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        // It's two in one, if it has text, then the button must say "send" else a microphone icon should appear
        if text != "" {
            // Just sending a text message
            self.sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            // Update send button icon and title
            updateSendButton(isSend: false)
        } else {
            print("Audio message")
        }
    }
    
    // Functionality when pressing the "Load Earlier Messages" button
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        // Load more messages
        self.loadMoreMessages(maxNumber: maxMessageNumber, minNumber: minMessageNumber)
        self.collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        // Get the message and the type of message
        let messageDictionary = self.objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        // Get our message
        let message = messages[indexPath.row]
        
        // Swith for all the types of messages
        switch messageType {
        case kPICTURE:
            let mediaItem = message.media as! JSQPhotoMediaItem
            let photos = IDMPhoto.photos(withImages: [mediaItem.image])
            let browser = IDMPhotoBrowser(photos: photos)
            self.present(browser!, animated: true, completion: nil)
        case kLOCATION:
            print("Location mess tapped")
        case kVIDEO:
            let mediaItem = message.media as! VideoMessage
            // Instantiate player
            let player = AVPlayer(url: mediaItem.fileURL! as URL)
            let moviePLayer = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            moviePLayer.player = player
            // As soon as open the video it will start automatically
            self.present(moviePLayer, animated: true){
                moviePLayer.player!.play()
            }
            
        default:
            print("Unknown mess tapped")
        }
    }
    
    
    // MARK: Send Messages
    
    // Depending on the information we pass, it will generate the message
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        // Create an object of our custom class
        var outgoingMessage: OutgoingMessage?
        // This is just for comfort, we are going to use this variable many times
        let currentUser = FUser.currentUser()!
        
        // Text message
        // If text is not nil, so it's a text message
        if let text = text {
            outgoingMessage = OutgoingMessage(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        
        // Picture message
        if let pic = picture {
            uploadImage(image: pic, chatRoomId: self.chatRoomId, view: self.navigationController!.view) { (imageLink) in
                // Check for the image link
                if imageLink != nil {
                    let text = "[\(kPICTURE)]"
                    // Instantiate the outgoing message
                    outgoingMessage = OutgoingMessage(message: text, pictureLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    // Play the message sent sound
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    // Send the message
                    outgoingMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
            }
            // If upload is not succesful
            return
        }
        
        // Video message
        if let video = video {
            // Get our video
            let videoData = NSData(contentsOfFile: video.path!)
            // Get first image of video (thumbnail), 0.3 because we just want the first frame for thumbnail not a big picture
            let dataThumbnail = videoThumbnail(video: video).jpegData(compressionQuality: 0.3)
            
            // Upload the video
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: self.navigationController!.view) { (videoLink) in
                // Check for the video
                if videoLink != nil {
                    // Text for our last message (in this case a video). It shows "[video]
                    let text = "[\(kVIDEO)]"
                    
                    // Instantiate the outgoing message
                    outgoingMessage = OutgoingMessage(message: text, videoLink: videoLink!, thumbnail: dataThumbnail! as NSData, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    // Play the message sent sound
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    // Send the message
                    outgoingMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
            }
            // If upload is not succesful
            return
        }
        
        // Add sound to sended message and clean the inputText toolbox
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        // Send the message
        outgoingMessage!.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
    }
    
    
    
    // MARK: LoadMessages
    
    func loadMessages() {
        // Get last 11 messages (load just a few, if we load everything, it will take too long). Remember when accesing to the .Message firebase reference, first is the "Users" area and then the "ChatRoomId" area
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
             // Check for snapshot
            guard let snapshot = snapshot else {
                // Initial loading is done (could be a new chat so no items)
                self.initialLoadComplete = true
                // Start listen for new chat
                return
            }
            // Get the messages
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            // Remove bad or corrupted messages
            self.loadedMessages = self.removeBadMessages(allMessages: sorted)
            
            // Insert messages (convert to JSQMessages)
            self.insertMessages()
            // After inserting the messages we want to automatically scroll down to the end of the view
            self.finishReceivingMessage(animated: true)
            
            self.initialLoadComplete = true
            
            print("We have \(self.messages.count) messages loaded")
            // Get picture messages
            
            // Get all messages in background
            self.getOldMessagesInBackground()
            
            // Start listening for new chats
            self.listenForNewChats()
            
        }
    }
    
    func listenForNewChats() {
        var lastMessageDate = "0"
        
        // Check if we have loaded some messages
        if loadedMessages.count > 0 {
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }
        
        // Create a listener in order to listen for new chats, but just in the chatView
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
            // Check for snapshot
            guard let snapshot = snapshot else { return }
            // Check if snapshot is not empty
            if !snapshot.isEmpty {
                for diff in snapshot.documentChanges {
                    // We need to check for new added elements
                    if diff.type == .added {
                        let item  = diff.document.data() as NSDictionary
                        
                        // Check if it's a proper message
                        if let type = item[kTYPE]{
                            // Check if we have a legit message
                            if self.legitTypes.contains(type as! String) {
                                // This for picture messages
                                if type as! String == kPICTURE {
                                    // Add to pictures
                                }
                                // For any other message
                                if self.insertInitialLoadMessages(messageDictionary: item) {
                                    // Play the sound for new message received
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                // Refresh collection view and scroll to the bottom
                                self.finishReceivingMessage()
                            }
                        }
                    }
                }
            }
        })
    }
    
    func getOldMessagesInBackground() {
        // Check if we have any messages, greater than 11, because we load the first 11 messages at the beginning
        if loadedMessages.count > 10 {
            let firstMessageDate = loadedMessages.first![kDATE] as! String
            
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                // Check for the snapshot
                guard let snapshot = snapshot else { return }
                
                // Sorting the messages by date, get them as NSArray so we can sort them
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                // Put the right old messages at the beginning and append the loadedMessages (the last ones)
                self.loadedMessages = self.removeBadMessages(allMessages: sorted) + self.loadedMessages
                
                // Get the picture messages
                
                // Update the max and min number of messages
                self.maxMessageNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
            }
        }
    }
    
    
    
    // MARK: InsertMessages
    
    func insertMessages() {
        maxMessageNumber = loadedMessages.count - loadedMessagesCount
        // kNUMBEROFMESSAGES is 10 by default, we can change it
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            // We don't want a negative value
            minMessageNumber = 0
        }
        
        for i in minMessageNumber ..< maxMessageNumber {
            // Get the dictionary of the respective message
            let messageDictionary = loadedMessages[i]
            
            // Insert message
            insertInitialLoadMessages(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        
        // This is for show the label of "Load Earlier messages", if we load more, then show it. Else don't, there's no reason because we have loaded less messages
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func insertInitialLoadMessages(messageDictionary: NSDictionary) -> Bool {
        
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        // Check if message is incoming or outgoing
        // Check who's the sender
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId(){
            // Incoming message
            // First update the status - change the message status to readed
        }
        
        // Get our message
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: self.chatRoomId)
        
        // Check if the returned message is not nil
        if message != nil {
            // Append message as dictionary and as JSQMessage - both arrays have to be in sync
            self.objectMessages.append(messageDictionary)
            self.messages.append(message!)
        }
        
        // Return a bool, false for outgoing and true for incoming message
        return isIncoming(messageDictionary: messageDictionary)
    }
    
    
    
    // MARK: LoadMoreMessages
    
    func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        // Check if we are loading old chats, this is for solving the problem of 11 (N) messages
        if loadOld {
            maxMessageNumber = minNumber - 1
            minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        }
        
        // If minMessageNumber is less than 0, set it to zero, don't want negatives
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        // It has to be reversed to put them in order
        for i in (minMessageNumber ... maxMessageNumber).reversed() {
            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            // Keep track of how many messaes we have loaded in the chat
            loadedMessagesCount += 1
        }
        loadOld = true
        // We need to check if there's any more messages to load
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func insertNewMessage(messageDictionary: NSDictionary) {
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: self.chatRoomId)
        
        // Insert message to array of JSQMessage and objecMessages
        // Insert at the beginning
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
    }
    
    
    
    // MARK: IBActions
    
    @objc func backAction() {
        // For going back, we just need to pop the actual VC and we will be back
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func infoButtonPressed() {
        print("Show image messages")
    }
    
    @objc func showGroup() {
        print("Show group")
    }
    
    @objc func showUserProfile() {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        // Pass the user we are chating with
        profileVC.user = withUsers.first!
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    
    // MARK: CustomSendButton
    
    // Change the button when the user is typing some message
    override func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
    }
    
    // Toogles the send button, between send title and microphone
    func updateSendButton(isSend: Bool) {
        if isSend {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        } else {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }

    
    
    // MARK: UpdateUI
    func setCustomTitle() {
        // Add subviews to the leftBarButton
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subtitleLabel)
        
        // Set the rightBarButtonItem to be an info button
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
        self.navigationItem.rightBarButtonItem = infoButton
        
        // Set the leftBarButtonItem
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        // Plural (Items)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        // Check if it's a group chat
        if isGroup! {
            avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
        } else {
            // One to one chat
            avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
        }
        
        getUsersFromFirestore(withIds: self.memberIds) { (withUsers) in
            // Set the users we are chatting with
            self.withUsers = withUsers
            
            // Get avatars
            // If it's one to one chat
            if !self.isGroup! {
                // Update user info
                self.setUIForSingleChat()
            }
        }
    }
    
    func setUIForSingleChat() {
        let withUser = withUsers.first!
        
        // Set the avatar image
        imageFromData(pictureData: withUser.avatar) { (image) in
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        titleLabel.text = withUser.fullname
        
        // Check if it's online and change the subtitle
        if withUser.isOnline {
            subtitleLabel.text = "Online"
        } else{
            subtitleLabel.text = "Offline"
        }
        
        // Add a target, so it will show the user profile when the image is tapped
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    
    
    
    // MARK: UIPickerControllerDelegate
    
    // This functions is called every time we choose a picture or video in the image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Get image and video
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        // Send the message
        sendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        // Dismiss the picker
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: Helpers
    
    func removeBadMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
        // Make a mutable variable with the messages, so we can remove
        var tempMessages = allMessages
        
        for message in tempMessages {
            // Check for the type of message, it should belong to one of the allowed types
            if message[kTYPE] != nil {
                if !self.legitTypes.contains(message[kTYPE] as! String) {
                    // If it doesn't contain, then remove
                    tempMessages.remove(at: tempMessages.index(of: message)!)
                }
            } else {
                // If is nil, also remove the message, something's wrong there
                tempMessages.remove(at: tempMessages.index(of: message)!)
            }
        }
        return tempMessages
    }
    
    func isIncoming(messageDictionary: NSDictionary) -> Bool {
        // If the current Id is equal to the sender then we it's an outgoing message
        if FUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        } else{
            // Else it's an incoming message
            return true
        }
    }
    
    func readTimeFrom(dateString: String) -> String {
        let date = dateFormatter().date(from: dateString)
        
        // Change the format, for the readed status is just necesary the hour and minutes
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:mm"
        
        return currentDateFormat.string(from: date!)
    }
}
