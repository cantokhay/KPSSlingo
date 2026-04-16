// components/dashboard/charts/topic-distribution-chart.tsx
'use client'

import React, { useState, useEffect } from 'react'
import {
  PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend
} from 'recharts'

interface TopicDistributionChartProps {
  data: { name: string; value: number }[]
}

const COLORS = ['#2D66FF', '#00C49F', '#FFBB28', '#FF8042', '#8884d8', '#82ca9d']

export function TopicDistributionChart({ data }: TopicDistributionChartProps) {
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])

  if (!isMounted) return <div className="h-[260px] w-full" />

  return (
    <div className="h-[260px] w-full mt-4 block relative">
      <ResponsiveContainer width="100%" height="100%" minWidth={0}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={80}
            paddingAngle={5}
            dataKey="value"
            animationDuration={1500}
            cornerRadius={4}
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              borderRadius: '16px',
              border: '1px solid var(--ink-disabled-alpha-10, rgba(0,0,0,0.1))',
              backgroundColor: 'var(--surface)',
              color: 'var(--ink-primary)',
              boxShadow: '0 10px 25px -5px rgba(0,0,0,0.1)',
              fontSize: '11px',
              fontWeight: 700
            }}
          />
          <Legend
            verticalAlign="bottom"
            height={36}
            iconType="circle"
            formatter={(value) => <span className="text-[10px] font-bold text-ink-secondary">{value}</span>}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  )
}
