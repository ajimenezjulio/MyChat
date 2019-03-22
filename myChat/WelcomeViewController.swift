//
//  WelcomeViewController.swift
//  iChat
//
//  Created by Julio Cesar Aguilar Jimenez on 21/03/2019.
//  Copyright © 2019 Julio C. All rights reserved.
//

import UIKit

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
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        dismissKeyboard()
    }
    
    @IBAction func backgroundTap(_ sender: Any) {
        dismissKeyboard()
    }
    
    
    // MARK: HelperFunctions
    
    func dismissKeyboard(){
        self.view.endEditing(false)
    }
    
    func cleanTextFields(){
        let empty = ""
        emailTextField.text = empty
        passwordTextField.text = empty
        repeatPasswordTextField.text = empty
    }
    
}
