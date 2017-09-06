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
}
