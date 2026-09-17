import Foundation
import Vision
guard CommandLine.arguments.count == 2 else { exit(2) }
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false
request.recognitionLanguages = ["en-US"]
do {
  try VNImageRequestHandler(url: url, options: [:]).perform([request])
  let rows: [[String: Any]] = (request.results ?? []).compactMap { observation in
    guard let text = observation.topCandidates(1).first else { return nil }
    let box = observation.boundingBox
    return ["text": text.string, "confidence": text.confidence,
      "x": box.midX, "y": 1.0 - box.midY, "width": box.width, "height": box.height]
  }
  let data = try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted,.sortedKeys])
  FileHandle.standardOutput.write(data)
} catch { fputs("OCR_ERROR \(error)\n", stderr); exit(3) }
