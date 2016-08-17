//
//  SpeechService.swift
//  Future Self
//
//  Based on SpeakToMe by Apple
//  https://developer.apple.com/library/prerelease/content/samplecode/SpeakToMe/Introduction/Intro.html
//

import Foundation
import Speech

enum SpeechState {
    case NoPermission
    case Available
    case NotAvailable
    case Recording
    case Stopping
}

protocol SpeechServiceDelegate {

    func speechStateDidChange(speechState: SpeechState)
    func completeWithText(text: String)
}

class SpeechService: NSObject, SFSpeechRecognizerDelegate {

    // MARK: - SpeechService

    // MARK: Internal

    var delegate: SpeechServiceDelegate?

    func setupSpeech() {
        speechRecognizer.delegate = self

        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Callback can come in on a background thread.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.delegate?.speechStateDidChange(speechState: .Available)

                case .denied, .restricted, .notDetermined:
                    self.delegate?.speechStateDidChange(speechState: .NotAvailable)
                }
            }
        }
    }

    func startStop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            delegate?.speechStateDidChange(speechState: .Stopping)
        } else {
            do {
                try startRecording()
                delegate?.speechStateDidChange(speechState: .Recording)
            } catch {
                delegate?.speechStateDidChange(speechState: .NotAvailable)
            }
        }
    }

    func startRecording() throws {
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }

        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true

        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                isFinal = result.isFinal

                if isFinal {
                    self.delegate?.completeWithText(text: result.bestTranscription.formattedString)
                }
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.delegate?.speechStateDidChange(speechState: .Available)
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        try audioEngine.start()
    }

    // MARK: Private

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - SFSpeechRecognizerDelegate

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            delegate?.speechStateDidChange(speechState: .Available)
        } else {
            delegate?.speechStateDidChange(speechState: .NotAvailable)
        }
    }
}
