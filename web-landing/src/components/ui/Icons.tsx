type IconProps = { size?: number; stroke?: string; fill?: string }

export const Icon = {
  Cleaning: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 3l-2 2 5 5 2-2-5-5z" />
      <path d="M12 5l-7 7v5h5l7-7" />
      <path d="M5 17l-2 4h6l-1-4" />
    </svg>
  ),
  Plumbing: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 3v6M15 3v6M7 9h10v3a5 5 0 0 1-10 0z" />
      <path d="M12 14v7M9 21h6" />
    </svg>
  ),
  Electrical: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z" />
    </svg>
  ),
  AC: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="9" rx="2" />
      <path d="M7 14v2M12 14v3M17 14v2M5 19l1.5-1.5M18.5 17.5L20 19" />
    </svg>
  ),
  Carpentry: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 4l6 6-3 3-6-6 3-3z" />
      <path d="M11 7l-7 7v6h6l7-7" />
    </svg>
  ),
  Painting: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="14" height="6" rx="1" />
      <path d="M17 6h3v5H10v3h2v7h-2" />
    </svg>
  ),
  Moving: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="6" width="11" height="10" rx="1" />
      <path d="M13 9h5l3 4v3h-8z" />
      <circle cx="7" cy="18" r="2" /><circle cx="17" cy="18" r="2" />
    </svg>
  ),
  Shield: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 2l8 3v6c0 5-3.5 9-8 11-4.5-2-8-6-8-11V5z" />
      <path d="M9 12l2 2 4-4" />
    </svg>
  ),
  Bolt: ({ size = 24, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z" />
    </svg>
  ),
  Star: ({ size = 16, stroke = 'currentColor', filled = true }: IconProps & { filled?: boolean }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? stroke : 'none'} stroke={stroke} strokeWidth="1.6" strokeLinejoin="round">
      <path d="M12 3l2.9 5.9 6.6.9-4.8 4.6 1.1 6.5L12 17.8 6.2 20.9 7.3 14.4 2.5 9.8l6.6-.9z" />
    </svg>
  ),
  Pin: ({ size = 18, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 21s7-7 7-12a7 7 0 0 0-14 0c0 5 7 12 7 12z" /><circle cx="12" cy="9" r="2.5" />
    </svg>
  ),
  Clock: ({ size = 18, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round">
      <circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" />
    </svg>
  ),
  Check: ({ size = 18, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 12l5 5L20 6" />
    </svg>
  ),
  CheckCircle: ({ size = 22, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9" /><path d="M8 12.5l3 3 5-6" />
    </svg>
  ),
  Search: ({ size = 20, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round">
      <circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" />
    </svg>
  ),
  Calendar: ({ size = 20, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="16" rx="2" /><path d="M3 9h18M8 3v4M16 3v4" />
    </svg>
  ),
  Phone: ({ size = 18, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 16.92V20a2 2 0 0 1-2.18 2A19 19 0 0 1 2 4.18 2 2 0 0 1 4 2h3.09a2 2 0 0 1 2 1.72c.13.96.34 1.9.62 2.81a2 2 0 0 1-.45 2.11L8 10a16 16 0 0 0 6 6l1.36-1.36a2 2 0 0 1 2.11-.45c.91.28 1.85.49 2.81.62A2 2 0 0 1 22 16.92z" />
    </svg>
  ),
  Mail: ({ size = 18, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="14" rx="2" /><path d="M3 7l9 6 9-6" />
    </svg>
  ),
  Lock: ({ size = 18, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="11" width="16" height="10" rx="2" /><path d="M8 11V7a4 4 0 0 1 8 0v4" />
    </svg>
  ),
  Arrow: ({ size = 18, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  ),
  ChevronDown: ({ size = 14, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.8" strokeLinecap="round">
      <path d="M6 9l6 6 6-6" />
    </svg>
  ),
  Apple: ({ size = 18, fill = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill}>
      <path d="M16.4 12.6a4.4 4.4 0 0 1 2.1-3.7 4.5 4.5 0 0 0-3.6-1.9c-1.5-.2-3 .9-3.7.9-.8 0-2-.9-3.3-.8a4.7 4.7 0 0 0-4 2.4c-1.7 3-.4 7.4 1.3 9.8.8 1.2 1.7 2.5 3 2.5 1.2-.1 1.6-.8 3.1-.8s1.9.8 3.2.7c1.3 0 2.2-1.2 3-2.4a10 10 0 0 0 1.4-2.8 4.3 4.3 0 0 1-2.5-3.9zM14 5.4a4.3 4.3 0 0 0 1-3.4 4.4 4.4 0 0 0-2.9 1.5 4 4 0 0 0-1 3.3 3.6 3.6 0 0 0 2.9-1.4z" />
    </svg>
  ),
  Play: ({ size = 18, fill = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill}>
      <path d="M5 3l16 9-16 9z" />
    </svg>
  ),
  Instagram: ({ size = 18, stroke = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke} strokeWidth="1.6">
      <rect x="3" y="3" width="18" height="18" rx="5" /><circle cx="12" cy="12" r="4" /><circle cx="17.5" cy="6.5" r="1" fill={stroke} />
    </svg>
  ),
  X: ({ size = 18, fill = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill}>
      <path d="M18 3h3l-7 8 8 10h-6l-5-6-5 6H3l7-8L2 3h6l4 5z" />
    </svg>
  ),
  LinkedIn: ({ size = 18, fill = 'currentColor' }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill}>
      <rect x="2" y="2" width="20" height="20" rx="3" />
      <path fill="#1B4F72" d="M7 10h2v8H7zM8 7.2a1.2 1.2 0 1 1 0 2.4 1.2 1.2 0 0 1 0-2.4zM11 10h2v1.1c.4-.6 1.2-1.3 2.5-1.3 2 0 2.5 1.3 2.5 3V18h-2v-4.4c0-1.1-.4-1.7-1.4-1.7s-1.6.7-1.6 1.7V18h-2z" />
    </svg>
  ),
  Verified: ({ size = 16 }: IconProps) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path d="M12 2l2.4 1.6L17 3l1 2.6L20 7l-.4 3 1 2.6-2 1.5-1 2.6-2.6.4L12 19l-2.4-1.4L7 17l-1-2.4-2-1.6 1-2.6L4 7l2-1.4L7 3l2.6.6z" fill="#F39C12" />
      <path d="M8.5 12l2.5 2.5L15.5 10" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </svg>
  ),
}
