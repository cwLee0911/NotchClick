import { motion } from 'motion/react';
import {
  Battery,
  Bluetooth,
  ChevronDown,
  Cpu,
  Globe2,
  HardDrive,
  MemoryStick,
  Music2,
} from 'lucide-react';

export function ControlCenter() {
  const controls = [
    {
      id: 'language',
      label: 'English',
      sublabel: 'Language',
      icon: (
        <div className="w-14 h-14 rounded-full bg-teal-500/10 flex items-center justify-center">
          <div className="w-11 h-11 rounded-full border-[5px] border-teal-400 flex items-center justify-center">
            <Globe2 className="w-5 h-5 text-teal-300" />
          </div>
        </div>
      ),
      hasDropdown: true,
    },
    {
      id: 'bluetooth',
      label: 'On',
      sublabel: 'Bluetooth',
      icon: (
        <div className="w-14 h-14 rounded-full bg-blue-500/10 flex items-center justify-center">
          <div className="w-11 h-11 rounded-full border-[5px] border-blue-500 flex items-center justify-center">
            <Bluetooth className="w-5 h-5 text-blue-300" />
          </div>
        </div>
      ),
    },
    {
      id: 'music',
      label: 'Spotify',
      sublabel: 'Music',
      icon: (
        <div className="w-14 h-14 rounded-full bg-green-500/10 flex items-center justify-center">
          <div className="w-11 h-11 rounded-full border-[5px] border-green-500 flex items-center justify-center">
            <Music2 className="w-5 h-5 text-green-300" />
          </div>
        </div>
      ),
    },
  ];

  const stats = [
    {
      id: 'cpu',
      value: '19%',
      label: 'CPU',
      icon: (
        <div className="w-9 h-9 rounded-full bg-green-500/10 border-4 border-green-500/70 flex items-center justify-center">
          <Cpu className="w-4 h-4 text-green-300" />
        </div>
      ),
      cardClass: 'border-green-500/20',
    },
    {
      id: 'memory',
      value: '17.7GB',
      label: 'Memory',
      icon: (
        <div className="w-9 h-9 rounded-full bg-fuchsia-500/10 border-4 border-fuchsia-500/70 flex items-center justify-center">
          <MemoryStick className="w-4 h-4 text-fuchsia-300" />
        </div>
      ),
      cardClass: 'border-fuchsia-500/20',
    },
    {
      id: 'storage',
      value: '224GB',
      label: 'Storage',
      icon: (
        <div className="w-9 h-9 rounded-full bg-cyan-500/10 border-4 border-cyan-500/70 flex items-center justify-center">
          <HardDrive className="w-4 h-4 text-cyan-300" />
        </div>
      ),
      cardClass: 'border-cyan-500/20',
    },
    {
      id: 'battery',
      value: '50%',
      label: 'Battery',
      icon: (
        <div className="w-9 h-9 rounded-full bg-green-500/10 border-4 border-green-500/70 flex items-center justify-center">
          <Battery className="w-4 h-4 text-green-300" />
        </div>
      ),
      cardClass: 'border-green-500/20',
    },
  ];

  return (
    <div className="relative space-y-5">
      {/* Top Row - Main Controls */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
        {controls.map((control, index) => (
          <motion.div
            key={control.id}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.05, duration: 0.3 }}
            role="button"
            tabIndex={0}
            className="relative rounded-2xl border border-white/10 bg-white/5 p-4 transition-all duration-300 hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-white/15"
          >
            <div className="flex flex-col items-center gap-2.5">
              {control.icon}
              <div className="text-center">
                <div className="flex items-center gap-1 justify-center">
                  <span className="text-sm text-white font-semibold">{control.label}</span>
                  {control.hasDropdown && (
                    <ChevronDown className="w-3 h-3 text-white/60" />
                  )}
                </div>
                <span className="text-xs text-white/50">{control.sublabel}</span>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="flex items-center gap-4 pt-1">
        <div className="min-w-0">
          <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-white/45">
            System Status
          </div>
          <div className="mt-1 text-xs text-white/35">
            CPU, memory, storage, and battery at a glance.
          </div>
        </div>
        <div className="hidden sm:block h-px flex-1 bg-white/10" />
      </div>

      {/* Bottom Row - Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {stats.map((stat, index) => (
          <motion.div
            key={stat.id}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.15 + index * 0.05, duration: 0.3 }}
            className={`relative bg-white/5 rounded-2xl p-4 border ${stat.cardClass}`}
          >
            <div className="flex items-center gap-3">
              {stat.icon}
              <div>
                <div className="text-sm sm:text-base text-white font-semibold">{stat.value}</div>
                <div className="text-xs text-white/50 font-medium">{stat.label}</div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
