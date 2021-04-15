//
//  VideoPlayerController.swift
//  MediaPlayer
//
//  Created by Mikhail Plotnikov on 14.04.2021.
//

import UIKit
import AVKit
import Speech

class VideoPlayerView: UIViewController, SubtitlesViewProtocol {
    
    private var presenter: SpeechRecognizerProtocol?
    private var arrayInteractiveView = [UIView]()
    
    var resultSubtitlesString = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.subtitleLabel.text = self.resultSubtitlesString
            }
        }
    }
    
    private var timerHideUI: Timer?
    private var timerUpdateCurrentTimeVideo: Timer?
    private var sliderIsEditing: Bool = false
    private var showSubtitles: Bool = true {
        didSet {
            self.subtitleLabel.isHidden = !showSubtitles
        }
    }
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var bottomSpaceToLabel: NSLayoutConstraint!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var verticalStack: UIStackView!
    @IBOutlet weak var switchSubtitles: UISwitch!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var horizontalSlider: UISlider!
    
    private var url: URL
    private var player: AVPlayer
    private var playerLayer: AVPlayerLayer
    
    private func startTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timerHideUI?.invalidate()
            self.timerHideUI = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.hideUI), userInfo: nil, repeats: false)
        }
    }
    
    @objc
    private func hideUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.5) {
                self.arrayInteractiveView.forEach { $0.alpha = 0 }
            } completion: { (isEnd) in
                if isEnd {
                    self.arrayInteractiveView.forEach { $0.isHidden = true }
                }
            }
        }
    }
    
    private func showUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.arrayInteractiveView.forEach { $0.isHidden = false }
            UIView.animate(withDuration: 0.5) {
                self.arrayInteractiveView.forEach { $0.alpha = 1 }
            }
        }
    }
    
    private func resetTimer() {
        DispatchQueue.main.async { [weak self] in
            
            self?.timerHideUI?.invalidate()
            self?.startTimer()
        }
    }
    
    @objc
    private func tapOnScreen() {
        if playButton.isHidden {
            showUI()
            resetTimer()
        } else {
            hideUI()
            timerHideUI?.invalidate()
        }
    }
    
    private func playVideo() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.player.play()
            self.player.volume = 0
            self.presenter?.audioPlayNode.play()
            self.playButton.setImage(UIImage(systemName: "stop"), for: .normal)
            self.playButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .highlighted)
        }
    }
    
    private func stopVideo() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.player.pause()
            self.presenter?.audioPlayNode.pause()
            self.playButton.setImage(UIImage(systemName: "play"), for: .normal)
            self.playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .highlighted)
        }
    }
    
    @IBAction func buttonTap(_ sender: Any) {
        if (player.rate == 0) {
            playVideo()
        } else {
            stopVideo()
        }
        startTimer()
    }
    
    @IBAction func closeButtonTap(_ sender: Any) {
        presenter?.prepareToDeinit()
        timerHideUI?.invalidate()
        timerUpdateCurrentTimeVideo?.invalidate()
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    private func seek(to value: Float) {
        guard let duration = player.currentItem?.duration.seconds else { return }
        let newValue = Float(duration) * value
        player.seek(to: CMTime(value: CMTimeValue(newValue), timescale: 1))
        presenter?.seekTo(value: Double(value))
        if player.rate != 0 {
            presenter?.audioPlayNode.play()
        } else {
            presenter?.audioPlayNode.pause()
        }
    }
    
    @IBAction func endEditingValue(_ sender: Any) {
        print("end")
        sliderIsEditing = false
    }
    
    @IBAction func beginEditingValue(_ sender: Any) {
        print("begin")
        sliderIsEditing = true
    }
    
    @IBAction func sliderChangeValue(_ sender: Any) {
        guard let slider = sender as? UISlider else { fatalError("Wrong UI") }
        seek(to: slider.value)
    }
    
    @IBAction func switchTap(_ sender: Any) {
        guard let sender = sender as? UISwitch else { return }
        self.showSubtitles = sender.isOn
    }
    
    private func setupUI() {
        
        videoView.layer.addSublayer(playerLayer)
        
        subtitleLabel.textColor = .white
        
        playButton.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 0.3)
        playButton.layer.cornerRadius = 15
        playButton.setImage(UIImage(systemName: "play"), for: .normal)
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .highlighted)
        
        verticalStack.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 0.3)
        verticalStack.layer.cornerRadius = 15
        
        subtitleLabel.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 0.3)
        subtitleLabel.layer.masksToBounds = true
        subtitleLabel.layer.cornerRadius = 15
        
        switchSubtitles.isOn = false
    }
    
    private func setupInteractiveViewArray() {
        self.arrayInteractiveView.append(contentsOf: [
            closeButton,
            playButton,
            timeLabel,
            verticalStack,
            horizontalSlider
        ])
    }
    
    private func setupUpdateTimeTimer() {
        timerUpdateCurrentTimeVideo = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            self?.updateTimeLabel()
        })
    }
    
    private func updateTimeLabel() {
        if self.player.currentItem?.status == .readyToPlay {
            
            guard let fullTime = self.player.currentItem?.duration.seconds else { return }
            
            let timeElapsed = self.player.currentTime().seconds
            let time = Int(timeElapsed)
            
            if !sliderIsEditing {
                horizontalSlider.value = Float(timeElapsed / fullTime)
            }
            
            timeLabel.text = time.formatToStringTime()
        }
    }
    
    private func setupGestureRecognizer() {
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapOnScreen))
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    init(url: URL) {
        
        self.url = url
        presenter = VideoPlayerPresenter()
        player = AVPlayer(url: url)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        
        super.init(nibName: nil, bundle: nil)
        
        presenter?.setDelegate(delegate: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        setupUI()
        setupInteractiveViewArray()
        setupGestureRecognizer()
        setupUpdateTimeTimer()
        
        showSubtitles = switchSubtitles.isOn
        
        presenter?.takeAudioTrackFromVideo(urlToVideo: url) { [weak self] pathToSound in
            self?.presenter?.startAudioWithSpeechRecognizer(pathToSound: pathToSound) { [weak self] in
                self?.playVideo()
                self?.startTimer()
            }
        }
        checkOrientation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
        checkOrientation()
        
    }
    
    private func checkOrientation() {
        switch UIDevice.current.orientation {
        case .portrait, .unknown:
            bottomSpaceToLabel.constant = self.view.bounds.height * 1/5
            subtitleLabel.textColor = .white
        case .landscapeLeft, .landscapeRight:
            bottomSpaceToLabel.constant = 5
            subtitleLabel.textColor = .black
        default:
            print("UnknownOrientation")
        }
        self.view.layoutIfNeeded()
    }
}

