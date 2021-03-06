//
//  ViewController.swift
//  Dictation
//
//  Created by Esha on 01/11/20.
//

import UIKit
import Speech


class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var textBox: UITextView!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        speechRecognizer.delegate = self
        
        // Asynchronously make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in

            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.audioButton.isEnabled = true
                    
                case .denied:
                    self.audioButton.isEnabled = false
                    self.audioButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.audioButton.isEnabled = false
                    self.audioButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.audioButton.isEnabled = false
                    self.audioButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                    
                default:
                    self.audioButton.isEnabled = false
                }
            }
        }
    }
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.textBox.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text \(result.bestTranscription.formattedString)")
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.audioButton.isEnabled = true
                self.audioButton.setTitle("Start Recording", for: [])
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        textBox.text = "(Speak)"
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            //audioButton.isEnabled = true
            audioButton.setImage(UIImage(named: "audio"), for: UIControl.State.normal)
        } else {
            //audioButton.isEnabled = false
            audioButton.setImage(UIImage(named: "no_audio"), for: UIControl.State.normal)
        }
    }

    @IBAction func audioButtonTapped(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            //audioButton.isEnabled = false
            audioButton.setImage(UIImage(named: "no_audio"), for: UIControl.State.normal)
        } else {
            do {
                try startRecording()
                audioButton.setImage(UIImage(named: "audio"), for: UIControl.State.normal)
            } catch {
                audioButton.setImage(UIImage(named: "no_audio"), for: UIControl.State.normal)
            }
        
    }
    
}
}

