//
//  CaptureImageView.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/10/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var isCoordinatorShown: Bool
    @Binding var imageInCoordinator: Image?
    @Binding var uiImageInCoordinator: UIImage?
    init(isShown: Binding<Bool>, image: Binding<Image?>, uiImage: Binding<UIImage?>) {
        _isCoordinatorShown = isShown
        _imageInCoordinator = image
        _uiImageInCoordinator = uiImage
    }

    func imagePickerController(_: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let unwrapImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        uiImageInCoordinator = unwrapImage
        imageInCoordinator = Image(uiImage: unwrapImage)
        isCoordinatorShown = false
    }

    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        isCoordinatorShown = false
    }
}

extension CaptureImageView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureImageView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_: UIImagePickerController,
                                context _: UIViewControllerRepresentableContext<CaptureImageView>) {}
}

struct CaptureImageView {
    @Binding var isShown: Bool
    @Binding var image: Image?
    @Binding var uiImage: UIImage?

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown, image: $image, uiImage: $uiImage)
    }
}
