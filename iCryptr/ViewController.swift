//
//  ViewController.swift
//  iCryptr
//
//  Created by Brendan Lindsey on 5/21/22.
//

import UIKit

class ViewController: UIViewController  {
    @IBOutlet weak var EncryptPhotoButton: UIButton!
    @IBOutlet weak var EncryptFileButton: UIButton!
    @IBOutlet weak var DecryptButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func EncryptPhotoTouchUpInside(_ sender: Any) {
        print("Touched Encrypt Photo")
    }
    @IBAction func EncryptFileTouchUpInside(_ sender: Any) {
        print("Touched Encrpyt File")
    }
    @IBAction func DecryptTouchUpInside(_ sender: Any) {
        print("Touched Decrypt")
    }
}

