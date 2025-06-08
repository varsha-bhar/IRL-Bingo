//
//  SignUpViewController.swift
//  IRL Bingo
//
//  Created by Amrith Gandham on 6/6/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    let db = Firestore.firestore()
    let defaultPassword = "letmein123"

    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.text = ""
    }

    @IBAction func createAccountTapped(_ sender: UIButton) {
        guard let username = usernameField.text?.lowercased(), !username.isEmpty else {
            errorLabel.text = "Please enter a username"
            return
        }

        let email = "\(username)@irlbingo.com"

        // Check for duplicate usernames
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                self.errorLabel.text = "Error: \(error.localizedDescription)"
                return
            }

            if let docs = snapshot?.documents, !docs.isEmpty {
                self.errorLabel.text = "Username already taken."
                return
            }

            // Create account using default password
            Auth.auth().createUser(withEmail: email, password: self.defaultPassword) { result, error in
                if let error = error {
                    self.errorLabel.text = "Signup failed: \(error.localizedDescription)"
                    return
                }

                guard let uid = result?.user.uid else {
                    self.errorLabel.text = "Signup failed: No user ID"
                    return
                }

                self.db.collection("users").document(uid).setData([
                    "username": username,
                    "email": email
                ]) { error in
                    if let error = error {
                        self.errorLabel.text = "Error saving user: \(error.localizedDescription)"
                    } else {
                        self.errorLabel.text = ""
                        self.performSegue(withIdentifier: "toHomeFromCreate", sender: self)
                    }
                }
            }
        }
    }
}
