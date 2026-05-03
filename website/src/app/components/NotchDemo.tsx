import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Grid2X2Plus, Music } from 'lucide-react';
import { AppIcon } from './AppIcon';
import { MusicPlayer } from './MusicPlayer';

type Tab = 'launcher' | 'music';

export function NotchDemo() {
  const [isExpanded, setIsExpanded] = useState(true);
  const [activeTab, setActiveTab] = useState<Tab>('music');

  const tabs = [
    { id: 'launcher' as Tab, label: 'Launcher', icon: Grid2X2Plus },
    { id: 'music' as Tab, label: 'Music', icon: Music },
  ];

  const apps = [
    { name: 'Calculator', color: '' },
    { name: 'Calendar', color: '' },
    { name: 'Notion', color: '' },
    { name: 'Spotify', color: '' },
    { name: 'MindNode', color: '' },
    { name: 'Messages', color: '' },
    { name: 'Notes', color: '' },
    { name: 'Reminders', color: '' },
    { name: 'Terminal', color: '' },
    { name: 'Atom', color: '' },
    { name: 'Add', color: '' },
  ];

  return (
    <div className="relative w-screen max-w-[100vw] sm:w-full sm:max-w-6xl sm:mx-auto px-4 overflow-visible">
      <div className="relative">
        {/* Collapsed Notch */}
        <AnimatePresence>
          {!isExpanded && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="flex justify-center"
            >
              <button
                onClick={() => setIsExpanded(true)}
                className="bg-black rounded-full h-8 w-48 hover:scale-105 transition-transform duration-300"
              />
            </motion.div>
          )}
        </AnimatePresence>

        {/* Expanded Notch Panel */}
        <AnimatePresence>
          {isExpanded && (
            <motion.div
              initial={false}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0, height: 32 }}
              transition={{ duration: 0.5, ease: [0.32, 0.72, 0, 1] }}
              className="relative mx-auto"
              style={{ maxWidth: '1040px', width: 'min(100%, calc(100vw - 2rem))' }}
            >
              {/* Glow Effect */}
              <div className="absolute inset-0 bg-purple-500/20 blur-[100px] rounded-[48px]" />

              {/* Main Panel */}
              <motion.div
                className="relative bg-[#0b0714]/[.92] backdrop-blur-2xl rounded-[30px] sm:rounded-[42px] overflow-visible shadow-2xl"
                style={{
                  minHeight: '430px',
                  boxShadow: '0 25px 50px -12px rgba(139, 92, 246, 0.25), 0 0 0 1px rgba(139, 92, 246, 0.25)',
                }}
              >
                <div className="p-5 sm:p-9">
                  {/* Tab Bar */}
                  <div className="grid grid-cols-2 gap-1 rounded-[28px] border border-purple-400/20 bg-purple-950/20 p-2 shadow-[inset_0_0_0_1px_rgba(255,255,255,.03)]">
                    {tabs.map((tab) => {
                      const Icon = tab.icon;
                      const isActive = activeTab === tab.id;
                      return (
                        <button
                          key={tab.id}
                          onClick={() => setActiveTab(tab.id)}
                          className="relative min-w-0 flex h-12 items-center justify-center gap-2 px-3 sm:px-4 rounded-[22px] transition-all duration-300 focus:outline-none"
                        >
                          {isActive && (
                            <motion.div
                              layoutId="activeTab"
                              className="absolute inset-0 rounded-[22px] bg-gradient-to-r from-violet-500/55 to-purple-400/35 shadow-[0_10px_28px_rgba(139,92,246,.22)]"
                              transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
                            />
                          )}
                          <Icon className={`relative z-10 h-4 w-4 ${isActive ? 'text-white' : 'text-white/45'}`} />
                          <span className={`relative z-10 truncate text-sm font-semibold ${isActive ? 'text-white' : 'text-white/45'}`}>
                            {tab.label}
                          </span>
                        </button>
                      );
                    })}
                  </div>

                  <div className="my-4 h-px bg-white/10" />

                  {/* Content Area */}
                  <div className="min-h-[240px]">
                    <AnimatePresence mode="wait">
                      {activeTab === 'launcher' && (
                        <motion.div
                          key="launcher"
                          initial={false}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: -20 }}
                          transition={{ duration: 0.3 }}
                          className="grid grid-cols-3 sm:grid-cols-4 gap-4 sm:gap-x-10 sm:gap-y-6"
                        >
                          {apps.map((app, index) => (
                            <motion.div
                              key={app.name}
                              initial={false}
                              animate={{ opacity: 1, scale: 1 }}
                              transition={{ delay: index * 0.03, duration: 0.3 }}
                            >
                              <AppIcon name={app.name} gradient={app.color} />
                            </motion.div>
                          ))}
                        </motion.div>
                      )}

                      {activeTab === 'music' && (
                        <motion.div
                          key="music"
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: -20 }}
                        >
                          <MusicPlayer />
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                </div>

                <button
                  onClick={() => setIsExpanded(false)}
                  className="sr-only"
                >
                  Collapse preview
                </button>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
