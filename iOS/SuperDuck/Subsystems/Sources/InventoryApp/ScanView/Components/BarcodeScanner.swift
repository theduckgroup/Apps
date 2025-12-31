import Foundation
import SwiftUI
@preconcurrency import AVFoundation
import Vision
import UIKit
import AudioToolbox
import Combine
import os
import Common

/// A full-screen view that displays camera video with a cutout overlay. The detected barcodes are highlighted in yellow.
struct BarcodeScanner: View {
    /// Minimum time the barcode needs to be present to be considered.
    var minPresenceTime: TimeInterval
    
    /// Minimum time a barcode needs to be absent to be considered again.
    ///
    /// This value is needed because sometimes Vision takes a long time before recognizing a code
    /// again despite the code staying in camera feed (likely on slow devices). Make sure this is
    /// not too small.
    var minAbsenceTime: TimeInterval
    
    /// If detection is enabled.
    var detectionEnabled: Bool
    
    /// Barcodes detected within camera view.
    @Binding var detectedBarcodes: [String]
    
    /// A closure called when a barcode is within camera view and has been (persistently) visible
    /// for a minimum duration. This only triggers if there is exactly one barcode.
    var persistentBarcodeHandler: (String) -> Void
    
    var body: some View {
        BarcodeScannerViewControllerRepresentable(
            minPresenceTime: minPresenceTime,
            minAbsenceTime: minAbsenceTime,
            detectionEnabled: detectionEnabled,
            detectionHandler: { barcodes in
                self.detectedBarcodes = barcodes
            },
            persistenceHandler: { barcodes in
                if barcodes.count == 1 {
                    persistentBarcodeHandler(barcodes[0])
                }
            }
        )
        .ignoresSafeArea()
    }
}

extension BarcodeScanner {
    static let defaultMinPresenceTime: TimeInterval = 0.250
    static let defaultMinAbsenceTime: TimeInterval = 0.500
}

private struct BarcodeScannerViewControllerRepresentable: UIViewControllerRepresentable {
    var minPresenceTime: TimeInterval
    var minAbsenceTime: TimeInterval
    var detectionEnabled: Bool
    var detectionHandler: ([String]) -> Void
    var persistenceHandler: ([String]) -> Void
    
    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        BarcodeScannerViewController()
    }
    
    func updateUIViewController(_ vc: BarcodeScannerViewController, context: Context) {
        print("! Update barcode scanner | Min presence time = \(minPresenceTime) | Min absence time = \(minAbsenceTime)")
        vc.minPresenceTime = minPresenceTime
        vc.minAbsenceTime = minAbsenceTime
        vc.detectionEnabled = detectionEnabled
        vc.detectionHandler = detectionHandler
        vc.persistenceHandler = persistenceHandler
    }
}

private class BarcodeScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var minPresenceTime: TimeInterval = 0
    var minAbsenceTime: TimeInterval = 0
    var detectionHandler: ([String]) -> Void = { _ in }
    var persistenceHandler: ([String]) -> Void = { _ in }
    var detectionEnabled = true
    nonisolated(unsafe) private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var cutoutLayer: CAShapeLayer!
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var detectTask: Task<Void, Never>?
    private var detectionEvents: [DetectionEvent] = []
    private var persistenceEvents: [PersistenceEvent] = []
    private var barcodeRectShapes: [CAShapeLayer] = []
    private var barcodeBBoxShapes: [CAShapeLayer] = []
    private var barcodeRects: [BarcodeRect] = [] {
        didSet {
            barcodeRectsChanged()
        }
    }
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isRunningForPreviews {
            view.backgroundColor = .black.withAlphaComponent(0.5)
            cutoutLayer = CAShapeLayer()
            view.layer.addSublayer(cutoutLayer)
            return
        }
        
        // Capture session
        
        captureSession.beginConfiguration()
        
        if captureSession.isMultitaskingCameraAccessSupported {
            // In here if device is an iPad that supports Stage Manager
            // Enable camera in iPad split view
            captureSession.isMultitaskingCameraAccessEnabled = true
        }
        
        captureSession.commitConfiguration()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: captureDevice),
              captureSession.canAddInput(input) else {
            assertionFailure()
            return
        }
        
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        
        if captureSession.canAddOutput(output) {
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(output)
        }
        
        // Preview layer
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Rotation coordinator
        
        rotationCoordinator = .init(device: captureDevice, previewLayer: previewLayer)
        
        rotationCoordinator.publisher(for: \.videoRotationAngleForHorizonLevelPreview)
            .sink { [weak previewLayer] value in
                previewLayer?.connection!.videoRotationAngle = value
            }
            .store(in: &cancellables)
        
        // Cutout layer; must be above preview layer
        
        cutoutLayer = CAShapeLayer()
        view.layer.addSublayer(cutoutLayer)
        
        // Start
        
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
    deinit {
        print("\(Self.self) deinit")
        
        let captureSession = captureSession
        
        DispatchQueue.global().async {
            captureSession.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Preview layer is nil in preview
        
        previewLayer?.frame = view.bounds
        cutoutLayer.frame = view.bounds
        invalidateCutoutLayer()
    }
    
    private func invalidateCutoutLayer() {
        cutoutLayer.fillRule = .evenOdd
        cutoutLayer.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
        
        let path = UIBezierPath(rect: cutoutLayer.bounds)
        path.append(UIBezierPath(rect: rectOfInterest()))
        cutoutLayer.path = path.cgPath
    }
   
    /// Called by AVCaptureSesion.
    ///
    /// Must be nonisolated, otherwise will cause crash due to main actor assertion. This is because
    /// this method will be called by AVCaptureSesion on a background thread.
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // CVImageBufferGetDisplaySize(pixelBuffer)
        
        nonisolated(unsafe) let pixelBuffer2 = pixelBuffer
        
        Task { @MainActor in
            handleCapturedOutput(pixelBuffer2)
        }
    }
    
    private func handleCapturedOutput(_ pixelBuffer: CVPixelBuffer) {
        guard detectionEnabled else {
            barcodeRects.removeAll()
            return
        }
        
        guard detectTask == nil else {
            // print("detectTask already running, skip buffer")
            return
        }
        
        detectTask = Task { @MainActor in
            // print("Detecting barcode")
            let vnObservations = await detectTaskImpl1(pixelBuffer)
            detectTaskImpl2(vnObservations)
            
            detectTask = nil
        }
    }
    
    /// Runs VN recognition.
    @concurrent private func detectTaskImpl1(_ pixelBuffer: CVPixelBuffer) async -> [VNBarcodeObservation] {
        let vnRequest = VNDetectBarcodesRequest()
        // vnRequest.symbologies = [.qr]
        // request.regionOfInterest = .init(x: 0, y: 0.4, width: 1, height: 0.3)
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let vnRequestSendable = UnsafeSendable(vnRequest)
        let handlerSendable = UnsafeSendable(handler)
        
        do {
            try handlerSendable.value.perform([vnRequestSendable.value])
            
            // try await perform()
            
            if vnRequest.results?.count ?? 0 > 0 {
                // print("Detection took \(Date().timeIntervalSince(t0))")
            }
            
        } catch {
            logger.error("VNImageRequestHandler failed: \(error)")
            return []
        }
        
        return vnRequest.results ?? []
    }
    
    /// Processes VN recognition result.
    @MainActor private func detectTaskImpl2(_ vnObservations: [VNBarcodeObservation]) {
        // print("[\(Date().ISO8601Format())] Detected: \(vnResults.map { $0.payloadStringValue ?? "<unknown>"})")
        
        struct BarcodeWithRect {
            let barcode: String
            let topLeft: CGPoint
            let topRight: CGPoint
            let bottomRight: CGPoint
            let bottomLeft: CGPoint
            let boundingBox: CGRect
        }
        
        var barcodesWithRect = vnObservations.compactMap { vnResult in
            // Transform for flipping y coordinate
            // Don't know why I have to do this; learnt from experiments
            
            let transform = CGAffineTransform.identity
                .scaledBy(x: 1, y: -1)
                .translatedBy(x: 0, y: -1)
            
            @MainActor
            func toPreviewLayerPoint(_ captureDevicePoint: CGPoint) -> CGPoint {
                let p = captureDevicePoint.applying(transform)
                return previewLayer.layerPointConverted(fromCaptureDevicePoint: p)
            }
            
            @MainActor
            func toPreviewLayerRect(_ captureDeviceRect: CGRect) -> CGRect {
                let r = captureDeviceRect.applying(transform)
                return previewLayer.layerRectConverted(fromMetadataOutputRect: r)
            }
            
            return BarcodeWithRect(
                barcode: vnResult.payloadStringValue ?? "???",
                topLeft: toPreviewLayerPoint(vnResult.topLeft),
                topRight: toPreviewLayerPoint(vnResult.topRight),
                bottomRight: toPreviewLayerPoint(vnResult.bottomRight),
                bottomLeft: toPreviewLayerPoint(vnResult.bottomLeft),
                boundingBox: toPreviewLayerRect(vnResult.boundingBox)
            )
        }
        
        barcodesWithRect = barcodesWithRect.filter {
            let roi = rectOfInterest()
            return [$0.topLeft, $0.topRight, $0.bottomRight, $0.bottomLeft].allSatisfy(roi.contains)
        }
        
        let barcodes = barcodesWithRect.map(\.barcode)
        
        // Update barcode rects
        
        self.barcodeRects = barcodesWithRect.map {
            .init(topLeft: $0.topLeft, topRight: $0.topRight, bottomRight: $0.bottomRight, bottomLeft: $0.bottomLeft, boundingBox: $0.boundingBox)
        }
        
        // Detection handler
                
        detectionHandler(barcodes)
        
        // Detection event
        
        detectionEvents.append(.init(time: Date(), barcodes: Set(barcodes)))
        detectionEventAdded()
    }
    
    private func rectOfInterest() -> CGRect {
        let bounds = view.bounds
        let safeInsets = view.safeAreaInsets
        let padding: CGFloat = 16

        // Calculate available space respecting safe area and padding
        let availableTop = safeInsets.top + padding
        let availableLeft = safeInsets.left + padding
        let availableRight = safeInsets.right + padding
        let availableBottom = safeInsets.bottom + padding

        let availableWidth = bounds.width - availableLeft - availableRight
        let availableHeight = bounds.height - availableTop - availableBottom

        // Rectangle takes up half of available height, full width
        let rectHeight = availableHeight / 2

        let rect = CGRect(
            x: availableLeft,
            y: availableTop,
            width: availableWidth,
            height: rectHeight
        )

        return rect
        
        /*
         // Old center logic
         // let (width, height) = (previewLayer.bounds.width, previewLayer.bounds.height)
         let (width, height) = (view.bounds.width, view.bounds.height)
         
         var rect = if width < height {
             CGRect(
                 x: 0,
                 y: (height - width) / 2,
                 width: width,
                 height: width
             )
             
         } else {
             CGRect(
                 x: (width - height) / 2,
                 y: 0,
                 width: height,
                 height: height
             )
         }
         
         if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
             rect = rect.insetBy(dx: 48, dy: 48)
         }
        */
    }
    
    private func barcodeRectsChanged() {
        // It is one barcode most of the time
        // Animation only applies to 1 barcode
        
        if barcodeRectShapes.count != barcodeRects.count || barcodeRects.count > 1 {
            barcodeRectShapes.forEach {
                $0.removeFromSuperlayer()
            }
            
            barcodeRectShapes = barcodeRects.indices.map { _ in
                let layer = CAShapeLayer()
                layer.isOpaque = false
                layer.fillColor = UIColor.yellow.withAlphaComponent(0.5).cgColor
                layer.strokeColor = UIColor.yellow.cgColor
                layer.lineWidth = 2
                view.layer.addSublayer(layer)
                return layer
            }
        }
        
        for (index, rect) in barcodeRects.enumerated() {
            let layer = barcodeRectShapes[index]
            
            let path = UIBezierPath()
            path.move(to: rect.topLeft)
            path.addLine(to: rect.topRight)
            path.addLine(to: rect.bottomRight)
            path.addLine(to: rect.bottomLeft)
            path.close()
            
            let anim = CABasicAnimation(keyPath: "path")
            anim.duration = 0.15
            anim.fromValue = layer.path
            anim.timingFunction = CAMediaTimingFunction(name: .linear)
            anim.toValue = path.cgPath
            layer.add(anim, forKey: "path")
            
            layer.path = path.cgPath
        }
        
        /*
         barcodeBBoxShapes.forEach {
         $0.removeFromSuperlayer()
         }
         
         for rect in barcodeRects {
         let layer = CAShapeLayer()
         layer.path = UIBezierPath(rect: rect.boundingBox).cgPath
         layer.fillColor = UIColor.blue.withAlphaComponent(0.5).cgColor
         view.layer.addSublayer(layer)
         barcodeBBoxShapes.append(layer)
         }
         */
    }
    
    private func detectionEventAdded() {
        let barcodes = detectionEvents.last!.barcodes
        
        let minTime = barcodes.isEmpty ? minAbsenceTime : minPresenceTime
        let lastDetectionEventTime = detectionEvents.last!.time
        
        detectionEvents.removeAll { event in
            // Don't remove the most recent event, otherwise we'll mess up future detections
            // (This is needed when minPresenceTime is 0)
            event.time != lastDetectionEventTime &&
            event.time < Date().addingTimeInterval(-minTime)
        }
        
        //        let df = DateFormatter()
        //        df.dateFormat = "HH:mm:ss.SSS"
        //
        //        print("""
        //
        //        Detection events:
        //        \(detectionEvents.map { "\(df.string(from: $0.time)) -> \($0.barcodes.count)" }.joined(separator: "\n"))
        //
        //        """)
        
        if detectionEvents.allSatisfy({ $0.barcodes == barcodes }) {
            let event = PersistenceEvent(time: Date(), barcodes: barcodes)
            persistenceEvents.append(event)
            
            let barcodesChanged = (
                persistenceEvents.count == 1 ||
                event.barcodes != persistenceEvents[persistenceEvents.count - 2].barcodes
            )
            
            if barcodesChanged {
                print("Persistence event: \(barcodes.joined(separator: ","))")
                persistenceHandler(Array(barcodes))
            }
        }
    }
}

extension BarcodeScannerViewController {
    /// Event added when barcodes (including no barcode) have been detected.
    private struct DetectionEvent {
        let time: Date
        let barcodes: Set<String>
    }
    
    /// Event added when the same barcodes (including no barcode) have been stable for some time.
    private struct PersistenceEvent {
        let time: Date
        let barcodes: Set<String>
    }
    
    private struct BarcodeRect {
        let topLeft: CGPoint
        let topRight: CGPoint
        let bottomRight: CGPoint
        let bottomLeft: CGPoint
        let boundingBox: CGRect
    }
}

nonisolated private class UnsafeSendable<Value>: @unchecked Sendable {
    var value: Value
    
    init(_ value: Value) {
        self.value = value
    }
}

#Preview {
    BarcodeScanner(
        minPresenceTime: 0.250,
        minAbsenceTime: 0.500,
        detectionEnabled: true,
        detectedBarcodes: .constant([]),
        persistentBarcodeHandler: { _ in }
    )
}
