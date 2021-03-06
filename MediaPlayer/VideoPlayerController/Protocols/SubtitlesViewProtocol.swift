//
//  SubtitleProtocol.swift
//  MediaPlayer
//
//  Created by Mikhail Plotnikov on 15.04.2021.
//

import Foundation
import UIKit

protocol SubtitlesViewProtocol: class {
    func writeSubtitles(_ subtitles: String)
    var resultSubtitlesString: String { get set }
}
