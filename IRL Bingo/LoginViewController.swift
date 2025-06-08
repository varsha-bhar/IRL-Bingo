//
//  LoginViewController.swift
//  IRL Bingo
//
//  Created by Amrith Gandham on 6/6/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    let db = Firestore.firestore()
    let defaultPassword = "letmein123"

    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.text = ""
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        guard let username = usernameField.text?.lowercased(), !username.isEmpty else {
            errorLabel.text = "Please enter a username"
            return
        }

        // Check if username exists in Firestore
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                self.errorLabel.text = "Error: \(error.localizedDescription)"
                return
            }

            guard let doc = snapshot?.documents.first,
                  let email = doc.data()["email"] as? String else {
                self.errorLabel.text = "Username not found. Please sign up."
                return
            }

            // Log in with Firebase using default password
            Auth.auth().signIn(withEmail: email, password: self.defaultPassword) { result, error in
                if let error = error {
                    self.errorLabel.text = "Login failed: \(error.localizedDescription)"
                } else {
                    self.errorLabel.text = ""
                    self.performSegue(withIdentifier: "toHomeFromLogin", sender: self)
                }
            }
        }
    }

    @IBAction func signUpTapped(_ sender: UIButton) {
        // Navigate to signup screen
        self.performSegue(withIdentifier: "toCreateFromSignUp", sender: self)
    }
}

