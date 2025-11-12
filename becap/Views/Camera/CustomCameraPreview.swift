//
//  CustomCameraPreview.swift
//  becap
//
//  Created by Victor Derveaux on 11/11/2025.
//

import SwiftUI

struct CustomCameraPreview: UIViewRepresentable {
    @ObservedObject var viewModel: CustomCameraViewModel

    func makeCoordinator() -> CustomCameraPreviewCoordinator {
        CustomCameraPreviewCoordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = viewModel.makePreviewLayer()
        previewLayer.frame = UIScreen.main.bounds

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)
        view.layer.addSublayer(previewLayer)

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class CustomCameraPreviewCoordinator: NSObject {
        weak var viewModel: CustomCameraViewModel?

        init(viewModel: CustomCameraViewModel) {
            self.viewModel = viewModel
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            viewModel?.setZoom(scale: gesture.scale)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            viewModel?.switchCamera()
        }
    }
}
