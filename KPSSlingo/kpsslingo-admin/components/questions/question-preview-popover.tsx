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
  correctOption: string | null
  trigger: React.ReactNode
}

export function QuestionPreviewPopover({ body, explanation, options, correctOption, trigger }: QuestionPreviewPopoverProps) {
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
              initial={{ opacity: 0, x: 20, scale: 0.95 }}
              animate={{ opacity: 1, x: 0, scale: 1 }}
              exit={{ opacity: 0, x: 20, scale: 0.95 }}
              className="absolute bottom-[-100px] right-[120%] z-[70] w-[400px] md:w-[500px] bg-white dark:bg-gray-900 border border-slate-200 dark:border-gray-800 rounded-[24px] shadow-2xl overflow-hidden p-6"
            >
              <div className="flex items-center justify-between mb-4 border-b border-slate-100 dark:border-gray-800 pb-3">
                <span className="text-[11px] font-black text-brand-primary uppercase tracking-widest">Soru Bilgisi</span>
                <button onClick={() => setIsOpen(false)} className="text-ink-disabled hover:text-semantic-error text-xs">✕</button>
              </div>

              <div className="space-y-4 max-h-[500px] overflow-y-auto pr-2 custom-scrollbar">
                {/* Soru Metni */}
                <div>
                   <p className="text-sm font-bold text-ink-primary dark:text-gray-100 leading-relaxed whitespace-pre-wrap">
                     {body}
                   </p>
                </div>

                {/* Seçenekler */}
                <div className="grid gap-2">
                  {options.sort((a,b) => a.label.localeCompare(b.label)).map((opt) => {
                    const isCorrect = opt.label === correctOption
                    return (
                      <div 
                        key={opt.label} 
                        className={`
                          flex gap-3 p-3 rounded-xl border transition-all duration-300
                          ${isCorrect 
                            ? 'bg-semantic-success/10 border-semantic-success/30 shadow-sm shadow-semantic-success/5' 
                            : 'bg-slate-50 dark:bg-gray-800 border-slate-100 dark:border-gray-700'
                          }
                        `}
                      >
                        <span className={`
                          w-6 h-6 rounded-lg flex items-center justify-center text-[10px] font-black shrink-0
                          ${isCorrect ? 'bg-semantic-success text-white' : 'bg-brand-primary/10 text-brand-primary'}
                        `}>
                          {opt.label}
                        </span>
                        <div className="flex-1">
                          <p className={`
                            text-xs font-semibold
                            ${isCorrect ? 'text-semantic-success' : 'text-ink-secondary dark:text-gray-300'}
                          `}>
                            {opt.body}
                          </p>
                          {isCorrect && (
                            <span className="text-[9px] font-black uppercase text-semantic-success/60 tracking-tighter">Doğru Cevap</span>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>

                {/* Açıklama */}
                {explanation && (
                  <div className="mt-4 p-4 rounded-xl bg-semantic-success/5 border border-semantic-success/10">
                    <p className="text-[10px] font-black text-semantic-success uppercase tracking-widest mb-1">Çözüm / Açıklama</p>
                    <p className="text-[11px] font-medium text-ink-secondary dark:text-gray-400 italic leading-relaxed">
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
