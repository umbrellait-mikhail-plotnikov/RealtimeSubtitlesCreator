//
//  ViewController.swift
//  MediaPlayer
//
//  Created by Mikhail Plotnikov on 13.04.2021.
//
import MobileCoreServices
import AVFoundation
import AVKit
import Speech
import UIKit

class ViewController: UIViewController {
    
    private func pushVideoPlayerController(url: URL) {
        let videoPlayerController = VideoPlayerView(url: url)
        
        self.navigationController?.pushViewController(videoPlayerController, animated: true)
    }
    
    @IBAction func buttonTap(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = [kUTTypeMovie as String]
        pickerController.videoExportPreset = AVAssetExportPresetPassthrough
        self.present(pickerController, animated: true)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pathToVideo = info[.mediaURL] as? URL else { return }
        
        picker.dismiss(animated: true) {
            self.pushVideoPlayerController(url: pathToVideo)
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
