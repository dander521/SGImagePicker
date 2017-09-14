//
//  ViewController.swift
//  SGImagePickerExample
//
//  Created by Sergey Garazha on 9/6/17.
//  Copyright © 2017 sergeygarazha. All rights reserved.
//

import UIKit
import SGImagePicker

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let vc = presentedViewController {
            return vc.preferredStatusBarStyle
        } else {
            return .default
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showPicker() {
        let picker = SGImagePickerViewController.picker() { image in
            self.imageView.image = image
            self.dismiss(animated: true, completion: {
                
            })
        }
        present(picker, animated: true, completion: nil)
    }

}
