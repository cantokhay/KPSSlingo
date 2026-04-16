// components/questions/question-preview-popover.tsx
'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

interface Option {
  label: string
  body: string
}

interface QuestionPreviewPopoverProps {
  body: string
  explanation: string | null
  options: Option[]
  trigger: React.ReactNode
}

export function QuestionPreviewPopover({ body, explanation, options, trigger }: QuestionPreviewPopoverProps) {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div className="relative inline-block">
      <div onClick={() => setIsOpen(!isOpen)} className="cursor-pointer">
        {trigger}
      </div>

      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop for closing */}
            <div 
              className="fixed inset-0 z-[60]" 
              onClick={() => setIsOpen(false)} 
            />
            
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[70] w-[90%] max-w-[500px] bg-white dark:bg-gray-900 border border-slate-200 dark:border-gray-800 rounded-[32px] shadow-2xl overflow-hidden p-8"
            >
              <div className="flex items-center justify-between mb-4 border-b border-slate-100 dark:border-gray-800 pb-3">
                <span className="text-[11px] font-black text-brand-primary uppercase tracking-widest">Soru Önizleme</span>
                <button onClick={() => setIsOpen(false)} className="text-ink-disabled hover:text-semantic-error text-xs">✕</button>
              </div>

              <div className="space-y-4 max-h-[400px] overflow-y-auto pr-2 custom-scrollbar">
                {/* Soru Metni */}
                <div>
                   <p className="text-sm font-bold text-ink-primary dark:text-gray-100 leading-relaxed">
                     {body}
                   </p>
                </div>

                {/* Seçenekler */}
                <div className="grid gap-2">
                  {options.sort((a,b) => a.label.localeCompare(b.label)).map((opt) => (
                    <div key={opt.label} className="flex gap-3 p-3 rounded-xl bg-slate-50 dark:bg-gray-800 border border-slate-100 dark:border-gray-700">
                      <span className="w-6 h-6 rounded-lg bg-brand-primary/10 text-brand-primary flex items-center justify-center text-[10px] font-black shrink-0">
                        {opt.label}
                      </span>
                      <p className="text-xs font-semibold text-ink-secondary dark:text-gray-300">
                        {opt.body}
                      </p>
                    </div>
                  ))}
                </div>

                {/* Açıklama */}
                {explanation && (
                  <div className="mt-4 p-4 rounded-xl bg-semantic-success/5 border border-semantic-success/10">
                    <p className="text-[10px] font-black text-semantic-success uppercase tracking-widest mb-1">Cevap Açıklaması</p>
                    <p className="text-[11px] font-medium text-ink-secondary dark:text-gray-400 italic">
                      {explanation}
                    </p>
                  </div>
                )}
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  )
}
