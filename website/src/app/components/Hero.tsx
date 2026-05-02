import { motion } from 'motion/react';
import { Download } from 'lucide-react';

const downloadURL = './downloads/NotchClick.dmg';

export function Hero() {
  return (
    <div className="text-center w-screen max-w-[100vw] sm:w-auto sm:max-w-5xl sm:mx-auto px-6 sm:px-8 mb-12">
      {/* Badge */}
      <motion.div
        initial={false}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-black/5 backdrop-blur-sm mb-5"
      >
        <span className="text-sm text-gray-700">macOS Notch Utility</span>
      </motion.div>

      {/* Headline */}
      <motion.h1
        initial={false}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.1 }}
        className="mb-5"
        style={{
          fontSize: 'clamp(2.25rem, 7.2vw, 4.6rem)',
          fontWeight: 700,
          lineHeight: 1.08,
          letterSpacing: '-0.035em',
          textWrap: 'balance',
        }}
      >
        Click your notch.
        <br />
        <span className="bg-gradient-to-r from-purple-600 via-violet-600 to-purple-600 bg-clip-text text-transparent">
          Get everything.
        </span>
      </motion.h1>

      {/* Buttons */}
      <motion.div
        initial={false}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
        className="flex flex-col sm:flex-row items-center justify-center gap-4"
      >
        <a
          href={downloadURL}
          download="NotchClick.dmg"
          className="group inline-flex w-full max-w-[340px] sm:min-w-[360px] items-center justify-center gap-2 px-10 py-4 bg-black text-white rounded-full hover:bg-gray-800 transition-all duration-300 shadow-lg hover:shadow-xl"
        >
          <Download className="w-5 h-5" />
          <span className="font-medium">Download DMG</span>
        </a>
      </motion.div>
    </div>
  );
}
