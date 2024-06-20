//
//  ContentView.swift
//  app
//
//  Created by enefry on 2024/6/19.
//

import MLTranslate
import SwiftUI

class DownloadProgress: NSObject, ObservableObject {
    @Published var total: Int64 = 0
    @Published var value: Int64 = 0
    @Published var fractionCompleted: Float32 = 0
    var progress: Progress?
    var updateCallback: ((Float32) -> Void)?

    public func set(progress: Progress?) {
        unbind()
        self.progress = progress
        bind()
    }

    private func bind() {
        if let progress = progress {
            progress.addObserver(self, forKeyPath: "completedUnitCount", context: nil)
            progress.addObserver(self, forKeyPath: "totalUnitCount", context: nil)
            total = progress.totalUnitCount
            value = progress.completedUnitCount
            if total != 0 {
                fractionCompleted = Float32(value) / Float32(total)
            } else {
                fractionCompleted = 0
            }
            updateCallback?(fractionCompleted)
        }
    }

    private func unbind() {
        if let progress = progress {
            progress.removeObserver(self, forKeyPath: "completedUnitCount")
            progress.removeObserver(self, forKeyPath: "totalUnitCount")
            progress.removeObserver(self, forKeyPath: "fractionCompleted")
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let obj = object as? Progress,
           let p = progress,
           p === obj,
           let keyPath = keyPath {
            value = p.completedUnitCount
            total = p.totalUnitCount
            fractionCompleted = Float32(p.fractionCompleted)
            updateCallback?(fractionCompleted)
        }
    }
}

class TranslateModel: ObservableObject {
    @Published var download: Bool = false
    @Published var chineseProgress: DownloadProgress = DownloadProgress()
    @Published var englishProgress: DownloadProgress = DownloadProgress()
    @Published var japaneseProgress: DownloadProgress = DownloadProgress()
    let translator = Translator.translator(options: TranslatorOptions(sourceLanguage: .english, targetLanguage: .chinese))

    init() {
        let languages = ModelManager.modelManager().downloadedTranslateModels.compactMap({ $0.language })
        print("download:\(languages)")
        if languages.contains(.english) && languages.contains(.japanese) && languages.contains(.chinese) {
            download = true
        }
    }

    func downloadModel() {
        let conditions = ModelDownloadConditions(
            allowsCellularAccess: false,
            allowsBackgroundDownloading: true
        )
        let japaneseModel = TranslateRemoteModel.translateRemoteModel(language: .japanese)
        let englishModel = TranslateRemoteModel.translateRemoteModel(language: .english)
        let chineseModel = TranslateRemoteModel.translateRemoteModel(language: .chinese)
        chineseProgress.set(progress: ModelManager.modelManager().download(chineseModel, conditions: conditions))
        englishProgress.set(progress: ModelManager.modelManager().download(englishModel, conditions: conditions))
        japaneseProgress.set(progress: ModelManager.modelManager().download(japaneseModel, conditions: conditions))
        chineseProgress.updateCallback = { [weak self] _ in
            self?.updateDownloadProgress()
        }
        englishProgress.updateCallback = { [weak self] _ in
            self?.updateDownloadProgress()
        }
    }

    func updateDownloadProgress() {
        if chineseProgress.fractionCompleted == 1 && englishProgress.fractionCompleted == 1 {
            download = true
        }
    }

    func translate(from: String) async -> String {
        do {
            return (try await translator.translate(from))
        } catch {
            return error.localizedDescription
        }
    }
}

struct ContentView: View {
    @State var fromStr: String = ""
    @State var toStr: String = ""
    @StateObject var model: TranslateModel = TranslateModel()
    @State var langugeID: String = ""
    var body: some View {
        GeometryReader(content: { geometry in
            VStack {
                TextEditor(text: $fromStr)
                    .border(.gray)
                    .frame(height: geometry.size.height * 0.5 - 20)

                Text(langugeID)
                if model.download {
                    HStack {
                        Button("翻译") {
                            Task {
                                let languageId = LanguageIdentification.languageIdentification()
                                let langugeIDs = try await languageId.identifyPossibleLanguages(for: fromStr)
                                langugeID = langugeIDs.map({ $0.languageTag }).joined(separator: ",")
                                let translator = Translator.translator(options: TranslatorOptions(sourceLanguage: TranslateLanguage(rawValue: langugeID), targetLanguage: .chinese))
                                try await translator.downloadModelIfNeeded()
                                toStr = try await translator.translate(fromStr)
                            }
                        }.buttonBorderShape(.roundedRectangle)
                        Button("语言") {
                            Task {
                                do {
                                    let languageId = LanguageIdentification.languageIdentification()
                                    let langugeIDs = try await languageId.identifyPossibleLanguages(for: fromStr)
                                    langugeID = langugeIDs.map({ $0.languageTag }).joined(separator: ",")
                                    print("id=>\(langugeIDs) \(TranslateLanguage.allLanguages())")
                                } catch {
                                    print("错误：\(error)")
                                }
                            }
                        }.buttonBorderShape(.roundedRectangle)
                    }
                } else {
                    Button("下载模型") {
                        model.downloadModel()
                    }
                    if model.chineseProgress.total > 0 {
                        ProgressView("中文模型", value: model.chineseProgress.fractionCompleted)
                    }
                    if model.englishProgress.total > 0 {
                        ProgressView("英文模型", value: model.englishProgress.fractionCompleted)
                    }
                }
                ScrollView {
                    Text(toStr).frame(width: geometry.size.width)
                }.border(.gray)
                    .frame(width: geometry.size.width,
                           height: geometry.size.height * 0.5 - 20)
            }
        })

        .padding()
    }
}
