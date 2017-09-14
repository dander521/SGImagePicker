//
//  SupportingClasses.swift
//  SGImagePicker
//
//  Created by Sergey Garazha on 9/6/17.
//  Copyright © 2017 sergeygarazha. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {return topViewController?.supportedInterfaceOrientations ?? .portrait}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.barTintColor = UIColor(red: 13/255, green: 13/255, blue: 13/255, alpha: 1)
        navigationBar.tintColor = .white
    }
    
    override var prefersStatusBarHidden: Bool {return false}
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
