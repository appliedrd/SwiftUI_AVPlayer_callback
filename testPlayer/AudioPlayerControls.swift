//
//  AudioPlayerControls.swift
//  testPlayer
//
//  Created by Edward Hill on 2023-01-13.
//

import SwiftUI
import AVFoundation

struct MyContentView : View {
    var doSomething : () -> ()
    var body: some View {
        Button(action: { self.doSomething() }) { Text("do something") }
    }
}

struct AudioPlayerControlsView: View {
    private enum PlaybackState: Int {
        case stopped
        case buffering
        case playing
    }
    var onEmit: (String) -> Void
    
    let player: AVPlayer
    let timeObserver: PlayerTimeObserver
    let durationObserver: PlayerDurationObserver
    let itemObserver: PlayerItemObserver
    let fudgeFactor = 0.1
    @State private var currentTime: TimeInterval = 0
    @State private var currentDuration: TimeInterval = 0
    @State private var state = PlaybackState.stopped
    
    var body: some View {
        VStack {
            if state == .stopped {
                Text("")
            } else if state == .buffering {
                Text("buffering...")
            } else {
                Text("playing prompt")
            }
            
//            Button(action: {
//                let path = Bundle.main.path(forResource: "finish", ofType: "mp3")!
//                let url = URL(fileURLWithPath: path)
//                let playerItem = AVPlayerItem(url: url)
//                self.player.replaceCurrentItem(with: playerItem)
//                self.player.play()
//                
//            })
//            {
//                TimerButton(label: "Play", buttonColor: .green)
//            }
//            
            Slider(value: $currentTime,
                   in: 0...currentDuration,
                   onEditingChanged: sliderEditingChanged,
                   minimumValueLabel: Text("\(Utility.formatSecondsToHMS(currentTime))"),
                   maximumValueLabel: Text("\(Utility.formatSecondsToHMS(currentDuration))")) {
                    // I have no idea in what scenario this View is shown...
                    Text("seek/progress slider")
            }
            .disabled(state != .playing)
        }
        .padding()
        // Listen out for the time observer publishing changes to the player's time
        .onReceive(timeObserver.publisher) { time in
            // Update the local var
            self.currentTime = time
            print(">>>> time: \(time)")
            if (self.currentDuration > 0 && self.currentTime >= self.currentDuration - self.fudgeFactor) {
                print("-------- we are done")
                self.state = .stopped
                self.onEmit("yipppe")
                
            }
            // And flag that we've started playback
            if time > 0 {
                self.state = .playing
            }
        }
        // Listen out for the duration observer publishing changes to the player's item duration
        .onReceive(durationObserver.publisher) { duration in
            // Update the local var
            self.currentDuration = duration
            print(">>>> duration: \(duration)")
        }
        // Listen out for the item observer publishing a change to whether the player has an item
        .onReceive(itemObserver.publisher) { hasItem in
            self.state = hasItem ? .buffering : .stopped
            self.currentTime = 0
            self.currentDuration = 0
        }
        // TODO the below could replace the above but causes a crash
//        // Listen out for the player's item changing
//        .onReceive(player.publisher(for: \.currentItem)) { item in
//            self.state = item != nil ? .buffering : .stopped
//            self.currentTime = 0
//            self.currentDuration = 0
//        }
    }
    
    // MARK: Private functions
    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            // Tell the PlayerTimeObserver to stop publishing updates while the user is interacting
            // with the slider (otherwise it would keep jumping from where they've moved it to, back
            // to where the player is currently at)
            timeObserver.pause(true)
        }
        else {
            // Editing finished, start the seek
            state = .buffering
            let targetTime = CMTime(seconds: currentTime,
                                    preferredTimescale: 600)
            player.seek(to: targetTime) { _ in
                // Now the (async) seek is completed, resume normal operation
                self.timeObserver.pause(false)
                self.state = .playing
            }
        }
    }
}

import Combine
class PlayerTimeObserver {
    let publisher = PassthroughSubject<TimeInterval, Never>()
    private weak var player: AVPlayer?
    private var timeObservation: Any?
    private var paused = false
    
    init(player: AVPlayer) {
        self.player = player
        
        // Periodically observe the player's current time, whilst playing
        timeObservation = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: nil) { [weak self] time in
            guard let self = self else { return }
            // If we've not been told to pause our updates
            guard !self.paused else { return }
            // Publish the new player time
            self.publisher.send(time.seconds)
        }
    }
    
    deinit {
        if let player = player,
            let observer = timeObservation {
            player.removeTimeObserver(observer)
        }
    }
    
    func pause(_ pause: Bool) {
        paused = pause
    }
}

class PlayerItemObserver {
    let publisher = PassthroughSubject<Bool, Never>()
    private var itemObservation: NSKeyValueObservation?
    
    init(player: AVPlayer) {
        // Observe the current item changing
        itemObservation = player.observe(\.currentItem) { [weak self] player, change in
            guard let self = self else { return }
            // Publish whether the player has an item or not
            self.publisher.send(player.currentItem != nil)
        }
    }
    
    deinit {
        if let observer = itemObservation {
            observer.invalidate()
        }
    }
}

class PlayerDurationObserver {
    let publisher = PassthroughSubject<TimeInterval, Never>()
    private var cancellable: AnyCancellable?
    
    init(player: AVPlayer) {
        let durationKeyPath: KeyPath<AVPlayer, CMTime?> = \.currentItem?.duration
        cancellable = player.publisher(for: durationKeyPath).sink { duration in
            guard let duration = duration else { return }
            guard duration.isNumeric else { return }
            self.publisher.send(duration.seconds)
        }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
