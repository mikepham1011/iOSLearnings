//
//  ViewController.swift
//  Text Detection Starter Project
//
//  Created by Sai Kambampati on 6/21/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var correctedImageView: UIImageView!
    @IBOutlet weak var corrected1ImageView: UIImageView!
    @IBOutlet weak var resultTextView: UITextView!
    var currentImage: UIImage?
    var currentResult = [VNTextObservation?]()
    var session = AVCaptureSession()
    var requests = [VNRequest]()
    var currentText = String()
    var shouldUpdateResult = true
    let showIndex = 2
//    var classificationRequest: VNCoreMLRequest = {
//        // Load the ML model through its generated class and create a Vision request for it.
//        do {
//            let model = try VNCoreMLModel(for: MNISTClassifier().model)
//            return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
//        } catch {
//            fatalError("can't load Vision ML model: \(error)")
//        }
//    }()
    
    //MARK: - Init Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startLiveVideo()
        startTextDetection()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cameraImageView.layer.sublayers?[0].frame = cameraImageView.bounds
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBAction Methods
    
    @IBAction func captureTextButtonTouchedUpInside(_ sender: UIButton) {
        sender.isEnabled = false
        currentText = ""
        resultTextView.text = currentText
        shouldUpdateResult = false
        
        guard let uiImage = currentImage else {
            print("no image from image picker")
            return
        }
        guard let ciImage = CIImage(image: uiImage) else {
            print("can't create CIImage from UIImage")
            return
        }
        
        let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
        let inputImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))
        let imageSize = inputImage.extent.size
        
        for region in currentResult {
            NSLog("region udid: \((region?.uuid)!) region confidence: \((region?.confidence)!)")
            
            if let boxes = region?.characterBoxes {
                for characterBox in boxes {
                    // Verify detected rectangle is valid.
                    let boundingBox = characterBox.boundingBox.scaled(to: imageSize)
                    guard inputImage.extent.contains(boundingBox)
                        else { print("invalid detected rectangle"); return }
                    
                    // Rectify the detected image and reduce it to inverted grayscale for applying model.
                    let topLeft = characterBox.topLeft.scaled(to: imageSize)
                    let topRight = characterBox.topRight.scaled(to: imageSize)
                    let bottomLeft = characterBox.bottomLeft.scaled(to: imageSize)
                    let bottomRight = characterBox.bottomRight.scaled(to: imageSize)
                    let correctedImage = inputImage
                        .cropped(to: boundingBox)
                        .applyingFilter("CIPerspectiveCorrection", parameters: [
                            "inputTopLeft": CIVector(cgPoint: topLeft),
                            "inputTopRight": CIVector(cgPoint: topRight),
                            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                            "inputBottomRight": CIVector(cgPoint: bottomRight)
                            ])
                        .applyingFilter("CIColorControls", parameters: [
                            kCIInputSaturationKey: 0,
                            kCIInputContrastKey: 32
                            ])
                        .applyingFilter("CIColorInvert", parameters: [:])

                    // Run the Core ML MNIST classifier -- results in handleClassification method
                    let handler = VNImageRequestHandler(ciImage: correctedImage)
                
                    // Show the pre-processed image
                    DispatchQueue.main.async {
                        if boxes.index(of: characterBox) == self.showIndex {
                            self.corrected1ImageView.image = UIImage(ciImage: inputImage
                                .cropped(to: boundingBox)
                                .applyingFilter("CIPerspectiveCorrection", parameters: [
                                    "inputTopLeft": CIVector(cgPoint: topLeft),
                                    "inputTopRight": CIVector(cgPoint: topRight),
                                    "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                                    "inputBottomRight": CIVector(cgPoint: bottomRight)
                                    ]))
                            
                            self.correctedImageView.image = UIImage(ciImage: correctedImage)
                        }
                    }
                    
                    do {
                        let model = try VNCoreMLModel(for: MNISTClassifier().model)
                        let classificationRequest = VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
                        try handler.perform([classificationRequest])
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentText = self.currentText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            self.resultTextView.text = self.currentText
            sender.isEnabled = true
            self.shouldUpdateResult = true
        }
    }
    
    //MARK: - Public Methods
    
    func startLiveVideo() {
        //1
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        //2
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        //3
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = cameraImageView.bounds
        cameraImageView.layer.addSublayer(imageLayer)
        
        session.startRunning()
    }
    
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
    }
    
    func startRectangleTextDetection() {
    }
    
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }
        
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCord = maxX * cameraImageView.frame.size.width
        let yCord = (1 - minY) * cameraImageView.frame.size.height
        let width = (minX - maxX) * cameraImageView.frame.size.width
        let height = (minY - maxY) * cameraImageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        
        cameraImageView.layer.addSublayer(outline)
    }
    
    func highlightLetters(box: VNRectangleObservation) {
        let xCord = box.topLeft.x * cameraImageView.frame.size.width
        let yCord = (1 - box.topLeft.y) * cameraImageView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * cameraImageView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * cameraImageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        cameraImageView.layer.addSublayer(outline)
    }
    
    func getImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) ->UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        guard let cgImage = context.makeImage() else {
            return nil
        }
        let image = UIImage(cgImage: cgImage, scale: 1, orientation:.right)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        return image
    }
    
    //MARK: - Vision Handler Methods
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }
        
        let result = observations.map({$0 as? VNTextObservation})
//        print("detect text result: \(result)")
        if shouldUpdateResult {
            currentResult = result
        }
        
        DispatchQueue.main.async() {
            self.cameraImageView.layer.sublayers?.removeSubrange(1...)
            
            for region in result {
                guard let rg = region else {
                    continue
                }
                self.highlightWord(box: rg)                
//                print("region udid: \((region?.uuid)!) region confidence: \((region?.confidence)!)")
                
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        self.highlightLetters(box: characterBox)
                    }
                }
            }
        }
    }
    
    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation]
            else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let best = observations.first
            else { fatalError("can't get best result") }
        
        DispatchQueue.main.async {
            self.currentText = self.currentText + "\nValue: \"\(best.identifier)\" Confidence: \(String(format:"%.2f",best.confidence*100))%"
        }
    }
}

//MARK: - AVCaptureVideoDataOutputSampleBufferDelegate Methods

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        guard let outputImage = getImageFromSampleBuffer(sampleBuffer: sampleBuffer) else {
            return
        }
        if shouldUpdateResult {
            currentImage = outputImage
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
        
    }
}
