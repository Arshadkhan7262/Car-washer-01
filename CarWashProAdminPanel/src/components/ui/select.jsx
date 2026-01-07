import * as React from "react"
import { cn } from "@/lib/utils"
import { ChevronDown } from "lucide-react"

const SelectContext = React.createContext()

const Select = ({ value, onValueChange, children }) => {
  const [isOpen, setIsOpen] = React.useState(false)
  const triggerRef = React.useRef(null)
  const contentRef = React.useRef(null)

  // Close on outside click
  React.useEffect(() => {
    if (!isOpen) return

    const handleClickOutside = (event) => {
      if (
        triggerRef.current &&
        contentRef.current &&
        !triggerRef.current.contains(event.target) &&
        !contentRef.current.contains(event.target)
      ) {
        setIsOpen(false)
      }
    }

    const handleEscape = (e) => {
      if (e.key === 'Escape') {
        setIsOpen(false)
      }
    }

    // Use setTimeout to avoid immediate closure
    setTimeout(() => {
      document.addEventListener('mousedown', handleClickOutside, true)
      document.addEventListener('keydown', handleEscape, true)
    }, 0)

    return () => {
      document.removeEventListener('mousedown', handleClickOutside, true)
      document.removeEventListener('keydown', handleEscape, true)
    }
  }, [isOpen])

  const handleValueChange = (newValue) => {
    onValueChange?.(newValue)
    setIsOpen(false) // Close dropdown when value is selected
  }

  return (
    <SelectContext.Provider value={{ value, onValueChange: handleValueChange, isOpen, setIsOpen, triggerRef, contentRef }}>
      {children}
    </SelectContext.Provider>
  )
}

const SelectTrigger = React.forwardRef(({ className, children, ...props }, ref) => {
  const { value, isOpen, setIsOpen, triggerRef } = React.useContext(SelectContext)
  const combinedRef = React.useRef(null)
  
  React.useEffect(() => {
    if (ref) {
      if (typeof ref === 'function') {
        ref(combinedRef.current)
      } else {
        ref.current = combinedRef.current
      }
    }
    if (triggerRef) {
      triggerRef.current = combinedRef.current
    }
  }, [ref, triggerRef])

  return (
    <button
      ref={combinedRef}
      type="button"
      className={cn(
        "flex h-10 w-full items-center justify-between rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 ring-offset-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-0 focus:border-blue-500 disabled:cursor-not-allowed disabled:opacity-50 transition-all",
        isOpen && "border-blue-500 ring-2 ring-blue-500",
        className
      )}
      onClick={(e) => {
        e.preventDefault()
        e.stopPropagation()
        setIsOpen(!isOpen)
      }}
      {...props}
    >
      <span className="flex-1 text-left truncate">
        {children || <SelectValue />}
      </span>
      <ChevronDown className={cn("h-4 w-4 text-slate-400 ml-2 flex-shrink-0 transition-transform duration-200", isOpen && "rotate-180 text-slate-600")} />
    </button>
  )
})
SelectTrigger.displayName = "SelectTrigger"

const SelectValue = ({ placeholder = "Select...", children }) => {
  const { value } = React.useContext(SelectContext)
  // If children are provided, use them (for custom display)
  if (children) {
    return <span className="truncate">{children}</span>
  }
  // Otherwise show the value or placeholder
  return <span className="truncate">{value || placeholder}</span>
}
SelectValue.displayName = "SelectValue"

const SelectContent = React.forwardRef(({ className, children, ...props }, ref) => {
  const { isOpen, contentRef, triggerRef } = React.useContext(SelectContext)
  const combinedRef = React.useRef(null)
  const [position, setPosition] = React.useState({ top: 0, left: 0 })

  React.useEffect(() => {
    if (ref) {
      if (typeof ref === 'function') {
        ref(combinedRef.current)
      } else {
        ref.current = combinedRef.current
      }
    }
    if (contentRef) {
      contentRef.current = combinedRef.current
    }
  }, [ref, contentRef])

  // Position the dropdown relative to trigger
  React.useEffect(() => {
    if (isOpen && triggerRef?.current) {
      const updatePosition = () => {
        if (triggerRef?.current) {
          const trigger = triggerRef.current
          const rect = trigger.getBoundingClientRect()
          // For fixed positioning, use viewport coordinates directly (no scroll offset)
          setPosition({
            top: rect.bottom + 4, // 4px gap below trigger
            left: rect.left
          })
        }
      }
      
      // Initial position
      updatePosition()
      
      // Update on scroll/resize
      window.addEventListener('scroll', updatePosition, true)
      window.addEventListener('resize', updatePosition)
      
      return () => {
        window.removeEventListener('scroll', updatePosition, true)
        window.removeEventListener('resize', updatePosition)
      }
    }
  }, [isOpen, triggerRef])

  const { setIsOpen } = React.useContext(SelectContext)

  if (!isOpen) return null

  return (
    <>
      <div
        className="fixed inset-0 z-40"
        onClick={() => setIsOpen(false)}
      />
      <div
        ref={combinedRef}
        className={cn(
          "fixed z-[9999] min-w-[8rem] overflow-hidden rounded-lg border border-slate-200 bg-white text-slate-950 shadow-xl",
          className
        )}
        style={{
          top: `${position.top}px`,
          left: `${position.left}px`
        }}
        onClick={(e) => e.stopPropagation()}
        {...props}
      >
        <div className="max-h-[300px] overflow-auto p-1.5">
          {children}
        </div>
      </div>
    </>
  )
})
SelectContent.displayName = "SelectContent"

const SelectItem = React.forwardRef(({ className, children, value, ...props }, ref) => {
  const { onValueChange, value: selectedValue } = React.useContext(SelectContext)
  const isSelected = selectedValue === value
  return (
    <div
      ref={ref}
      className={cn(
        "relative flex w-full cursor-pointer select-none items-center rounded-md py-2 px-3 text-sm outline-none transition-colors",
        "hover:bg-slate-100 focus:bg-slate-100",
        isSelected && "bg-blue-50 text-blue-700 font-medium hover:bg-blue-100",
        "data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
        className
      )}
      onClick={(e) => {
        e.preventDefault()
        e.stopPropagation()
        onValueChange?.(value)
      }}
      {...props}
    >
      {children}
      {isSelected && (
        <svg className="ml-auto h-4 w-4 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
        </svg>
      )}
    </div>
  )
})
SelectItem.displayName = "SelectItem"

export { Select, SelectTrigger, SelectValue, SelectContent, SelectItem }






