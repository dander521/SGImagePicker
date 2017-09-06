//
//  SGImagePicker.swift
//  SGImagePicker
//
//  Created by Sergey Garazha on 9/6/17.
//  Copyright © 2017 sergeygarazha. All rights reserved.
//

import UIKit
import AVFoundation

public class SGImagePickerViewController: UIViewController {
    
    @IBOutlet weak var previewViewContainer: UIView!

    public class func picker() -> UIViewController {
        let storyboard = UIStoryboard(name: "Interface", bundle: Bundle(for: self.classForCoder()))
        let vc = storyboard.instantiateViewController(withIdentifier: "SGImagePickerViewController") as! SGImagePickerViewController
        return UINavigationController(rootViewController: vc)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        if authorizationStatus() {
            do { try configure()
            } catch let er {
                self.showAlert(er)
            }
        }
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = previewViewContainer.bounds
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do { try configure()
        } catch let er {
            self.showAlert(er)
        }
    }
    
    func askAuthorization() {
        
    }
    
    func authorizationStatus() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }
    
    func showAlert(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }

    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var output: AVCapturePhotoOutput!
    var preview: AVCaptureVideoPreviewLayer!
    
    func configure() throws {
        
        guard session == nil else {
            return
        }
        
        guard let backCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back).devices.first else {
            //TODO: drop exception
            return
        }
        
        session = AVCaptureSession()
        
        input = try AVCaptureDeviceInput(device: backCamera)
        session.addInput(input)
        
        output = AVCapturePhotoOutput()
        session.addOutput(output)
        
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        previewViewContainer.layer.addSublayer(preview)
        
        session.startRunning()
    }

}
