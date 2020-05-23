//
//  ViewController.swift
//  TextReader
//
//  Created by Eric Internicola on 5/23/20.
//  Copyright © 2020 Eric Internicola. All rights reserved.
//

import UIKit
import Vision
import VisionKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
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
    
}
