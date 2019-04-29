//
//  WelcomeViewController.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 21/03/2019.
//  Copyright © 2019 Julio C. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: IBActions
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            loginUser()
        } else {
            ProgressHUD.showError("Email and password must be filled")
        }
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" &&
            repeatPasswordTextField.text != "" {
            if passwordTextField.text == repeatPasswordTextField.text {
                registerUser()
            } else {
                ProgressHUD.showError("Passwords don't match")
            }
            
        } else {
            ProgressHUD.showError("All fields are requiered for registering")
        }
    }
    
    @IBAction func backgroundTap(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    // MARK: Helpers
    
    func loginUser() {
        ProgressHUD.show("Login...")
        FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) {
            (error) in
            // Code called when firebase tries to log in the user, first check for errors
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                print("Login Error: " + error!.localizedDescription)
                return
            }
            // If no errors present the app
            self.goToApp()
        }
    }
    
    func registerUser() {
        dismissKeyboard()
        performSegue(withIdentifier: "welcomeToFinishReg", sender: self)
        
        cleanTextFields()
    }
    
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func cleanTextFields() {
        let empty = ""
        emailTextField.text = empty
        passwordTextField.text = empty
        repeatPasswordTextField.text = empty
    }
    
    
    // MARK: GoToApp
    
    func goToApp() {
        ProgressHUD.dismiss()
        
        cleanTextFields()
        dismissKeyboard()
        
        // Notification of user logged in
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        
        // Present the app
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        self.present(mainView, animated: true, completion: nil)
    }
    
    
    // MARK: Navigation
    
    // Before doing the segue, do this
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "welcomeToFinishReg" {
            let vc = segue.destination as! FinishRegistrationViewController
            vc.email = emailTextField.text!
            vc.password = passwordTextField.text!
        }
    }
}
