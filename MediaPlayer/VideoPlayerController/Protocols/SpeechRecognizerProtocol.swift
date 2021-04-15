//
//  SpeechRecognizerProtocol.swift
//  MediaPlayer
//
//  Created by Mikhail Plotnikov on 15.04.2021.
//

import Foundation
import AVKit

protocol SpeechRecognizerProtocol: class {
    func setDelegate(delegate: SubtitlesViewProtocol)
    func takeAudioTrackFromVideo(urlToVideo: URL, closure: @escaping (URL) -> ())
    func startAudioWithSpeechRecognizer(pathToSound: URL, closure: @escaping () -> ())
    func prepareToDeinit()
    func seekTo(value: Double)
    
    var audioEngine: AVAudioEngine { get }
    var audioPlayNode: AVAudioPlayerNode { get }
}
