//
//  EditViewController.swift
//  SGImagePicker
//
//  Created by Sergey Garazha on 9/6/17.
//  Copyright © 2017 sergeygarazha. All rights reserved.
//

import UIKit

class EditViewController: UIViewController {
    
    var image: UIImage!
    var callback: ((UIImage?)->())?
    
    @IBOutlet weak var imageView: UIImageView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    class func instance() -> EditViewController {
        let bundle = Bundle(for: self.classForCoder())
        let storyboard = UIStoryboard(name: "Interface", bundle: bundle)
        return storyboard.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = image
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBack))
    }
    
    @objc func goBack() {
        navigationController?.presentingViewController?.dismiss(animated: false, completion: nil)
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        callback?(image)
    }

}
