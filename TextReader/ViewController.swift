//
//  ViewController.swift
//  TextReader
//
//  Created by Eric Internicola on 5/23/20.
//  Copyright © 2020 Eric Internicola. All rights reserved.
//

import Cartography
import Photos
import PhotosUI
import UIKit
import Vision
import VisionKit

class ViewController: UIViewController {
    
    let textView = UITextView(withText: "Click the scan button to take a photo and read the text from that photo.  The text will appear here.")
    let scanButton = UIButton(withText: "Scan Text")
    let addPhotoButton = UIButton(withText: "Text from Photo")
    let copyButton = UIButton(withText: "Copy Text")
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    let imagePicker = UIImagePickerController()
    
    private var resultingText = ""
    
    private var requests = [VNRequest]()
    // Dispatch queue to perform Vision requests.
    private let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue",
                                                         qos: .userInitiated,
                                                         attributes: [],
                                                         autoreleaseFrequency: .workItem)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVision()
        activityIndicator.hidesWhenStopped = true
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        buildView()
    }

    @IBAction
    func tappedScan(_ source: Any) {
        guard VNDocumentCameraViewController.isSupported else {
            return print("VNDocumentCameraViewController is not supported")
        }
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }
    
    @IBAction
    func tappedPhoto(_ source: Any) {
        selectPhotoFromGallery()
    }
    
    @IBAction
    func tappedCopy(_ source: Any) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = textView.text
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate

extension ViewController: VNDocumentCameraViewControllerDelegate {

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {        
        controller.dismiss(animated: true)
        
        var images = [UIImage]()
        for pageIndex in 0..<scan.pageCount {
            images.append(scan.imageOfPage(at: pageIndex))
        }
        
        readText(from: images)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer {
            dismiss(animated: true, completion: nil)
        }
        
        guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return assertionFailure("no image came back")
        }
        
        readText(from: [pickedImage])
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        print("cancel is clicked")
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UINavigationControllerDelegate

extension ViewController: UINavigationControllerDelegate {
    
}

// MARK: - UITextViewDelegate

extension ViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
    
}

// MARK: - Implementation

private extension ViewController {

    func selectPhotoFromGallery() {
        present(imagePicker, animated: true, completion: nil)
    }

    func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            print("Access is granted by user")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                print("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("success")
                }
            })
            print("It is not determined until now")
        case .restricted:
            // same same
            print("User do not have access to photo album.")
        case .denied:
            // same same
            print("User has denied the permission.")
        @unknown default:
            fatalError()
        }
    }
    
    func readText(from images: [UIImage]) {
        // Clear any existing text.
        resultingText = ""

        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        textRecognitionWorkQueue.async {
            images.forEach { image in
                guard let cgImage = image.cgImage else {
                    return
                }
                do {
                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try requestHandler.perform(self.requests)
                } catch {
                    print("failed to recognize text: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.handleTextRecognition()
            }
        }
    }
    
    func handleTextRecognition() {
        textView.text = resultingText
    }
    
    // Setup Vision request as the request can be reused
    func setupVision() {
        let textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("The observations are of an unexpected type.")
                return
            }
            // Concatenate the recognised text from all the observations.
            let maximumCandidates = 1
            for observation in observations {
                guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                self.resultingText += candidate.string + " "
            }
        }
        // specify the recognition level
        textRecognitionRequest.recognitionLevel = .accurate
        self.requests = [textRecognitionRequest]
    }
    
    func buildView() {
        [textView, scanButton, addPhotoButton, copyButton, activityIndicator].forEach { view.addSubview($0) }
        
        scanButton.addTarget(self, action: #selector(tappedScan(_:)), for: .touchUpInside)
        addPhotoButton.addTarget(self, action: #selector(tappedPhoto(_:)), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(tappedCopy(_:)), for: .touchUpInside)
        
        constrain(view, textView, scanButton, addPhotoButton, copyButton, activityIndicator) { view, textView, scanButton, addPhotoButton, copyButton,  activityIndicator in
            textView.top == view.safeAreaLayoutGuide.top + 16
            textView.left == view.left + 16
            textView.right == view.right - 16
            textView.bottom == copyButton.top - 16
            
            activityIndicator.centerX == view.centerX
            activityIndicator.centerY == view.centerY
            
            copyButton.left == view.left + 16
            copyButton.right == view.right - 16
            copyButton.bottom == addPhotoButton.top - 16
            
            addPhotoButton.left == view.left + 16
            addPhotoButton.right == view.right - 16
            addPhotoButton.bottom == scanButton.top - 16
            
            scanButton.left == view.left + 16
            scanButton.right == view.right - 16
            scanButton.bottom == view.safeAreaLayoutGuide.bottom - 16
        }
        
        textView.delegate = self
    }
}

// MARK: - UITextView(withText:)

extension UITextView {
    
    convenience init(withText text: String, fontSize: CGFloat = 24) {
        self.init(frame: .zero)
        self.text = text
        font = .systemFont(ofSize: fontSize)
        
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 4
    }
    
}

// MARK: - UIButton(withText:)

extension UIButton {
    
    convenience init(withText text: String, titleColor: UIColor = .blue) {
        self.init(type: .custom)
        setTitle(text, for: .normal)
        setTitleColor(titleColor, for: .normal)
        
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        layer.borderColor = titleColor.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 8
    }
    
}
