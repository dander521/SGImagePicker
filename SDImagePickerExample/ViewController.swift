//
//  ViewController.swift
//  SDImagePickerExample
//
//  Created by Sergey Garazha on 9/6/17.
//  Copyright © 2017 sergeygarazha. All rights reserved.
//

import UIKit
import SGImagePicker

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showPicker() {
        let picker = SGImagePickerViewController.picker()
        present(picker, animated: true, completion: nil)
    }

}

