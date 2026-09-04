import AVFoundation

enum AudioRecorderError: Error {
    case engineStartFailed(Error)
    case converterCreationFailed
}

/// Captures microphone audio while running and hands back mono 16kHz
/// Float32 samples on stop — the format WhisperKit expects.
final class AudioRecorder {
    /// WhisperKit (like whisper.cpp) is trained on 16kHz mono audio.
    private static let targetSampleRate: Double = 16_000
    private static let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: targetSampleRate,
        channels: 1,
        interleaved: false
    )!

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var samples: [Float] = []
    private let queue = DispatchQueue(label: "com.liamdevine.echo.audio-recorder")
    private(set) var isRecording = false

    /// Optional Core Audio device UID to record from. Nil uses the system
    /// default input device.
    var preferredInputDeviceUID: String?

    func start() throws {
        guard !isRecording else { return }

        if let uid = preferredInputDeviceUID {
            AudioDeviceSelector.setDefaultInputDevice(uid: uid)
        }

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: inputFormat, to: Self.targetFormat) else {
            throw AudioRecorderError.converterCreationFailed
        }
        self.converter = converter

        samples.removeAll(keepingCapacity: true)

        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.convertAndStore(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw AudioRecorderError.engineStartFailed(error)
        }

        isRecording = true
    }

    /// Stops capture and returns the accumulated mono 16kHz samples.
    @discardableResult
    func stop() -> [Float] {
        guard isRecording else { return [] }
        isRecording = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        return queue.sync { samples }
    }

    private func convertAndStore(_ buffer: AVAudioPCMBuffer) {
        guard let converter else { return }

        let ratio = Self.targetSampleRate / buffer.format.sampleRate
        let outCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: Self.targetFormat, frameCapacity: outCapacity) else { return }

        var error: NSError?
        var consumed = false
        converter.convert(to: outBuffer, error: &error) { _, inputStatus in
            if consumed {
                inputStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            inputStatus.pointee = .haveData
            return buffer
        }

        guard error == nil, let channelData = outBuffer.floatChannelData else { return }
        let frames = Int(outBuffer.frameLength)
        let chunk = Array(UnsafeBufferPointer(start: channelData[0], count: frames))

        queue.sync {
            samples.append(contentsOf: chunk)
        }
    }
}
