//
//  SettingsTableViewController.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 23/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Code to change to the new settings style defined by Apple
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    
    
    // MARK: IBACtions
   
    @IBAction func logOutButtonPressed(_ sender: Any) {
        // Logout locally and from firebase
        FUser.logOutCurrentUser { (success) in
            if success {
                // Show login view
                self.showLoginView()
            }
        }
    }
    
    func showLoginView() {
        // Don't requiere a downcast to View Controller because by default its a ViewController
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcome")
        // Present View Controller
        self.present(mainView, animated: true, completion: nil)
    }
    
}
