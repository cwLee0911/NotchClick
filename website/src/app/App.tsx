import { Hero } from './components/Hero';
import { NotchDemo } from './components/NotchDemo';
import logoImage from '../imports/image.png';

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
        <section id="preview" className="pb-24">
          <NotchDemo />
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
