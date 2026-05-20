import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

// MARK: - RecordingState  (Epic G4)
enum RecordingState: Equatable {
    case idle
    case recording
    case paused
    case finalizing
    case saved(url: URL)
    case failed(message: String)

    var isActive: Bool {
        self == .recording || self == .paused
    }
}

// MARK: - RecorderPipeline  (Epic G2 / G3 / G4)
/// AVCaptureSession → AVAssetWriter 主線。
/// 每幀 video frame 透過 BurnInRenderer 燒錄 overlay CGImage。
/// 線程安全：所有 AVFoundation 回呼在 sessionQ；狀態變更發布至 MainActor。
@MainActor
final class RecorderPipeline: NSObject, ObservableObject {

    // MARK: Published
    @Published private(set) var recordingState: RecordingState = .idle

    // MARK: Dependencies
    let cameraSession: CameraSession
    private let burnIn: BurnInRenderer

    // MARK: Overlay snapshot provider (set by OverlayViewModel)
    var currentSnapshot: OverlaySnapshot?

    // MARK: Private — Writer
    private var assetWriter:       AVAssetWriter?
    private var videoInput:        AVAssetWriterInput?
    private var audioInput:        AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private var outputURL: URL?
    private var sessionStartTime: CMTime = .zero
    private var hasStartedSession = false

    private let writerQ = DispatchQueue(label: "com.joybadminton.writer", qos: .userInitiated)

    // MARK: Video settings
    private let videoWidth  = 1920
    private let videoHeight = 1080

    // MARK: Init
    init(cameraSession: CameraSession = CameraSession(),
         burnIn: BurnInRenderer = BurnInRenderer()) {
        self.cameraSession = cameraSession
        self.burnIn = burnIn
        super.init()
        wireCameraCallbacks()
    }

    // MARK: - Public API

    /// 開始錄影。
    func startRecording() {
        guard recordingState == .idle else { return }
        let url = makeOutputURL()
        outputURL = url
        do {
            try prepareWriter(url: url)
            recordingState = .recording
            cameraSession.start()
        } catch {
            recordingState = .failed(message: error.localizedDescription)
        }
    }

    /// 暫停錄影（封閉 audio / video input，保留 writer）。
    func pauseRecording() {
        guard recordingState == .recording else { return }
        videoInput?.markAsFinished()
        recordingState = .paused
    }

    /// 復原錄影（重建 writer，接續上一段 timestamp）。
    func resumeRecording() {
        guard recordingState == .paused, let url = outputURL else { return }
        do {
            try prepareWriter(url: url)
            recordingState = .recording
        } catch {
            recordingState = .failed(message: error.localizedDescription)
        }
    }

    /// 停止錄影、封閉 writer、將檔案儲存至相冊。
    func stopRecording() {
        guard recordingState.isActive || recordingState == .paused else { return }
        recordingState = .finalizing
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            guard let self else { return }
            let url = self.outputURL
            Task { @MainActor in
                if let url {
                    self.recordingState = .saved(url: url)
                } else {
                    self.recordingState = .failed(message: "No output URL")
                }
                self.resetWriter()
            }
        }
        cameraSession.stop()
    }

    // MARK: - Private — Writer Setup

    private func prepareWriter(url: URL) throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)

        // Video input
        let vSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoWidth,
            AVVideoHeightKey: videoHeight,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: vSettings)
        vInput.expectsMediaDataInRealTime = true

        let pxAttr: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey  as String: videoWidth,
            kCVPixelBufferHeightKey as String: videoHeight
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: vInput,
            sourcePixelBufferAttributes: pxAttr
        )

        // Audio input
        let aSettings: [String: Any] = [
            AVFormatIDKey:         kAudioFormatMPEG4AAC,
            AVSampleRateKey:       44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey:   128_000
        ]
        let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: aSettings)
        aInput.expectsMediaDataInRealTime = true

        if writer.canAdd(vInput) { writer.add(vInput) }
        if writer.canAdd(aInput) { writer.add(aInput) }

        writer.startWriting()

        assetWriter        = writer
        videoInput         = vInput
        audioInput         = aInput
        pixelBufferAdaptor = adaptor
        hasStartedSession  = false
    }

    private func resetWriter() {
        assetWriter        = nil
        videoInput         = nil
        audioInput         = nil
        pixelBufferAdaptor = nil
        hasStartedSession  = false
        outputURL          = nil
    }

    // MARK: - Private — Camera Wiring

    private func wireCameraCallbacks() {
        cameraSession.onFrame = { [weak self] sampleBuffer in
            self?.processVideoFrame(sampleBuffer)
        }
        cameraSession.onAudio = { [weak self] sampleBuffer in
            self?.processAudioFrame(sampleBuffer)
        }
    }

    // MARK: - Private — Frame Processing  (G3 Overlay Composite)

    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard recordingState == .recording,
              let writer = assetWriter,
              let vInput = videoInput,
              let adaptor = pixelBufferAdaptor,
              vInput.isReadyForMoreMediaData else { return }

        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if !hasStartedSession {
            writer.startSession(atSourceTime: pts)
            sessionStartTime  = pts
            hasStartedSession = true
        }

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // 燒錄 overlay
        let composited = compositeOverlay(onto: imageBuffer, pts: pts)
        adaptor.append(composited ?? imageBuffer, withPresentationTime: pts)
    }

    private func processAudioFrame(_ sampleBuffer: CMSampleBuffer) {
        guard recordingState == .recording,
              let aInput = audioInput,
              aInput.isReadyForMoreMediaData else { return }
        aInput.append(sampleBuffer)
    }

    // MARK: - Overlay Composite  (G3)
    /// 將 BurnInRenderer 產生的 CGImage 合成入 CVPixelBuffer。
    private func compositeOverlay(onto imageBuffer: CVImageBuffer,
                                  pts: CMTime) -> CVPixelBuffer? {
        guard let snapshot = currentSnapshot,
              let overlayImage = burnIn.render(snapshot: snapshot) else {
            return nil  // 無 overlay 時原実輸出圖像
        }

        CVPixelBufferLockBaseAddress(imageBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, []) }

        let w = CVPixelBufferGetWidth(imageBuffer)
        let h = CVPixelBufferGetHeight(imageBuffer)
        let baseAddr = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)

        guard let ctx = CGContext(
            data: baseAddr,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                      | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        // Overlay 薊於影片
        ctx.draw(overlayImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return nil  // in-place 修改 imageBuffer，回 nil 表示直接用原 buffer
    }

    // MARK: - Helpers
    private func makeOutputURL() -> URL {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fname = "match_\(ISO8601DateFormatter().string(from: Date())).mp4"
        return docs.appendingPathComponent(fname)
    }
}
