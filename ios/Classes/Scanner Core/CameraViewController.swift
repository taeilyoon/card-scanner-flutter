//
//  CameraViewController.swift
//  Card Promise Showcase
//
//  Created by Mohammed Sadiq on 26/07/20.
//  Copyright © 2020 MZaink. All rights reserved.
//

import UIKit
import AVFoundation
import MLKitTextRecognition
import MLKitVision

protocol CameraDelegate {
    func camera(_ camera: CameraViewController, didScan scanResult: Text)
    func cameraDidStopScanning(_ camera: CameraViewController)
}

class CameraViewController: UIViewController {



    var scansDroppedSinceLastReset: Int = 0
    
    let textRecognizer = TextRecognizer.textRecognizer()
    
    var cameraDelegate: CameraDelegate?
    var captureSession: AVCaptureSession!
    var device: AVCaptureDevice!
    var input: AVCaptureDeviceInput!
    var prompt: String = ""
    var torchOn: Bool = false
    
    var cameraOrientation: CameraOrientation = .portrait


    public override func viewDidLoad() {
        super.viewDidLoad()
        gainCameraPermission()


    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            let tapCapturingView = UIControl(
                frame: CGRect(
                    x: 0.0,
                    y: 80.0,
                    width: self.view.frame.width,
                    height: self.view.frame.height
                )
            )
            
            tapCapturingView.addTarget(
                self,
                action: #selector(self.captureTap(_:)),
                for: .touchDown
            )
        }

        let label2: UILabel = {
                  let label = UILabel()

                let screenSize: CGRect = UIScreen.main.bounds
                  label.text = "카드를 영역에 맞춰주세요."
                label.textColor = UIColor.white;
                label.translatesAutoresizingMaskIntoConstraints = false;
                label.font = UIFont(name: "Roboto-Bold", size: 18)
                label.textAlignment = .center
                label.widthAnchor.constraint(equalToConstant: screenSize.width).isActive = true
                label.heightAnchor.constraint(equalToConstant: 100).isActive = true
                  return label
              }()
        let label1: UILabel = {

                let screenSize: CGRect = UIScreen.main.bounds
                  let label = UILabel()
                  label.text = "본인 명의의 신용/체크카드 등록가능 합니다"
                label.textColor = UIColor.white;
                label.translatesAutoresizingMaskIntoConstraints = false;
                label.textAlignment = .center
                label.font = UIFont(name: "Roboto-Medium",size: 16)
                label.widthAnchor.constraint(equalToConstant: screenSize.width).isActive = true
                label.heightAnchor.constraint(equalToConstant: 150).isActive = true

                  return label
              }()
     
            
        let button : UIButton = {
            
            let screenSize: CGRect = UIScreen.main.bounds
            let button = UIButton()
            
            button.frame = CGRect(x : 0, y : screenSize.height - 40, width: screenSize.width, height: 40)
            button.backgroundColor = UIColor(red: 0.957, green: 0.318, blue: 0.522, alpha: 1);

            button.setTitle("직접 입력하기", for: .normal);
            button.setTitleColor(.white, for: .normal);
            button.addTarget(
                self,
                action: #selector(selectorBackButton),
                for: .touchUpInside
            )
            return button;
            
        }();
        
        
        self.view.addSubview(self.backgroundView);
        self.view.addSubview(button);
        self.view.addSubview(label2);
        
        self.view.addSubview(label1);
        
    }
    let backgroundView: UIView = {
        
        let screenSize: CGRect = UIScreen.main.bounds
         let v = UIView()
         v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        v.widthAnchor.constraint(equalToConstant: screenSize.width).isActive = true;
        
        v.heightAnchor.constraint(equalToConstant: screenSize.height).isActive = true;
         return v
    }();
    override func viewDidLayoutSubviews() {
    
        let maskLayer = CAShapeLayer()
        maskLayer.frame = backgroundView.bounds
        maskLayer.fillColor = UIColor.black.cgColor

       let screenSize: CGRect = UIScreen.main.bounds
        // Create the path.
        let path = UIBezierPath(rect: backgroundView.bounds)
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd

       let width = screenSize.width;
       
       let height = screenSize.height;
       let leftPadding = CGFloat(20);
       let contentWidth = self.view.frame.width - leftPadding*2;
       let contentHeight = contentWidth*CGFloat(20)/CGFloat(33);

       
        // Append the overlay image to the path so that it is subtracted.
        path.append(UIBezierPath(rect: CGRect(
           x:width/2 - contentWidth/2, y:height/2 - contentHeight/2 , width:contentWidth, height:contentHeight)))
        maskLayer.path = path.cgPath

        
        backgroundView.layer.mask = maskLayer;
    }
    @objc func captureTap(_ sender: UIEvent) {
        refocus()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addAnimatingScanLine()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            stopScanning()
        }
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let safeCaptureDevice = AVCaptureDevice.default(for: .video), let safeCaptureDeviceInput = try? AVCaptureDeviceInput(device: safeCaptureDevice) else {
            return
        }
        
        device = safeCaptureDevice
        input = safeCaptureDeviceInput
        
        refocus()
        
        addInputDeviceToSession()
        
        createAndAddPreviewLayer()
        addOutputToInputDevice()
        addScanControlsAndIndicators()

        startScanning()

        let screenSize: CGRect = UIScreen.main.bounds
        let v = UIView(frame: CGRect(
            origin: CGPoint(
                x: 0,
                y: 0
            ),
            size: CGSize(
                width: screenSize.width,
                height:screenSize.height
            )
        ));
        v.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        view.addSubview(v);
    }
    
    func gainCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCaptureSession()
                }
            }
            
        case .denied, .restricted:
            // The user has previously denied access; or
            // The user can't grant access due to restrictions.
            fallthrough
            
        @unknown default:
            NSLog("Camera Permissions Error")
            dismiss(animated: true, completion: nil)
        }
    }
    
    func addInputDeviceToSession() {
        captureSession.addInput(input)
    }
    
    func createAndAddPreviewLayer() {
        DispatchQueue.main.async {
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            previewLayer.frame = UIScreen.main.bounds
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.isOpaque = true
            self.view.layer.isOpaque = true
            self.view.layer.addSublayer(previewLayer)
              let titleLabel: UILabel = {
                          let label = UILabel()

                        let screenSize: CGRect = UIScreen.main.bounds
                          label.text = "카드를 영역에 맞춰주세요."
                        label.textColor = UIColor.white;
                        label.translatesAutoresizingMaskIntoConstraints = false;
                        label.font = UIFont(name: "Roboto-Bold", size: 18)
                        label.textAlignment = .center
                        label.widthAnchor.constraint(equalToConstant: screenSize.width).isActive = true
                        label.heightAnchor.constraint(equalToConstant: 500).isActive = true
                          return label
                      }()
                    let descriptionLabel: UILabel = {

                        let screenSize: CGRect = UIScreen.main.bounds
                          let label = UILabel()
                          label.text = "본인 명의의 신용/체크카드 등록가능 합니다"
                        label.textColor = UIColor.white;
                        label.translatesAutoresizingMaskIntoConstraints = false;
                        label.textAlignment = .center
                        label.font = UIFont(name: "Roboto-Medium",size: 16)
                        label.widthAnchor.constraint(equalToConstant: screenSize.width).isActive = true
                        label.heightAnchor.constraint(equalToConstant: 550).isActive = true

                          return label
                      }()

                    self.view.addSubview(descriptionLabel);
                    self.view.addSubview(titleLabel);




//                    self.backgroundView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
//                    self.backgroundView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
//                    self.backgroundView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
//                    self.backgroundView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
//
//

        }
    }
    
    func addOutputToInputDevice() {
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Video Queue"))
        captureSession.addOutput(dataOutput)
    }
    
    func refocus() {
        do {
            try device.lockForConfiguration()
            device.focusMode = .autoFocus
        } catch {
            print(error)
        }
    }
    
    func addScanControlsAndIndicators() {
        addCornerClips()
        addScanYourCardToProceedLabel()
        addNavigationBar()
    }
    
    func addCornerClips() {
        DispatchQueue.main.async {
            let cornerClipsView = CornerClipsView()
            cornerClipsView.backgroundColor = .clear
            cornerClipsView.frame = self.view.frame
            self.view.addSubview(cornerClipsView)
        }
    }
    
    
    func addScanYourCardToProceedLabel() {
        DispatchQueue.main.async {
            let center = self.view.center
            let scanYourCardToProceedLabel = UILabel(
                frame: CGRect(
                    origin: CGPoint(
                        x: center.x - 160,
                        y: center.y + 180
                    ),
                    size: CGSize(
                        width: 320,
                        height: 20
                    )
                )
            )
            
            scanYourCardToProceedLabel.textAlignment = NSTextAlignment.center
            scanYourCardToProceedLabel.text = self.prompt
            scanYourCardToProceedLabel.numberOfLines = 0
            scanYourCardToProceedLabel.font = scanYourCardToProceedLabel.font.withSize(12.0)
            scanYourCardToProceedLabel.textColor = .white
            self.view.addSubview(scanYourCardToProceedLabel)
        }
    }
    

    func addUI(){
        DispatchQueue.main.async {
            let center = self.view.center
            let scanYourCardToProceedLabel = UILabel(
                frame: CGRect(
                    origin: CGPoint(
                        x: center.x - 160,
                        y: center.y + 180
                    ),
                    size: CGSize(
                        width: 320,
                        height: 20
                    )
                )
            )
            
            scanYourCardToProceedLabel.textAlignment = NSTextAlignment.center
            scanYourCardToProceedLabel.text = self.prompt
            scanYourCardToProceedLabel.numberOfLines = 0
            scanYourCardToProceedLabel.font = scanYourCardToProceedLabel.font.withSize(12.0)
            scanYourCardToProceedLabel.textColor = .white
            self.view.addSubview(scanYourCardToProceedLabel)
        }
    }
    
    func addNavigationBar() {
        DispatchQueue.main.async {
            self.view.addSubview(self.backButton)
            self.view.addSubview(self.flashButton)
        }
    }
    
    lazy var flashButton: UIButton = {
        let device = AVCaptureDevice.default(for: AVMediaType.video)!
        let flashBtn = UIButton(
            frame: CGRect(
                x: self.view.frame.width - (30 + 17 + 30),
                y: 55,
                width: 17 + 30,
                height: 17 + 10
            )
        )
        
        flashBtn.setImage(
            UIImage(
                named: device.isTorchOn ? "flashOn" : "flashOff"
            ),
            for: .normal
        )
        
        flashBtn.addTarget(
            self,
            action: #selector(selectorFlashLightButton),
            for: .touchUpInside
        )
        
        flashBtn.contentEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: 30.0,
            bottom: 10.0,
            right: 0.0
        )
        
        return flashBtn
    }()
    
    lazy var backButton: UIButton = {
        let backBtn = UIButton(
            frame: CGRect(
                x: 30,
                y: 55,
                width: 17 + 30,
                height: 17 + 10
            )
        )
        
        backBtn.setImage(
            UIImage(
                named: "backButton"
            ),
            for: .normal
        )
        
        backBtn.addTarget(
            self,
            action: #selector(selectorBackButton),
            for: .touchUpInside
        )
        
        backBtn.contentEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: 0.0,
            bottom: 10.0,
            right: 30.0
        )
        
        return backBtn
    }()
    
    @objc func selectorFlashLightButton() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }
        
        DispatchQueue.main.async {
            device.toggleTorch()
            self.flashButton.setImage(
                UIImage(named: device.isTorchOn ? "flashOn" : "flashOff"),
                for: .normal
            )
        }
    }
    
    @objc func selectorBackButton() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func addAnimatingScanLine() {
        
        guard let image = UIImage(named: "blueScanLine", in: Bundle(for: SwiftCardScannerPlugin.self), compatibleWith: nil) else {
            return
        }
        
        let blueScanLineImage = UIImageView(image: image)
        
        var center = view.center
        
        for view in view.subviews {
            if let cornerClips = view as? CornerClipsView {
                center = cornerClips.center
            }
        }
        
        blueScanLineImage.frame = CGRect(origin: CGPoint(x: center.x - 160.0, y: center.y - 95.0), size: CGSize(width: 320.0, height: 30.0))
        
        
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
                blueScanLineImage.frame = CGRect(origin: CGPoint(x: center.x - 160, y:  center.y + 95.0 - 30.0), size: CGSize(width: 320.0, height: 30.0))
            }, completion: nil)
            self.view.addSubview(blueScanLineImage)
        }
    }
    
    public func startScanning() {
        captureSession.startRunning()
    }
    
    public func stopScanning() {
        DispatchQueue.main.async {
            self.device.unlockForConfiguration()
            self.captureSession.stopRunning()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let visionImage = VisionImage(buffer: sampleBuffer)
        
        // .right = portrait mode
        // .up = landscapeRight
        visionImage.orientation = orientationForScanning
        
        guard let result = try? textRecognizer.results(in: visionImage) else {
            #if DEBUG
            NSLog("Text Recognizer", "Something went wrong while setting up TextRecognizer")
            #endif
            return
        }
        
        cameraDelegate?.camera(self, didScan: result)
    }
}

// MARK: - Auxilliary methods
extension CameraViewController {
    func vibrateToIndicateTouch() {
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
    }

    var orientationForScanning: UIImage.Orientation {
        if (cameraOrientation == .landscape) {
            // landscape mode
            return .up
        } else {
            // portrait mode
            return .right
        }
    }
    
    func imageOrientation(
        deviceOrientation: UIDeviceOrientation,
        cameraPosition: AVCaptureDevice.Position
    ) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            return .up
        }
    }
}

class CornerClipsView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let halfWidth: CGFloat = 160.0
        let halfHeight: CGFloat = 95.0
        let startPoint: CGPoint = CGPoint(x: center.x - halfWidth, y: center.y - halfHeight)
        let endPoint: CGPoint = CGPoint(x: center.x + halfWidth, y: center.y + halfHeight)
        
        
        let leftTopCorner: CGPoint = startPoint
        let rightTopCorner: CGPoint = CGPoint(x: endPoint.x, y: startPoint.y)
        let leftBottomCorner: CGPoint = CGPoint(x: startPoint.x, y: endPoint.y)
        let rightBottomCorner: CGPoint = endPoint
        
        guard let ctx  = UIGraphicsGetCurrentContext() else {
            return
        }
        
        ctx.setLineWidth(2.0)
        ctx.setStrokeColor(UIColor.white.cgColor)
        
        ctx.move(to: leftTopCorner)
        ctx.addLine(to: CGPoint(x: leftTopCorner.x + 30, y: leftTopCorner.y))
        ctx.move(to: leftTopCorner)
        ctx.addLine(to: CGPoint(x: leftTopCorner.x, y: leftTopCorner.y + 20))
        
        ctx.move(to: leftBottomCorner)
        ctx.addLine(to: CGPoint(x: leftBottomCorner.x + 30, y: leftBottomCorner.y))
        ctx.move(to: leftBottomCorner)
        ctx.addLine(to: CGPoint(x: leftBottomCorner.x, y: leftBottomCorner.y - 20))
        
        ctx.move(to: rightTopCorner)
        ctx.addLine(to: CGPoint(x: rightTopCorner.x - 30, y: rightTopCorner.y))
        ctx.move(to: rightTopCorner)
        ctx.addLine(to: CGPoint(x: rightTopCorner.x, y: rightTopCorner.y + 20))
        
        ctx.move(to: rightBottomCorner)
        ctx.addLine(to: CGPoint(x: rightBottomCorner.x - 30, y: rightBottomCorner.y))
        ctx.move(to: rightBottomCorner)
        ctx.addLine(to: CGPoint(x: rightBottomCorner.x, y: rightBottomCorner.y - 20))
        
        ctx.strokePath()
    }
}

extension AVCaptureDevice {
    var isLocked: Bool {
        do {
            try lockForConfiguration()
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func toggleTorch() {
        guard hasTorch && isLocked else { return }
        
        defer { unlockForConfiguration() }
        
        if torchMode == .off {
            torchMode = .on
        }  else {
            torchMode = .off
        }
    }
    
    var isTorchOn: Bool {
        return torchMode == .on
    }
}

