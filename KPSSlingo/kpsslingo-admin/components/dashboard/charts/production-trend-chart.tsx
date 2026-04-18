// components/dashboard/charts/production-trend-chart.tsx
'use client'

import React, { useState, useEffect } from 'react'
import { 
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer 
} from 'recharts'

interface ProductionTrendChartProps {
  data: { date: string; count: number }[]
}

export function ProductionTrendChart({ data }: ProductionTrendChartProps) {
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])

  if (!isMounted) return <div className="h-[280px] w-full" />

  return (
    <div className="h-[280px] w-full mt-4 block relative">
      <ResponsiveContainer width="100%" height="100%" minWidth={0}>
        <AreaChart data={data}>
          <defs>
            <linearGradient id="colorCount" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#2D66FF" stopOpacity={0.1}/>
              <stop offset="95%" stopColor="#2D66FF" stopOpacity={0}/>
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="currentColor" className="text-ink-disabled/10" />
          <XAxis 
            dataKey="date" 
            axisLine={false} 
            tickLine={false} 
            tick={{ fontSize: 10, fontWeight: 700, fill: 'currentColor' }}
            className="text-ink-disabled"
            dy={10}
          />
          <YAxis 
            axisLine={false} 
            tickLine={false} 
            tick={{ fontSize: 10, fontWeight: 700, fill: 'currentColor' }}
            className="text-ink-disabled"
          />
          <Tooltip 
            contentStyle={{ 
              borderRadius: '16px', 
              border: '1px solid var(--ink-disabled-alpha-10, rgba(148, 163, 184, 0.1))', 
              backgroundColor: 'var(--surface)',
              boxShadow: '0 10px 25px -5px rgba(0,0,0,0.2)',
              fontSize: '11px',
              fontWeight: 700,
              padding: '8px 12px'
            }}
            itemStyle={{ color: 'var(--ink-primary)', padding: '2px 0' }}
            labelStyle={{ color: 'var(--ink-secondary)', marginBottom: '4px' }}
          />
          <Area 
            type="monotone" 
            dataKey="count" 
            name="Üretilen Soru"
            stroke="#2D66FF" 
            strokeWidth={3}
            fillOpacity={1} 
            fill="url(#colorCount)" 
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}
