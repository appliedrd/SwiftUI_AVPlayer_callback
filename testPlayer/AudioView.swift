//
//  AudioView.swift
//  AVPlayer-SwiftUI
//
//  Created by Chris Mash on 08/03/2020.
//  Copyright © 2020 Chris Mash. All rights reserved.
//

import SwiftUI
import AVFoundation

struct AudioView: View {
    let player = AVPlayer()
    let prompts = ["introduction", "start_walking", "stop_walking", "finish"]
    @State private var prompt_index = 0
    
    var body: some View {
        VStack {
            AudioPlayerControlsView(onEmit: { str in
                print("we are here" + str)
            },
                                    player: player,
                                    timeObserver: PlayerTimeObserver(player: player),
                                    durationObserver: PlayerDurationObserver(player: player),
                                    itemObserver: PlayerItemObserver(player: player))
            
            Button(action: {
                let path = Bundle.main.path(forResource: self.prompts[prompt_index], ofType: "mp3")!
                let url = URL(fileURLWithPath: path)
                let playerItem = AVPlayerItem(url: url)
                self.player.replaceCurrentItem(with: playerItem)
                self.player.play()
                self.prompt_index = self.prompt_index + 1 % self.prompts.count
            })
            {
                TimerButton(label: "Play", buttonColor: .green)
            }
        }
        .onDisappear {
            // When this View isn't being shown anymore stop the player
            self.player.replaceCurrentItem(with: nil)
        }
    }
}
