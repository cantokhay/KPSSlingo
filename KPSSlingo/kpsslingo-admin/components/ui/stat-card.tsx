// components/ui/stat-card.tsx
import Link from 'next/link'

interface StatCardProps {
  label: string
  value: number | string
  icon: string
  accent: 'primary' | 'success' | 'warning' | 'error'
  href?: string
}

const accentConfig = {
  primary: 'bg-brand-primary/10 text-brand-primary border-brand-primary/20',
  success: 'bg-semantic-success/10 text-semantic-success border-semantic-success/20',
  warning: 'bg-semantic-warning/10 text-semantic-warning border-semantic-warning/20',
  error:   'bg-semantic-error/10 text-semantic-error border-semantic-error/20',
}

export function StatCard({ label, value, icon, accent, href }: StatCardProps) {
  const content = (
    <div className={`
      p-5 rounded-card border transition-all duration-200 bg-surface
      ${href ? 'hover:shadow-md hover:border-brand-primary/40' : ''}
      ${accentConfig[accent]}
    `}>
      <div className="flex items-center justify-between mb-3">
        <span className="text-2xl">{icon}</span>
        <span className="text-xs font-bold uppercase tracking-wider opacity-80">
          {label}
        </span>
      </div>
      <div className="text-2xl sm:text-3xl font-extrabold text-ink-primary tracking-tight">
        {value}
      </div>
    </div>
  )

  if (href) {
    return (
      <Link href={href} className="block no-underline">
        {content}
      </Link>
    )
  }

  return content
}
