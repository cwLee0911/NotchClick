import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Music, SkipBack, SkipForward, Pause, Play } from 'lucide-react';

type MusicService = 'apple' | 'spotify';

export function MusicPlayer() {
  const [service, setService] = useState<MusicService>('spotify');
  const [isPlaying, setIsPlaying] = useState(true);

  return (
    <div className="space-y-4">
      {/* Service Switcher */}
      <div className="flex gap-2">
        <button
          onClick={() => setService('apple')}
          className={`flex-1 px-4 py-2 rounded-xl text-sm transition-all ${
            service === 'apple'
              ? 'bg-white/10 text-white'
              : 'bg-white/5 text-white/50 hover:text-white/80'
          }`}
        >
          Apple Music
        </button>
        <button
          onClick={() => setService('spotify')}
          className={`flex-1 px-4 py-2 rounded-xl text-sm transition-all ${
            service === 'spotify'
              ? 'bg-white/10 text-white'
              : 'bg-white/5 text-white/50 hover:text-white/80'
          }`}
        >
          Spotify
        </button>
      </div>

      {/* Music Content */}
      <AnimatePresence mode="wait">
        {service === 'apple' ? (
          <motion.div
            key="apple"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            className="bg-white/5 rounded-2xl p-6 border border-white/10"
          >
            <div className="flex items-start gap-4">
              {/* Icon */}
              <div className="flex-shrink-0 w-16 h-16 rounded-2xl bg-gradient-to-br from-pink-500 to-red-500 flex items-center justify-center">
                <Music className="w-8 h-8 text-white" />
              </div>

              {/* Content */}
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div>
                    <div className="inline-block px-2 py-0.5 rounded text-[10px] font-semibold bg-pink-500/20 text-pink-300 mb-2">
                      APPLE MUSIC
                    </div>
                    <h3 className="text-white font-medium text-base">
                      Apple Music isn't running
                    </h3>
                  </div>
                  <button className="px-4 py-2 bg-white/10 hover:bg-white/15 rounded-lg text-sm text-white transition-colors">
                    Open Music
                  </button>
                </div>
                <p className="text-sm text-white/60 leading-relaxed">
                  Launch the app to show the current song and playback controls.
                </p>
              </div>
            </div>
          </motion.div>
        ) : (
          <motion.div
            key="spotify"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="bg-white/5 rounded-2xl p-6 border border-white/10"
          >
            <div className="space-y-4">
              <div className="flex gap-4">
                {/* Album Art */}
                <div className="flex-shrink-0 w-24 h-24 rounded-xl bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center overflow-hidden">
                  <div className="w-full h-full bg-gradient-to-br from-purple-300 via-purple-500 to-purple-700 flex items-center justify-center">
                    <svg className="w-12 h-12 text-black/50" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M12 2L14 8L20 8L15 12L17 18L12 14L7 18L9 12L4 8L10 8L12 2Z" />
                    </svg>
                  </div>
                </div>

                {/* Track Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2 mb-1">
                    <div className="min-w-0 flex-1">
                      <h3 className="text-white font-medium text-base truncate">Music album appears on the left</h3>
                      <p className="text-white/60 text-sm truncate">Control playback from the notch</p>
                      <p className="text-white/40 text-xs truncate">Spotify or Apple Music</p>
                    </div>
                    <div className="flex-shrink-0 px-2 py-0.5 rounded text-[10px] font-semibold bg-green-500/20 text-green-300">
                      SPOTIFY
                    </div>
                  </div>
                </div>
              </div>

              {/* Progress Bar */}
              <div className="space-y-3">
                <div className="flex items-center gap-2 text-[10px] text-white/40">
                  <span>3:03</span>
                  <div className="flex-1 h-1 bg-white/10 rounded-full overflow-hidden">
                    <div className="h-full bg-white/60 rounded-full" style={{ width: '65%' }} />
                  </div>
                  <span>3:16</span>
                </div>

                {/* Controls */}
                <div className="flex w-full items-center justify-center gap-4">
                  <button className="w-8 h-8 flex items-center justify-center rounded-lg bg-white/10 hover:bg-white/15 transition-colors">
                    <SkipBack className="w-4 h-4 text-white" />
                  </button>
                  <button
                    onClick={() => setIsPlaying(!isPlaying)}
                    className="w-10 h-10 flex items-center justify-center rounded-lg bg-green-500 hover:bg-green-600 transition-colors"
                  >
                    {isPlaying ? (
                      <Pause className="w-5 h-5 text-white" fill="white" />
                    ) : (
                      <Play className="w-5 h-5 text-white" fill="white" />
                    )}
                  </button>
                  <button className="w-8 h-8 flex items-center justify-center rounded-lg bg-white/10 hover:bg-white/15 transition-colors">
                    <SkipForward className="w-4 h-4 text-white" />
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
