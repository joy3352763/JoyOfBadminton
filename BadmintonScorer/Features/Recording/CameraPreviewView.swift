import AVFoundation
import SwiftUI

// MARK: - CameraPreviewView
/// AVCaptureVideoPreviewLayer 的 SwiftUI 包裝層。
/// 取代 Epic E 的 CameraPreviewPlaceholder。
struct CameraPreviewView: UIViewRepresentable {
    let cameraSession: CameraSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        let layer = cameraSession.makePreviewLayer()
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        view.previewLayer = layer
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer?.frame = uiView.bounds
    }

    // MARK: - Inner UIView
    final class PreviewUIView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer?

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
}
