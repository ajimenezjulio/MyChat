//
//  ChatsViewController.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 26/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import UIKit
import FirebaseFirestore


// The delegate can be done by code as in UsersTableViewController or by storyboard using the connections tab in inspector and by making a connection from "dataSource" and "delegate" to our ViewController (in this case the view controller will be the delegate, not the cell as in UsersTableViewController)

// Conforms protocols of UITableViewDelegate, UITableViewDataSource, RecentChatTableViewCellDelegate, UISearchResultsUpdating
class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentChatTableViewCellDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Array of recent chats
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = []
    
    // Listener for listen to new chats
    var recentListener: ListenerRegistration!
    
    // Our search controller
    let searchController = UISearchController(searchResultsController: nil)
    
    
    
    // MARK: Cycle of ViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Code to change to the new settings style defined by Apple
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Setup for searchController
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        // It notifies when some update is going on
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        // Set the header view and the "New Group" button we need to do it by code, because we need to add it to our tableView
        setTableViewHeader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Load recents and setup listener
        loadRecentChats()
        // Get rid of empty cells
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Remove listener. Important to save battery life, we don't want to check all the time (probably yes in a future)
        recentListener.remove()
    }

    
    
    // MARK: IBActions
    
    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "usersTableView") as! UsersTableViewController
        self.navigationController?.pushViewController(userVC, animated: true)
    }
    
    
    
    // MARK: TableViewDataSource
    
    // If we don't implement the numberOfSectionsInTableView the default is one and that's what we want so we're not implementing it
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If we are using the search bar, just return the filtered results
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChats.count
        } else {
            return recentChats.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecentChatTableViewCell
        
        // Cell setup
        // Make the delegate of the cell to itself
        cell.delegate = self
        
        var recent: NSDictionary!
        
        // Get the right recent depending on if we are using the searchBar or not
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
        } else {
           recent = recentChats[indexPath.row]
        }
        cell.generateCell(recentChat: recent, indexPath: indexPath)
        
        return cell
    }
    
    
    
    // MARK: TableViewDelegateFunctions
    
    // Users can interact with the cells
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var tempRecent: NSDictionary!
        // Get the right recent on which we will perform the actions of mute or delete
        if searchController.isActive && searchController.searchBar.text != "" {
            tempRecent = filteredChats[indexPath.row]
        } else {
            tempRecent = recentChats[indexPath.row]
        }
        
        // Handling mute
        var muteTitle = "Unmute"
        var mute = false
        // Looking for our user in the members to push, if we are there, that means that we are not muted
        if (tempRecent[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()) {
            muteTitle = "Mute"
            mute = true
        }
        
        // Action when user press the delete button
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            // First remove it from our array
            self.recentChats.remove(at: indexPath.row)
            // Now delete it
            deleteRecentChat(recentChatDictionary: tempRecent)
            
            self.tableView.reloadData()
        }
        
        // Action when user press the mute button
        let muteAction = UITableViewRowAction(style: .default, title: muteTitle) { (action, indexPath) in
            print("Mute \(indexPath)")
        }
        muteAction.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        
        return [deleteAction, muteAction]
    }

    // When the user selects the row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // First deselect the row
        tableView.deselectRow(at: indexPath, animated: true)
        
        var recent: NSDictionary!
        // Get the right recent on which we will perform the actions of mute or delete
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
        } else {
            recent = recentChats[indexPath.row]
        }
        
        // Before starting the chat we need to make a validation for whom already delete the recent. For example if I text to Andy and he delete the recent chat, he will not see it, so first we need to check for who has deleted the recent chats and recreate it, the same for the groups.
        
        // Restart the chat
        restartRecentChat(recent: recent)
        
        // Show chat view
        let chatVC = ChatViewController()
        // Hide tabButtonBar
        chatVC.hidesBottomBarWhenPushed = true
        // Pass variables to chatVC
        chatVC.chatRoomId = (recent[kCHATROOMID] as? String)!
        chatVC.memberIds = (recent[kMEMBERS] as? [String])!
        chatVC.membersToPush = (recent[kMEMBERSTOPUSH] as? [String])!
        // If it's a group then true, else false (one to one chat)
        chatVC.isGroup = (recent[kTYPE] as! String) == kGROUP
        // Pass the title of the chat (name of the person to chat or name of the group)
        chatVC.titleName = (recent[kWITHUSERFULLNAME] as? String)!
        
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    
    
    // MARK: LoadRecentChats
    
    // Get all documents belonging to our user
    func loadRecentChats() {
        recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
            // Check for snapshot
            guard let snapshot = snapshot else { return }
            // Clean the array so we will not duplicate every time
            self.recentChats = []
            // Check for NOT emptiness in snapshot
            if !snapshot.isEmpty {
                // We need to sort by date, so the recent one will appear on top, we said "as NSArray" because the sorting function is builded in NSArray. It requires a descriptor (the key for sorting and if it will be ascending or descending)
                let sorted = ( (dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray ).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                
                // Iterating through sorted documents
                for recent in sorted {
                    // Check if the last message is not empty (chatRoomId and recentId is just for checking if it isn't a corrupted file), if everything ok, then add it
                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                        self.recentChats.append(recent)
                    }
                }
                
                self.tableView.reloadData()
            }
        })
    }
    
    
    
    // MARK: CustomTableViewHeader
    
    func setTableViewHeader() {
        // Create view of whole width of table and at the beginning
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        // *** For some reason the tablewView.frame.widht doesn't work on buttonView and lineView so we use self.view.frame.width instead (it suppose that both have the same width) ***
        
        // Create the button. Height 10 point less (margins at top and bottom)
        let buttonView = UIView(frame: CGRect(x: 0, y: 5, width: self.view.frame.width, height: 35))
        let groupButton = UIButton(frame: CGRect(x: self.view.frame.width - 110, y: 10, width: 100, height: 20))
        
        // Setup button
        groupButton.setTitle("New Group", for: .normal)
        // Using "colorLiterral" command to get the box and pick a color
        let buttonColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        groupButton.setTitleColor(buttonColor, for: .normal)
        // Add a target so every time we click the button we add a target
        groupButton.addTarget(self, action: #selector(self.groupButtonPressed), for: .touchUpInside)
        
        // Crate a gray line separator ( height of 1 )
        let lineView = UIView(frame: CGRect(x: 0, y: headerView.frame.height - 1, width: self.view.frame.width, height: 1))
        lineView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        // Assembling
        buttonView.addSubview(groupButton)
        headerView.addSubview(buttonView)
        headerView.addSubview(lineView)
        
        tableView.tableHeaderView = headerView
    }
    
    @objc func groupButtonPressed() {
        print("Button pressed")
    }
    
    
    
    // MARK: RecentChatsCell Delegate
    
    func didTapAvatarImage(indexPath: IndexPath) {
        // Get the recent chat tapped
        var recentChat: NSDictionary!
        if searchController.isActive && searchController.searchBar.text != "" {
            recentChat = filteredChats[indexPath.row]
        } else {
            recentChat = recentChats[indexPath.row]
        }
        
        
        if recentChat[kTYPE] as! String == kPRIVATE {
            // Get the id of the user to whom the recent chat belongs
            reference(.User).document(recentChat[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
                // Validate that snapshot returns something and also that is not empty
                guard let snapshot = snapshot else { return }
                if snapshot.exists {
                    // Create the retrieved user and show it
                    let userDictionary = snapshot.data() as! NSDictionary
                    let tempUser = FUser(_dictionary: userDictionary)
                    
                    self.showUserProfile(user: tempUser)
                }
            }
        }
    }
    
    func showUserProfile(user: FUser) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        
        // Pass the user info to ProfileViewController
        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    
    // MARK: SearchControllerFunctions
    
    // Filter recentChats
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredChats = recentChats.filter({ (recentChat) -> Bool in
            // Lowercase before filtering to make it non-sensitive and return the matches
            return (recentChat[kWITHUSERFULLNAME] as! String).lowercased().contains(searchText.lowercased())
        })
        // Reload tableView
        tableView.reloadData()
    }
    
    // Every time the search is updated, this function is called
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
}
