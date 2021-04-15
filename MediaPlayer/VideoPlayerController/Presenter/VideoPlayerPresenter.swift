//
//  VideoPlayerPresenter.swift
//  MediaPlayer
//
//  Created by Mikhail Plotnikov on 15.04.2021.
//
import UIKit
import Foundation
import AVKit
import Speech

class VideoPlayerPresenter: SpeechRecognizerProtocol {
    
    private weak var delegate: SubtitlesViewProtocol?
    
    public func setDelegate(delegate: SubtitlesViewProtocol) {
        self.delegate = delegate
    }
    
    private var audioFile: AVAudioFile?
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private let recognizer = SFSpeechRecognizer(locale: Locale.current)
    private var task: SFSpeechRecognitionTask?
    private var resultString = "" {
        didSet {
            delegate?.resultSubtitlesString = resultString
        }
    }
    private func getFile(path: URL) -> AVAudioFile? {
        guard let temp = try? AVAudioFile(forReading: path) else { return nil }
        return temp
    }
    var audioEngine = AVAudioEngine()
    var audioPlayNode = AVAudioPlayerNode()
    
    func takeAudioTrackFromVideo(urlToVideo: URL, closure: @escaping (URL) -> () = {_ in}) {
        
        let asset = AVAsset(url: urlToVideo)
        let pathToSound = getPathToSound(urlToVideo: urlToVideo)
        asset.writeAudioTrack(to: pathToSound) {
            closure(pathToSound)
        } failure: { (err) in
            fatalError("\(err.localizedDescription)")
        }
    }
    
    private func getPathToSound(urlToVideo: URL) -> URL {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        let nameForSound = urlToVideo.lastPathComponent.dropLast(4)
        
        return dir.appendingPathComponent("\(nameForSound).m4a")
    }
    
    private func configureSoundEngine(pathToFile: URL) {
        self.audioEngine.attach(self.audioPlayNode)
        self.audioEngine.connect(self.audioPlayNode, to: self.audioEngine.mainMixerNode, format: nil)
        guard let file = getFile(path: pathToFile) else { return }
        self.audioFile = file
        self.audioPlayNode.scheduleFile(file, at: nil, completionHandler: nil)
        
        self.audioEngine.mainMixerNode.outputVolume = 1
        
        self.audioEngine.prepare()
        try? self.audioEngine.start()
        
    }
    
    func startAudioWithSpeechRecognizer(pathToSound: URL, closure: @escaping () -> ()) {
        SFSpeechRecognizer.requestAuthorization { [weak self] in
            if $0 == .authorized {
                self?.configureSoundEngine(pathToFile: pathToSound)
                self?.recognize()
                closure()
            }
        }
    }
    
    private func recognize() {
        guard let recognizer = recognizer else { return }
        request = SFSpeechAudioBufferRecognitionRequest()
        let recogFormat = self.audioEngine.mainMixerNode.outputFormat(forBus: 0)
        self.audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: recogFormat) { [weak self] buffer, _ in
            self?.request.append(buffer)
        }
        
        task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] (result, err) in
            guard err == nil,
                  let result = result,
                  let self = self else { return }
            
            if result.isFinal && !self.isEnd {
                self.audioEngine.mainMixerNode.removeTap(onBus: 0)
                
                self.recognize()
                
            } else {
                
                let transcr = result.bestTranscription.formattedString
                let components = transcr.components(separatedBy: .whitespaces)
                var words = components.filter { !$0.isEmpty }
                
                if words.count > 16 {
                    words = Array(words[words.endIndex - 15 ..< words.endIndex])
                }
                self.resultString = words.joined(separator: " ")
                
            }
        })
        
    }
    
    var isEnd = false
    
    func seekTo(value: Double) {
        guard let audioFile = audioFile else { return }
        let newSampleTime = AVAudioFramePosition(Double(audioFile.length) * value)
        var frameCount = audioFile.length - newSampleTime
        audioPlayNode.stop()
        if frameCount <= 0 {
            frameCount = 1
        }
        audioPlayNode.scheduleSegment(audioFile, startingFrame: newSampleTime, frameCount: AVAudioFrameCount(frameCount), at: nil)
        
    }
    
    func prepareToDeinit() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isEnd = true
            self.task?.cancel()
            self.task?.finish()
            self.task = nil
            self.request.endAudio()
            self.audioEngine.stop()
            self.audioEngine.disconnectNodeOutput(self.audioPlayNode)
            self.audioEngine.detach(self.audioPlayNode)
            self.audioPlayNode.stop()
        }
    }
}
