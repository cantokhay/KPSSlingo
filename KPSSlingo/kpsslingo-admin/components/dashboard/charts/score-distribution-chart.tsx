// components/dashboard/charts/score-distribution-chart.tsx
'use client'

import React, { useState, useEffect } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell
} from 'recharts'

interface ScoreDistributionChartProps {
  data: { range: string; count: number }[]
}

// Skora göre renk döndüren yardımcı fonksiyon
const getBarColor = (range: string) => {
  if (range === '0-5.0') return '#FF4D4D' // Kritik/Düşük (Kırmızı)
  const score = parseFloat(range.split('-')[0])
  if (score < 7) return '#FFA500' // Orta (Turuncu)
  if (score < 8.5) return '#FFD700' // İyi (Sarı)
  return '#00C49F' // Mükemmel (Yeşil)
}

export function ScoreDistributionChart({ data }: ScoreDistributionChartProps) {
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])

  if (!isMounted) return <div className="h-[240px] w-full" />

  return (
    <div className="h-[240px] w-full mt-4 block relative">
      <ResponsiveContainer width="100%" height="100%" minWidth={0}>
        <BarChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 20 }}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="currentColor" className="text-ink-disabled/10" />
          <XAxis 
            dataKey="range" 
            axisLine={false} 
            tickLine={false} 
            tick={{ fontSize: 10, fontWeight: 700, fill: 'currentColor' }}
            className="text-ink-disabled"
            angle={-45}
            textAnchor="end"
            interval={0}
            height={40}
          />
          <YAxis 
            axisLine={false} 
            tickLine={false} 
            tick={{ fontSize: 10, fontWeight: 700, fill: 'currentColor' }}
            className="text-ink-disabled"
          />
          <Tooltip 
            cursor={{ fill: 'var(--brand-primary)', opacity: 0.05 }}
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
          <Bar dataKey="count" radius={[4, 4, 0, 0]}>
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={getBarColor(entry.range)} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
