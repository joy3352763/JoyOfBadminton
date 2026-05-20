import AVFoundation
import Foundation

// MARK: - CameraSession  (Epic G1)
/// AVCaptureSession 封裝，負責相機權限請求、Session 生命週期管理、
/// 將每幀 CMSampleBuffer 透過閃結式回呼傳送出去。
final class CameraSession: NSObject {

    // MARK: Public
    /// 每一影片 frame 回呼（在 CameraSession 內部 serial queue 呼叫）。
    var onFrame: ((CMSampleBuffer) -> Void)?
    /// 每一音訊 frame 回呼。
    var onAudio: ((CMSampleBuffer) -> Void)?

    private(set) var isRunning = false

    // MARK: Private
    private let session   = AVCaptureSession()
    private let videoOut  = AVCaptureVideoDataOutput()
    private let audioOut  = AVCaptureAudioDataOutput()
    private let sessionQ  = DispatchQueue(label: "com.joybadminton.camera", qos: .userInitiated)

    // MARK: Setup
    /// 請求相機權限，完成後呼叫 completion（Main queue）。
    func requestAccessAndConfigure(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted, let self else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.sessionQ.async {
                self.configure()
                DispatchQueue.main.async { completion(true) }
            }
        }
    }

    func start() {
        sessionQ.async { [weak self] in
            guard let self, !self.isRunning else { return }
            self.session.startRunning()
            self.isRunning = true
        }
    }

    func stop() {
        sessionQ.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.session.stopRunning()
            self.isRunning = false
        }
    }

    // MARK: Private — Configure
    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080

        // Video input — 實機裝置用後置鉛頭
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video, position: .back),
           let videoInput = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        // Audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput  = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        // Video output
        videoOut.setSampleBufferDelegate(self, queue: sessionQ)
        videoOut.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOut.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOut) { session.addOutput(videoOut) }

        // Audio output
        audioOut.setSampleBufferDelegate(self, queue: sessionQ)
        if session.canAddOutput(audioOut) { session.addOutput(audioOut) }

        // 結枟對、防止鎖燒自動轉
        if let conn = videoOut.connection(with: .video) {
            if conn.isVideoOrientationSupported {
                conn.videoOrientation = .landscapeRight
            }
            if conn.isVideoStabilizationSupported {
                conn.preferredVideoStabilizationMode = .auto
            }
        }

        session.commitConfiguration()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate,
                          AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if output === videoOut {
            onFrame?(sampleBuffer)
        } else {
            onAudio?(sampleBuffer)
        }
    }
}

// MARK: - Preview Layer Helper
extension CameraSession {
    /// 建立預覽 layer，供 SwiftUI UIViewRepresentable 使用。
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}
