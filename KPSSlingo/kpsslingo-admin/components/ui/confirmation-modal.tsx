'use client'

import { motion, AnimatePresence } from 'framer-motion'
import { useState, useEffect } from 'react'

interface ConfirmationModalProps {
  isOpen: boolean
  onClose: () => void
  onConfirm: () => void
  title: string
  message: string
  confirmText?: string
  cancelText?: string
  variant?: 'danger' | 'success' | 'info'
  isLoading?: boolean
}

export function ConfirmationModal({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Onayla',
  cancelText = 'Vazgeç',
  variant = 'info',
  isLoading = false
}: ConfirmationModalProps) {
  // Prevent scrolling when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = 'unset'
    }
    return () => {
      document.body.style.overflow = 'unset'
    }
  }, [isOpen])

  const buttonClasses = {
    danger: 'bg-semantic-error text-white shadow-lg shadow-semantic-error/20 hover:bg-semantic-error/90',
    success: 'bg-semantic-success text-white shadow-lg shadow-semantic-success/20 hover:bg-semantic-success/90',
    info: 'bg-brand-primary text-white shadow-lg shadow-brand-primary/20 hover:bg-brand-primary/90'
  }

  const iconColors = {
    danger: 'text-semantic-error bg-semantic-error/10',
    success: 'text-semantic-success bg-semantic-success/10',
    info: 'text-brand-primary bg-brand-primary/10'
  }

  const icons = {
    danger: '⚠️',
    success: '✅',
    info: 'ℹ️'
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-ink-primary/40 backdrop-blur-sm"
          />

          {/* Modal */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            className="relative w-full max-w-md bg-surface border border-ink-disabled/10 rounded-[32px] p-8 shadow-2xl overflow-hidden"
          >
            <div className="text-center">
              <div className={`inline-flex items-center justify-center w-16 h-16 rounded-2xl mb-6 text-3xl ${iconColors[variant]}`}>
                {icons[variant]}
              </div>
              
              <h3 className="text-2xl font-extrabold text-ink-primary tracking-tight mb-2">
                {title}
              </h3>
              
              <p className="text-ink-secondary text-sm font-medium leading-relaxed mb-8 px-4">
                {message}
              </p>

              <div className="flex flex-col sm:flex-row gap-3">
                <button
                  onClick={onClose}
                  disabled={isLoading}
                  className="flex-1 px-6 py-3.5 rounded-2xl text-sm font-bold text-ink-secondary bg-surface-alt border border-ink-disabled/10 hover:bg-ink-disabled/5 transition-all disabled:opacity-50"
                >
                  {cancelText}
                </button>
                <button
                  onClick={onConfirm}
                  disabled={isLoading}
                  className={`flex-1 px-6 py-3.5 rounded-2xl text-sm font-bold transition-all hover:-translate-y-0.5 active:translate-y-0 disabled:opacity-50 flex items-center justify-center gap-2 ${buttonClasses[variant]}`}
                >
                  {isLoading ? (
                    <>
                      <span className="animate-spin text-lg">⏳</span>
                      <span>İşleniyor...</span>
                    </>
                  ) : (
                    confirmText
                  )}
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  )
}
