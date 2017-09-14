//
//  SGImagePicker.swift
//  SGImagePicker
//
//  Created by Sergey Garazha on 9/6/17.
//  Copyright © 2017 sergeygarazha. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos

public class SGImagePickerViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - IVARS
    
    var callback: ((UIImage?)->())?
    
    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var libraryImageView: UIImageView!

    //MARK: session ivars
    
    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var output: AVCapturePhotoOutput!
    var preview: AVCaptureVideoPreviewLayer!
    
    //MARK: getters
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
        
    }
    
    //MARK: - INIT
    
    public class func picker(callback: @escaping ((UIImage?)->())) -> UIViewController {
        let storyboard = UIStoryboard(name: "Interface", bundle: Bundle(for: self.classForCoder()))
        let vc = storyboard.instantiateViewController(withIdentifier: "SGImagePickerViewController") as! SGImagePickerViewController
        vc.callback = callback
        return NavigationController(rootViewController: vc)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - VIEW CONTROLLER LIFE CYCLE
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        if authorizationStatus() {
            tryToConfig()
            updateLibraryButton()
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
    }
    
    @objc func cancel() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = previewViewContainer.bounds
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tryToConfig()
        updateLibraryButton()
    }
    
    func updateLibraryButton() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1 // This is available in iOS 9.
        
        let fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        if let asset = fetchResult.firstObject {
            let manager = PHImageManager.default()
            
            // If you already know how you want to resize,
            // great, otherwise, use full-size.
            let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            // I arbitrarily chose AspectFit here. AspectFill is
            // also available.
            _ = manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil)
            { image, info in
                self.libraryImageView.image = image
            }
        }
    }
    
    //MARK: - AUTHORIZATION
    
    func authorizationStatus() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }
    
    //MARK: - SUPPORTING
    
    func tryToConfig() {
        do { try configure()
        } catch let er {
            self.showAlert(er)
        }
    }
    
    func showAlert(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }
    
    //MARK: - SESSION CONFIGURATION
    
    func configure() throws {
        guard session == nil else {
            return
        }
        
        guard let backCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first else {
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
    
    func changeCamera() {
        guard let session = self.session else {
            return
        }
        
        session.stopRunning()
        
        session.beginConfiguration()
        
        var position: AVCaptureDevice.Position = .back
        if let i = session.inputs.first as? AVCaptureDeviceInput {
            if i.device.position == .back {
                position = .front
            }
            session.removeInput(i)
        }
        
        if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first, let input = try? AVCaptureDeviceInput(device: device) {
            self.input = input
            session.addInput(input)
            session.commitConfiguration()
            session.startRunning()
        }
    }
    
    //MARK: - IBACTIONS
    
    @IBAction func takePhotoButtonAction(_ sender: Any) {
        makePhoto()
    }
    
    @IBAction func openLibraryButtonAction() {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .photoLibrary
        vc.mediaTypes = [kUTTypeImage as String]
        present(vc, animated: false, completion: nil)
    }
    
    @IBAction func switchFlashButtonAction() {
        changeCamera()
    }
    
    //MARK: - PUBLIC ACTIONS
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true) {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.openEdit(image)
            }
        }
    }
    
    public func makePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(format: nil), delegate: self)
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard let buffer = photoSampleBuffer,
            let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer),
            let image = UIImage(data: data) else {
                return
        }
        
        openEdit(image)
    }
    
    func openEdit(_ image: UIImage) {
        let vc = EditViewController.instance()
        vc.image = image
        vc.callback = self.callback
        present(NavigationController(rootViewController: vc), animated: false, completion: nil)
    }
}
