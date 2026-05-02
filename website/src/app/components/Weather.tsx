import { motion } from 'motion/react';
import { Sun, Cloud, CloudRain, Droplets, Wind } from 'lucide-react';

export function Weather() {
  const hourlyForecast = [
    { time: 'Now', temp: '14°', icon: 'sun' },
    { time: '4pm', temp: '14°', icon: 'sun' },
    { time: '5pm', temp: '14°', icon: 'sun' },
    { time: '6pm', temp: '14°', icon: 'sun' },
    { time: '7pm', temp: '13°', icon: 'sun' },
    { time: '8pm', temp: '12°', icon: 'sun' },
    { time: '9pm', temp: '12°', icon: 'sun' },
    { time: '10pm', temp: '12°', icon: 'cloud' },
  ];

  const getWeatherIcon = (icon: string, size: 'large' | 'small' = 'small') => {
    const iconSize = size === 'large' ? 'w-9 h-9' : 'w-5 h-5';
    const iconColor = 'text-white/90';

    switch (icon) {
      case 'sun':
        return <Sun className={`${iconSize} ${iconColor}`} />;
      case 'cloud':
        return <Cloud className={`${iconSize} text-gray-400`} />;
      case 'rain':
        return <CloudRain className={`${iconSize} text-blue-400`} />;
      default:
        return <Sun className={`${iconSize} ${iconColor}`} />;
    }
  };

  return (
    <div className="space-y-3">
      {/* Current Weather */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="rounded-[24px] border border-white/10 bg-gradient-to-r from-slate-900/55 to-black/30 px-5 py-4 shadow-[inset_0_1px_0_rgba(255,255,255,.03)]"
      >
        <div className="flex items-center justify-between">
          {/* Left - Temperature */}
          <div className="flex items-center gap-4">
            <div className="grid h-16 w-16 place-items-center rounded-full bg-white/10">
              {getWeatherIcon('sun', 'large')}
            </div>
            <div>
              <div className="text-5xl text-white font-light leading-none tracking-tight">14°</div>
              <div className="mt-1 text-sm font-semibold text-white/55">Clear Sky</div>
            </div>
          </div>

          {/* Right - Location & Stats */}
          <div className="text-right">
            <div className="mb-2 text-lg font-semibold text-white">Current Location</div>
            <div className="flex items-center justify-end gap-2 text-sm font-semibold text-white/60">
              <div className="flex items-center gap-1 rounded-full bg-white/[.07] px-3 py-1.5">
                <Droplets className="h-3.5 w-3.5" />
                <span>29</span>
              </div>
              <div className="flex items-center gap-1 rounded-full bg-white/[.07] px-3 py-1.5">
                <Wind className="h-3.5 w-3.5" />
                <span>72%</span>
              </div>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Hourly Forecast */}
      <div className="grid grid-cols-4 gap-2 sm:grid-cols-8">
        {hourlyForecast.map((hour, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.15 + index * 0.03 }}
            className="flex min-h-[104px] flex-col items-center justify-center gap-2 rounded-[20px] border border-white/10 bg-white/[.045] px-2 py-3 first:bg-purple-400/[.12]"
          >
            <div className="text-sm font-semibold text-white/55">{hour.time}</div>
            <div>{getWeatherIcon(hour.icon)}</div>
            <div className="text-lg font-semibold text-white">{hour.temp}</div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
