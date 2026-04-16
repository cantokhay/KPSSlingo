// components/ui/sortable-header.tsx
'use client'

import { useRouter, useSearchParams } from 'next/navigation'

interface SortableHeaderProps {
  label: string
  sortKey: string
  currentOrderBy: string
  currentOrderDir: 'asc' | 'desc'
  className?: string
}

export function SortableHeader({ 
  label, 
  sortKey, 
  currentOrderBy, 
  currentOrderDir,
  className = ""
}: SortableHeaderProps) {
  const router = useRouter()
  const searchParams = useSearchParams()

  const isActive = currentOrderBy === sortKey

  function toggleSort() {
    const params = new URLSearchParams(searchParams.toString())
    
    if (isActive) {
      // Toggle direction if already active
      params.set('orderDir', currentOrderDir === 'asc' ? 'desc' : 'asc')
    } else {
      // Set new sort key
      params.set('orderBy', sortKey)
      params.set('orderDir', 'asc') // Default to asc for new key
    }
    
    params.set('page', '1')
    router.push(`?${params.toString()}`)
  }

  return (
    <button
      onClick={toggleSort}
      className={`
        group flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-ink-disabled dark:text-gray-500
        hover:text-brand-primary transition-colors focus:outline-none
        ${className}
      `}
    >
      <span className={isActive ? 'text-brand-primary' : ''}>{label}</span>
      <div className={`
        flex flex-col text-[8px] transition-opacity
        ${isActive ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}
      `}>
        <span className={isActive && currentOrderDir === 'asc' ? 'text-brand-primary' : 'text-current opacity-40'}>▲</span>
        <span className={isActive && currentOrderDir === 'desc' ? 'text-brand-primary' : 'text-current opacity-40'}>▼</span>
      </div>
    </button>
  )
}
