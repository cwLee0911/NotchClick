import { motion } from 'motion/react';
import {
  Battery,
  ChevronDown,
  Cpu,
  Globe2,
  HardDrive,
  MemoryStick,
} from 'lucide-react';

export function ControlCenter() {
  const cards = [
    {
      id: 'language',
      value: 'English',
      label: 'Language',
      cardClass: 'border-teal-500/20',
      icon: (
        <div className="grid h-9 w-9 place-items-center rounded-full bg-teal-500/10">
          <div className="grid h-7 w-7 place-items-center rounded-full border-[3px] border-teal-400">
            <Globe2 className="h-3.5 w-3.5 text-teal-300" />
          </div>
        </div>
      ),
      hasDropdown: true,
    },
    {
      id: 'cpu',
      value: '19%',
      label: 'CPU',
      cardClass: 'border-green-500/20',
      icon: (
        <div className="grid h-9 w-9 place-items-center rounded-full bg-green-500/10">
          <div className="grid h-7 w-7 place-items-center rounded-full border-[3px] border-green-500/70">
            <Cpu className="h-3.5 w-3.5 text-green-300" />
          </div>
        </div>
      ),
    },
    {
      id: 'memory',
      value: '17.7GB',
      label: 'Memory',
      cardClass: 'border-fuchsia-500/20',
      icon: (
        <div className="grid h-9 w-9 place-items-center rounded-full bg-fuchsia-500/10">
          <div className="grid h-7 w-7 place-items-center rounded-full border-[3px] border-fuchsia-500/70">
            <MemoryStick className="h-3.5 w-3.5 text-fuchsia-300" />
          </div>
        </div>
      ),
    },
    {
      id: 'storage',
      value: '224GB',
      label: 'Storage',
      cardClass: 'border-cyan-500/20',
      icon: (
        <div className="grid h-9 w-9 place-items-center rounded-full bg-cyan-500/10">
          <div className="grid h-7 w-7 place-items-center rounded-full border-[3px] border-cyan-500/70">
            <HardDrive className="h-3.5 w-3.5 text-cyan-300" />
          </div>
        </div>
      ),
    },
    {
      id: 'battery',
      value: '50%',
      label: 'Battery',
      cardClass: 'border-green-500/20',
      icon: (
        <div className="grid h-9 w-9 place-items-center rounded-full bg-green-500/10">
          <div className="grid h-7 w-7 place-items-center rounded-full border-[3px] border-green-500/70">
            <Battery className="h-3.5 w-3.5 text-green-300" />
          </div>
        </div>
      ),
    },
  ];

  return (
    <div className="relative">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-5">
        {cards.map((card, index) => (
          <motion.div
            key={card.id}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.05, duration: 0.3 }}
            className={`relative min-h-[96px] rounded-2xl border ${card.cardClass} bg-white/5 p-3 transition-all duration-300 hover:bg-white/10`}
          >
            <div className="flex h-full flex-col items-center justify-center gap-2">
              {card.icon}
              <div className="text-center">
                <div className="flex items-center justify-center gap-1">
                  <span className="max-w-[82px] truncate text-sm font-semibold text-white">
                    {card.value}
                  </span>
                  {card.hasDropdown && (
                    <ChevronDown className="h-3 w-3 shrink-0 text-white/60" />
                  )}
                </div>
                <div className="text-[11px] font-medium uppercase text-white/45">
                  {card.label}
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
