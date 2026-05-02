import { Hero } from './components/Hero';
import { NotchDemo } from './components/NotchDemo';
import logoImage from '../imports/image.png';
import {
  Battery,
  Bluetooth,
  Grid2X2Plus,
  Languages,
  type LucideIcon,
} from 'lucide-react';

const features: Array<{
  icon: LucideIcon;
  title: string;
  description: string;
  color: string;
  background: string;
}> = [
  {
    icon: Battery,
    title: 'Low Power Mode',
    description: 'Click Battery to turn on Low Power Mode without digging through settings.',
    color: '#10b981',
    background: 'rgba(16, 185, 129, 0.12)',
  },
  {
    icon: Grid2X2Plus,
    title: 'Quick Launcher',
    description: 'Add the apps you want and open them quickly from the expanded notch.',
    color: '#a855f7',
    background: 'rgba(168, 85, 247, 0.12)',
  },
  {
    icon: Languages,
    title: 'Language Switch',
    description: 'Change your language directly from the notch whenever you need it.',
    color: '#14b8a6',
    background: 'rgba(20, 184, 166, 0.12)',
  },
  {
    icon: Bluetooth,
    title: 'Bluetooth Control',
    description: 'Click Bluetooth to connect and manage nearby devices from the notch.',
    color: '#3b82f6',
    background: 'rgba(59, 130, 246, 0.12)',
  },
];

function FeatureCard({ feature }: { feature: (typeof features)[number] }) {
  const Icon = feature.icon;

  return (
    <div className="rounded-[28px] bg-white/72 border border-white/80 shadow-[0_18px_45px_rgba(30,23,64,0.08)] px-8 py-9 backdrop-blur-sm">
      <div
        className="mb-8 grid h-14 w-14 place-items-center rounded-2xl"
        style={{ background: feature.background }}
      >
        <Icon className="h-8 w-8" style={{ color: feature.color }} strokeWidth={2.1} />
      </div>
      <h3 className="mb-5 text-[1.55rem] font-bold tracking-[-0.02em] text-black">{feature.title}</h3>
      <p className="text-[1.05rem] leading-8 text-gray-600">{feature.description}</p>
    </div>
  );
}

export default function App() {
  return (
    <div className="min-h-screen w-full max-w-[100vw] bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 overflow-x-hidden">
      {/* Background decoration */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-purple-300/30 rounded-full blur-[150px] translate-x-1/2 -translate-y-1/2" />
        <div className="absolute bottom-0 left-0 w-[600px] h-[600px] bg-blue-300/30 rounded-full blur-[150px] -translate-x-1/2 translate-y-1/2" />
      </div>

      {/* Content */}
      <div className="relative z-10 w-full max-w-[100vw] overflow-x-hidden">
        {/* Header */}
        <header className="flex items-center px-8 py-5">
          <div className="flex items-center gap-2">
            <img src={logoImage} alt="NotchClick Logo" className="w-8 h-8 rounded-lg" />
            <span className="font-semibold text-lg">NotchClick</span>
          </div>
        </header>

        {/* Hero Section */}
        <section className="pt-8 pb-10">
          <Hero />
        </section>

        {/* Notch Demo Section */}
        <section id="preview" className="pb-20">
          <NotchDemo />
        </section>

        {/* Features Section */}
        <section id="features" className="px-8 pb-24">
          <div className="mx-auto max-w-5xl">
            <div className="mb-14 text-center">
              <h2
                className="mb-4"
                style={{
                  fontSize: 'clamp(2.25rem, 5vw, 4.25rem)',
                  fontWeight: 700,
                  lineHeight: 1.08,
                  letterSpacing: '-0.035em',
                }}
              >
                What Notch can do:
              </h2>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
              {features.map((feature) => (
                <FeatureCard key={feature.title} feature={feature} />
              ))}
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="border-t border-gray-200/50 py-12 px-8">
          <div className="max-w-6xl mx-auto text-sm text-gray-600">
            <p>© 2026 NotchClick. All rights reserved.</p>
          </div>
        </footer>
      </div>
    </div>
  );
}
