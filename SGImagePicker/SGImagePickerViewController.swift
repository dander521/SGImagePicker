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

struct Platform {
    static var isSimulator: Bool {
        #if arch(i386) || arch(x86_64)
            return true
        #else
            return false
        #endif
    }
}

enum CameraAccessStatus {
    case allowed
    case denied
    case notDetermined
}

enum PreviewViewState {
    case accessDenied
    case configurationError(String)
    case preview
    case initial
}

enum LibraryButtonState {
    case error
    case preview(UIImage)
    case initial
}

enum Constants: String {
    case cameraAccessDenied = "Failed to access to your camera. Try to open settings app and change access permissions."
}

public class SGImagePickerViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - IVARS
    
    var callback: ((UIImage?)->())?
    
    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var libraryImageView: UIImageView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryConfigureButton: UIButton!

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
    var camearaStatus: CameraAccessStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .allowed
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        }
    }
    var libraryStatus: CameraAccessStatus {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized: return .allowed
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        }
    }
    
    //MARK: - INIT
    
    public class func picker(callback: @escaping ((UIImage?)->())) -> UIViewController {
        let storyboard = UIStoryboard(name: "Interface", bundle: Bundle(for: self.classForCoder()))
        let vc = storyboard.instantiateViewController(withIdentifier: "SGImagePickerViewController") as! SGImagePickerViewController
        vc.callback = callback
        return NavigationController(rootViewController: vc)
    }
    
    init() {
        fatalError("use SGImagePicker.picker()")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - VIEW CONTROLLER LIFE CYCLE
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        
        if camearaStatus == .notDetermined {
            setPreviewState(.initial)
            setLibraryButtonState(.initial)
        } else {
            updateInterfaceForStatus() 
        }
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
        
        updateInterfaceForStatus()
    }
    
    //MARK: - UI STATES
    
    func updateInterfaceForStatus() {
        switch camearaStatus {
        case .allowed: setPreviewState(.preview)
        case .denied: setPreviewState(.accessDenied)
        case .notDetermined:
            requestAccessToCamera {
                self.updateInterfaceForStatus()
            }
            return
        }
        
        switch libraryStatus {
        case .allowed: updateLibraryButton()
        case .denied: setLibraryButtonState(.error)
        case .notDetermined:
            setLibraryButtonState(.initial)
            requestLibraryAccess {
                DispatchQueue.main.async {
                    self.updateInterfaceForStatus()
                }
            }
        }
    }
    
    //MARK: preview
    
    func setPreviewState(_ state: PreviewViewState) {
        switch state {
        case .initial:
            errorView.isHidden = true
            previewViewContainer.isHidden = false
            retryConfigureButton.isHidden = true
        case .accessDenied:
            errorView.isHidden = false
            errorLabel.text = Constants.cameraAccessDenied.rawValue
            previewViewContainer.isHidden = true
            retryConfigureButton.isHidden = false
        case .configurationError(let er):
            errorView.isHidden = false
            errorLabel.text = er
            previewViewContainer.isHidden = true
            retryConfigureButton.isHidden = false
        case .preview:
            errorView.isHidden = true
            previewViewContainer.isHidden = false
            retryConfigureButton.isHidden = true
            if session == nil || session!.isRunning == false {
                do {
                    try configure()
                } catch let er {
                    self.setPreviewState(.configurationError(er.localizedDescription))
                }
            }
        }
    }
    
    //MARK: library button
    
    func setLibraryButtonState(_ state: LibraryButtonState) {
        switch state {
        case .initial:
            libraryImageView.backgroundColor = UIColor.lightGray
            libraryImageView.image = nil
        case .error:
            libraryImageView.backgroundColor = UIColor.clear
            libraryImageView.image = #imageLiteral(resourceName: "error")
        case .preview(let image):
            libraryImageView.backgroundColor = UIColor.clear
            libraryImageView.image = image
        }
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
                DispatchQueue.main.async {
                    if let image = image {
                        self.setLibraryButtonState(.preview(image))
                    } else {
                        self.setLibraryButtonState(.error)
                    }
                }
            }
        }
    }
    
    //MARK: - ACCESS
    
    func requestLibraryAccess(callback: @escaping ()->()) {
        PHPhotoLibrary.requestAuthorization { (_) in
            DispatchQueue.main.async {
                callback()
            }
        }
    }
    
    func requestAccessToCamera(callback: @escaping ()->()) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                DispatchQueue.main.async {
                    callback()
                }
            }
        } else {
            callback()
        }
    }
    
    //MARK: - CAMERA SESSION
    
    func configure() throws {
        if Platform.isSimulator {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Camera doesn't work in simulator"])
            throw error
        }
        
        guard let backCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Camera not found."])
            throw error
        }
        
        input = try AVCaptureDeviceInput(device: backCamera)

        session = AVCaptureSession()
        session.addInput(input)
        
        output = AVCapturePhotoOutput()
        session.addOutput(output)
        
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = previewViewContainer.bounds
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
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard let buffer = photoSampleBuffer,
            let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer),
            let image = UIImage(data: data) else {
                return
        }
        
        openEdit(image)
    }
    
    //MARK: - IBACTIONS
    
    @IBAction func retryConfigure() {
        updateInterfaceForStatus()
    }
    
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
    
    //MARK: ACTIONS
    
    func openEdit(_ image: UIImage) {
        let vc = EditViewController.instance()
        vc.image = image
        vc.callback = self.callback
        present(NavigationController(rootViewController: vc), animated: false, completion: nil)
    }
    
    //MARK: - PUBLIC ACTIONS
    
    public func makePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(format: nil), delegate: self)
    }
    
    //MARK: IMAGE PICKER CONTROLLER
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true) {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.openEdit(image)
            }
        }
    }
}
