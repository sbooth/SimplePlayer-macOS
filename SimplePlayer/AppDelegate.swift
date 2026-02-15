//
// Copyright (c) 2009-2026 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/SimplePlayer-macOS
// MIT license
//

import AppKit
import os.log

import SFBAudioEngine

@main
class AppDelegate: NSObject {
    @IBOutlet weak var playerWindowController: PlayerWindowController!

    @IBAction func openFile(_ sender: AnyObject?) {
        let openPanel = NSOpenPanel()

        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = PlayerWindowController.supportedPathExtensions

        if openPanel.runModal() == .OK {
            if let url = openPanel.urls.first {
                playerWindowController.play(url: url)
            }
        }
    }

    @IBAction func addFiles(_ sender: AnyObject?) {
        let openPanel = NSOpenPanel()

        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = PlayerWindowController.supportedPathExtensions

        if openPanel.runModal() == .OK {
            playerWindowController.addToPlaylist(urls: openPanel.urls)
        }
    }

    @IBAction func analyzeFiles(_ sender: AnyObject?) {
        let openPanel = NSOpenPanel()

        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = PlayerWindowController.supportedPathExtensions

        if openPanel.runModal() == .OK {
            do {
                let urls = openPanel.urls
                let start = DispatchTime.now()
                let rg = try ReplayGainAnalyzer.analyzeAlbum(urls)
                let end = DispatchTime.now()
                let msecTaken = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / Double(NSEC_PER_MSEC)
                os_log("Analyzed replain gain for %d tracks in %.2f msec (%.2f msec per track)", urls.count, msecTaken, msecTaken / Double(urls.count))
                os_log("Album gain %.2f dB, peak %.6f\nTracks:\n%{public}@", rg.replayGain.gain, rg.replayGain.peak, rg.trackReplayGain.map({ (url, replayGain) in String(format: "    \"%@\" gain %.2f dB, peak %.6f", FileManager.default.displayName(atPath: url.lastPathComponent), replayGain.gain, replayGain.peak) }).joined(separator: "\n"))
                let alert = NSAlert()
                alert.messageText = "Replay Gain Analysis Complete"
                alert.informativeText = "Check log for details."
                alert.runModal()
            } catch let error {
                NSApp.presentError(error)
            }
        }
    }

    @IBAction func exportWAVEFile(_ sender: AnyObject?) {
        let openPanel = NSOpenPanel()

        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = PlayerWindowController.supportedPathExtensions

        if openPanel.runModal() == .OK, let url = openPanel.url {
            let destURL = url.deletingPathExtension().appendingPathExtension("wav")
            if FileManager.default.fileExists(atPath: destURL.path) {
                let alert = NSAlert()
                alert.messageText = "Do you want to overwrite the existing file?"
                alert.informativeText = "A file with the same name already exists."
                alert.addButton(withTitle: "Overwrite")
                alert.addButton(withTitle: "Cancel")

                if alert.runModal() != NSApplication.ModalResponse.alertFirstButtonReturn {
                    return
                }
            }

            do {
                try AudioConverter.convert(url, to: destURL)
                // Silently fail if metadata can't be copied
                try? AudioFile.copyMetadata(from: url, to: destURL)
            } catch let error {
                try? FileManager.default.trashItem(at: destURL, resultingItemURL: nil)
                NSApp.presentError(error)
            }
        }
    }
}

// MARK: - NSApplicationDelegate
extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        playerWindowController.showWindow(self)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            playerWindowController.play(url: url)
        }
    }
}
