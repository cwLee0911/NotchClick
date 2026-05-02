import { motion } from 'motion/react';

interface AppIconProps {
  name: string;
  gradient?: string;
}

type GlyphName =
  | 'apps'
  | 'calendar'
  | 'text'
  | 'document'
  | 'audio'
  | 'star'
  | 'message'
  | 'note'
  | 'tasks'
  | 'terminal'
  | 'code'
  | 'plus';

const iconMap: Record<string, GlyphName> = {
  Calculator: 'apps',
  Calendar: 'calendar',
  Talk: 'text',
  Notion: 'document',
  Spotify: 'audio',
  MindNode: 'star',
  Messages: 'message',
  Notes: 'note',
  Reminders: 'tasks',
  Terminal: 'terminal',
  Atom: 'code',
  Add: 'plus',
};

const accentMap: Record<GlyphName, string> = {
  apps: '#a78bfa',
  calendar: '#fb7185',
  text: '#fbbf24',
  document: '#e5e7eb',
  audio: '#34d399',
  star: '#c084fc',
  message: '#4ade80',
  note: '#fde68a',
  tasks: '#93c5fd',
  terminal: '#5eead4',
  code: '#67e8f9',
  plus: '#d8b4fe',
};

function Glyph({ name }: { name: GlyphName }) {
  const common = {
    fill: 'none',
    stroke: 'currentColor',
    strokeWidth: 2.15,
    strokeLinecap: 'round' as const,
    strokeLinejoin: 'round' as const,
  };

  switch (name) {
    case 'apps':
      return (
        <>
          <rect x="8" y="8" width="6" height="6" rx="2" {...common} />
          <rect x="17" y="8" width="6" height="6" rx="2" {...common} />
          <rect x="26" y="8" width="6" height="6" rx="2" {...common} />
          <rect x="8" y="17" width="6" height="6" rx="2" {...common} />
          <rect x="17" y="17" width="6" height="6" rx="2" {...common} />
          <rect x="26" y="17" width="6" height="6" rx="2" {...common} />
          <rect x="8" y="26" width="6" height="6" rx="2" {...common} />
          <rect x="17" y="26" width="6" height="6" rx="2" {...common} />
          <rect x="26" y="26" width="6" height="6" rx="2" {...common} />
        </>
      );
    case 'calendar':
      return (
        <>
          <rect x="8" y="9" width="24" height="23" rx="6" {...common} />
          <path d="M13 7v5M27 7v5M8 16h24" {...common} />
          <path d="M15 22h3M22 22h3M15 27h3M22 27h3" {...common} />
        </>
      );
    case 'text':
      return (
        <>
          <path d="M11 11h18M11 17h14M11 23h18M11 29h10" {...common} />
          <path d="M29 24v8" {...common} />
        </>
      );
    case 'document':
      return (
        <>
          <path d="M13 7h11l7 7v19H13Z" {...common} />
          <path d="M24 7v8h7M17 20h10M17 25h10M17 30h6" {...common} />
        </>
      );
    case 'audio':
      return (
        <>
          <path d="M11 23h5l7 6V11l-7 6h-5Z" {...common} />
          <path d="M27 16.5c1.7 2.1 1.7 4.9 0 7M31 13c3.2 4.3 3.2 9.7 0 14" {...common} />
        </>
      );
    case 'star':
      return <path d="m20 7 4.1 8.4 9.2 1.3-6.6 6.5 1.6 9.1L20 28l-8.3 4.3 1.6-9.1-6.6-6.5 9.2-1.3Z" {...common} />;
    case 'message':
      return (
        <>
          <path d="M8 18.8C8 12.9 13.1 9 20 9s12 3.9 12 9.8-5.1 9.8-12 9.8c-1.7 0-3.2-.2-4.6-.7L9.5 31l2-5.1C9.3 24.1 8 21.6 8 18.8Z" {...common} />
          <path d="M15 18h10M15 23h6" {...common} />
        </>
      );
    case 'note':
      return (
        <>
          <rect x="10" y="7" width="20" height="26" rx="5" {...common} />
          <path d="M14 14h12M14 20h12M14 26h8" {...common} />
        </>
      );
    case 'tasks':
      return (
        <>
          <path d="m10 13 2 2 4-5M10 22l2 2 4-5M10 31l2 2 4-5" {...common} />
          <path d="M21 14h10M21 23h10M21 32h10" {...common} />
        </>
      );
    case 'terminal':
      return (
        <>
          <rect x="8" y="9" width="24" height="22" rx="5" {...common} />
          <path d="m14 18 5 4-5 4M21 26h7" {...common} />
        </>
      );
    case 'code':
      return (
        <>
          <path d="m15 13-7 7 7 7M25 13l7 7-7 7" {...common} />
          <path d="m22 10-4 20" {...common} />
        </>
      );
    case 'plus':
      return <path d="M20 10v20M10 20h20" {...common} />;
    default:
      return null;
  }
}

export function AppIcon({ name }: AppIconProps) {
  const glyph = iconMap[name] ?? 'apps';
  const isAdd = glyph === 'plus';
  const accent = accentMap[glyph];

  return (
    <motion.div
      whileHover={{ scale: 1.06, y: -2 }}
      whileTap={{ scale: 0.96 }}
      className="flex flex-col items-center cursor-pointer group"
      aria-label={isAdd ? 'Add app' : name}
    >
      <div
        className={`relative flex h-14 w-14 items-center justify-center overflow-hidden rounded-[14px] ${
          isAdd ? 'border-2 border-dashed border-white/24 bg-white/[.025]' : 'border border-white/10 bg-white/[.055]'
        }`}
        style={{
          color: isAdd ? 'rgba(255,255,255,.58)' : accent,
          boxShadow:
            '0 12px 24px rgba(0,0,0,.22), inset 0 1px 0 rgba(255,255,255,.12), inset 0 -10px 20px rgba(0,0,0,.08)',
        }}
      >
        <div
          className="absolute inset-0 opacity-80"
          style={{
            background: isAdd
              ? 'linear-gradient(135deg, rgba(255,255,255,.08), rgba(255,255,255,0) 48%, rgba(167,139,250,.08))'
              : `radial-gradient(circle at 28% 18%, rgba(255,255,255,.16), transparent 36%), radial-gradient(circle at 74% 78%, ${accent}24, transparent 48%)`,
          }}
        />
        <svg className="relative h-8 w-8" viewBox="0 0 40 40" aria-hidden="true">
          <Glyph name={glyph} />
        </svg>
      </div>
    </motion.div>
  );
}
