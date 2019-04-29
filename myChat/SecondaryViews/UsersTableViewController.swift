//
//  UsersTableViewController.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 23/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

// For searchs we need to also implement the UISearchResultsUpdating protocol
// For being notified when the avatarImage is pressed we need to use our custome delegate UserTableViewCellDelegate previously created on UserTableViewCell file
class UsersTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var filterSegmentedController: UISegmentedControl!
    
    // Variables for save users downloaded from firebase
    var allUsers: [FUser] = []
    var filteredUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    
    // Search bar
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // As it is a TableViewController, we need to create the title manually (can't be done in storyboard)
        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        
        // Get rid of empty cells at the footer, just show empty space
        tableView.tableFooterView = UIView()
        
        // Show the searchController
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        // We need to see also the background
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        loadUsers(filter: kCITY)
    }
    

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // If we are searching we just need one section, else show the sections based on the alphabetic letter
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return allUsersGrouped.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If we are searching just show the number of filtered results, else show all users per every section
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUsers.count
         } else {
            // Find section title
            let sectionTitle = self.sectionTitleList[section]
            // Users per given section
            let users = self.allUsersGrouped[sectionTitle]
            
            return users!.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Downcasting as our custom UserTableViewCell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        var user: FUser
        // If we are searching, return the filtered user
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            // Find section title
            let sectionTitle = self.sectionTitleList[indexPath.section]
            // Users per given section
            let users = self.allUsersGrouped[sectionTitle]
            // Get user in the actual indexPath
            user = users![indexPath.row]
        }
        
        // Configure the cell
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        // The cell has to be delegate to itself (the protocol was created ond UserTableViewCell)
        cell.delegate = self
        
        return cell
    }
    
    
    
    // MARK: TableView Delegate
    
    // Delegate that will add the section names
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // If we are searching, then there is no section title
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            // Return the section
            return sectionTitleList[section]
        }
    }
    
    // Delegate for return the index in the right side of the screen
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        // If we are searching, there is no section so also no index
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return sectionTitleList
        }
    }
    
    // Delegate that will jump to the section when clicked in the index
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    // Start a chat when the cell is clicked
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Don't select the row
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the right user
        var user: FUser
        // If we are searching, return the filtered user
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            // Find section title
            let sectionTitle = self.sectionTitleList[indexPath.section]
            // Users per given section
            let users = self.allUsersGrouped[sectionTitle]
            // Get user in the actual indexPath
            user = users![indexPath.row]
        }
        // Start the chat
        startPrivateChat(user1: FUser.currentUser()!, user2: user)
    }
    
    
    
    // MARK: LoadUsers
    
    // Load users based on the selected type
    func loadUsers(filter: String) {
        ProgressHUD.show()
        // We will have 3 different kinds of query (My City, My Country, All)
        var query: Query!
        
        switch filter {
        case kCITY:
            // Query for users in the same city that our user
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            // Query for users in the same country that our user
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
        default:
            // Query for getting all users
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        // Run the query
        query.getDocuments { (snapshot, error) in
            // First clear the current array of users, sections and groups, if not it will add the new users to the past ones
            self.allUsers = []
            self.sectionTitleList = []
            self.allUsersGrouped = [:]
            
            // If there's an error, print it
            if error != nil {
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            
            // If no error check for the snapshot
            guard let snapshot = snapshot else {
                ProgressHUD.dismiss()
                return
            }
            
            // If everything ok, present into the tableView
            if !snapshot.isEmpty {
                for userDictionary in snapshot.documents {
                    // Get info for every user
                    let userDictionary = userDictionary.data() as NSDictionary
                    // Create the user
                    let fUser = FUser.init(_dictionary: userDictionary)
                    // If the retrieved user is equal to our actual user, don't append it (we don't want to chat to ourselves)
                    if fUser.objectId != FUser.currentId() {
                        self.allUsers.append(fUser)
                    }
                }
                
                // Split to groups
                self.splitDataIntoSections()
                self.tableView.reloadData()
            }
            // Refresh data in the table
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }
    
    
    
    // MARK: IBActions
    
    @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {
        // Get the index of the selected segment and load the users
        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: kCOUNTRY)
        case 2:
            loadUsers(filter: "")
        default:
            return
        }
    }
    
    
    
    // MARK: SearchControllerFunctions
    
    // Filter users
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredUsers = allUsers.filter({ (user) -> Bool in
            // Lowercase before filtering to make it non-sensitive and return the matches
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        // Reload tableView
        tableView.reloadData()
    }
    
    // Every time the search is updated, this function is called
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    
    
    // MARK: Helpers
    
    // Private function, only can be used by this class
    fileprivate func splitDataIntoSections() {
        var sectionTitle: String = ""
        
        // Iterate to every user
        for i in 0 ..< self.allUsers.count {
            let currentUser = self.allUsers[i]
            // Get first character
            let firstCharacter = currentUser.firstname.first!
            let firstCharString = "\(firstCharacter)"
            
            // Check if the section for this character is already created (so we won't create any section duplicate)
            if firstCharString != sectionTitle {
                // Create section
                sectionTitle = firstCharString
                self.allUsersGrouped[sectionTitle] = []
                self.sectionTitleList.append(sectionTitle)
            }
            // Append the current user to the section
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
    }
    
    
    
    // MARK: UserTableViewCellDelegate
    func didTapAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        
        // Pass the user to the profileVC
        var user: FUser
        // If we are searching then use the filteredUsers, else allUsers
        if searchController.isActive && searchController.searchBar.text != "" {
            user = self.filteredUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        
        // Fill the user info in the profileVC
        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)
        
    }
}
