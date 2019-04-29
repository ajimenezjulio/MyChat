//
//  FinishRegistrationViewController.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 22/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import UIKit
import ProgressHUD

class FinishRegistrationViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var surnameTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    // Variables to pass the user credentials from previous view controller
    var email: String!
    var password: String!
    // Optional, the user can or cannot use an avatar image
    var avatarImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        cleanTextFields()
        dismissKeyboard()
        
        // Return to previous view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        ProgressHUD.show("Registering...")
        
        if nameTextField.text != "" && surnameTextField.text != "" && countryTextField.text != "" &&
            cityTextField.text != "" && phoneTextField.text != "" {
            // Register the user
            FUser.registerUserWith(email: email!, password: password!, firstName: nameTextField.text!, lastName: surnameTextField.text!) { (error) in
                // If some error arises
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error!.localizedDescription)
                    print("Registration Error: " + error!.localizedDescription)
                    return
                }
                // If everything ok
                self.registerUser()
            }
        } else {
            ProgressHUD.showError("All fields are required")
        }
    }
    
    
    // MARK: Helpers
    
    func registerUser() {
        let fullName = nameTextField.text! + " " + surnameTextField.text!
        
        var tempDictionary: Dictionary = [kFIRSTNAME: nameTextField.text!,
                                          kLASTNAME: surnameTextField.text!,
                                          kFULLNAME: fullName,
                                          kCOUNTRY: countryTextField.text!,
                                          kCITY: cityTextField.text!,
                                          kPHONE: phoneTextField.text!
                                        ] as [String: Any]
        if avatarImage == nil {
            imageFromInitials(firstName: nameTextField.text!, lastName: surnameTextField.text!) { (avatarInitials) in
                
                // Convert UIImage into Data object
                let avatarIMG = avatarInitials.jpegData(compressionQuality: 0.7)
                // Convert Data object to string
                let avatar = avatarIMG!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                // Save into the dictionary
                tempDictionary[kAVATAR] = avatar
                
                // Finish registration
                self.finishRegistration(withValues: tempDictionary)
            }
        } else {
            // Convert avatar image into Data object
            let avatarData = avatarImage?.jpegData(compressionQuality: 0.7)
            // Convert Data object to string
            let avatar = avatarData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            // Save into the dictionary
            tempDictionary[kAVATAR] = avatar
            
            // Finish registration
            self.finishRegistration(withValues: tempDictionary)
        }
    }
    
    func finishRegistration(withValues: [String: Any]) {
        updateCurrentUserInFirestore(withValues: withValues) { (error) in
            if error != nil {
                // This is happening in background thread, we need to go to the main queue
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                }
                return
            }
            ProgressHUD.dismiss()
            
            // If no error, go to app
            self.goToApp()
        }
    }
    
    func goToApp() {
        cleanTextFields()
        dismissKeyboard()
        
        // Notification of user logged in
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        
        // Present the app
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        self.present(mainView, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func cleanTextFields() {
        let empty = ""
        nameTextField.text = empty
        surnameTextField.text = empty
        countryTextField.text = empty
        cityTextField.text = empty
        phoneTextField.text = empty
    }
    
}
