//
//  ViewController.swift
//  TextReader
//
//  Created by Eric Internicola on 5/23/20.
//  Copyright © 2020 Eric Internicola. All rights reserved.
//

import Cartography
import UIKit
import Vision
import VisionKit

class ViewController: UIViewController {
    
    let textView = UITextView(withText: "Click the scan button to take a photo and read the text from that photo.  The text will appear here.")
    let scanButton = UIButton(withText: "Scan")
    let addPhotoButton = UIButton(withText: "Photo")
    let copyButton = UIButton(withText: "Copy")
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
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
        // Clear any existing text.
        resultingText = ""
        // dismiss the document camera
        controller.dismiss(animated: true)

        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        textRecognitionWorkQueue.async {
            self.resultingText = ""
            for pageIndex in 0 ..< scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                if let cgImage = image.cgImage {
                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    do {
                        try requestHandler.perform(self.requests)
                    } catch {
                        print("failed to recognize text: \(error.localizedDescription)")
                    }
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.handleTextRecognition()
            }
        }
    }
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
        [scanButton, addPhotoButton, copyButton].forEach { $0.setTitleColor(.blue, for: .normal) }
        
        scanButton.addTarget(self, action: #selector(tappedScan(_:)), for: .touchUpInside)
        addPhotoButton.addTarget(self, action: #selector(tappedPhoto(_:)), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(tappedCopy(_:)), for: .touchUpInside)
        
        constrain(view, textView, scanButton, addPhotoButton, copyButton, activityIndicator) { view, textView, scanButton, addPhotoButton, copyButton,  activityIndicator in
            textView.top == view.safeAreaLayoutGuide.top
            textView.left == view.left + 16
            textView.right == view.right - 16
            textView.bottom == copyButton.top - 16
            
            activityIndicator.centerX == view.centerX
            activityIndicator.centerY == view.centerY
            
            copyButton.centerX == view.centerX
            copyButton.bottom == addPhotoButton.top - 16
            
            addPhotoButton.centerX == view.centerX
            addPhotoButton.bottom == scanButton.top - 16
            
            scanButton.centerX == view.centerX
            scanButton.bottom == view.safeAreaLayoutGuide.bottom - 16
        }
        
        textView.delegate = self
    }
}


extension UITextView {
    
    convenience init(withText text: String) {
        self.init(frame: .zero)
        self.text = text
    }
    
}

extension UIButton {
    
    convenience init(withText text: String) {
        self.init(type: .custom)
        setTitle(text, for: .normal)
    }
    
}
