import * as React from "react"
import { cn } from "@/lib/utils"

const DropdownMenuContext = React.createContext()

const DropdownMenu = ({ children }) => {
  const [isOpen, setIsOpen] = React.useState(false)
  const triggerRef = React.useRef(null)
  return (
    <DropdownMenuContext.Provider value={{ isOpen, setIsOpen, triggerRef }}>
      <div className="relative">{children}</div>
    </DropdownMenuContext.Provider>
  )
}

const DropdownMenuTrigger = React.forwardRef(({ asChild, children, ...props }, ref) => {
  const { setIsOpen, triggerRef } = React.useContext(DropdownMenuContext)
  const combinedRef = React.useRef(null)
  
  React.useEffect(() => {
    if (ref) {
      if (typeof ref === 'function') {
        ref(combinedRef.current)
      } else if (ref) {
        ref.current = combinedRef.current
      }
    }
    if (triggerRef) {
      triggerRef.current = combinedRef.current
    }
  }, [ref, triggerRef])
  
  const handleClick = (e) => {
    e.stopPropagation(); // Prevent event from bubbling to document click handler
    setIsOpen(prev => !prev);
  }
  
  if (asChild) {
    return React.cloneElement(children, { 
      ref: combinedRef,
      onClick: handleClick,
      'data-dropdown-trigger': true, // Add marker for click outside detection
      ...props 
    })
  }
  return (
    <button ref={combinedRef} onClick={handleClick} data-dropdown-trigger {...props}>
      {children}
    </button>
  )
})
DropdownMenuTrigger.displayName = "DropdownMenuTrigger"

const DropdownMenuContent = React.forwardRef(({ className, align = "start", children, ...props }, ref) => {
  const { isOpen, setIsOpen, triggerRef } = React.useContext(DropdownMenuContext)
  const contentRef = React.useRef(null)
  const [position, setPosition] = React.useState({ top: 0, right: 0 })
  
  // Position the dropdown relative to trigger
  React.useEffect(() => {
    if (isOpen && triggerRef?.current) {
      const updatePosition = () => {
        if (triggerRef?.current) {
          const trigger = triggerRef.current
          const rect = trigger.getBoundingClientRect()
          if (align === "end") {
            setPosition({
              top: rect.bottom + 4,
              right: window.innerWidth - rect.right
            })
          } else {
            setPosition({
              top: rect.bottom + 4,
              left: rect.left
            })
          }
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
  }, [isOpen, align, triggerRef])
  
  React.useEffect(() => {
    const handleClickOutside = (e) => {
      // Check if click is outside both the dropdown container and the trigger button
      const isClickInDropdown = e.target.closest('.dropdown-menu-container');
      const isClickInTrigger = e.target.closest('[data-dropdown-trigger]');
      
      if (isOpen && !isClickInDropdown && !isClickInTrigger) {
        setIsOpen(false)
      }
    }
    if (isOpen) {
      // Use setTimeout to ensure this runs after the click event that opened the dropdown
      setTimeout(() => {
        document.addEventListener('click', handleClickOutside)
      }, 0)
      return () => document.removeEventListener('click', handleClickOutside)
    }
  }, [isOpen, setIsOpen])
  
  React.useEffect(() => {
    if (ref) {
      if (typeof ref === 'function') {
        ref(contentRef.current)
      } else if (ref) {
        ref.current = contentRef.current
      }
    }
  }, [ref])
  
  if (!isOpen) return null
  
  return (
    <>
      <div 
        className="fixed inset-0 z-40" 
        onClick={() => setIsOpen(false)} 
      />
      <div
        ref={contentRef}
        className={cn(
          "dropdown-menu-container fixed z-50 min-w-[8rem] overflow-hidden rounded-md border border-slate-200 bg-white p-1 text-slate-950 shadow-md",
          className
        )}
        style={{
          top: `${position.top}px`,
          ...(align === "end" ? { right: `${position.right}px` } : { left: `${position.left}px` })
        }}
        onClick={(e) => {
          e.stopPropagation(); // Prevent clicks inside dropdown from closing it
        }}
        {...props}
      >
        {children}
      </div>
    </>
  )
})
DropdownMenuContent.displayName = "DropdownMenuContent"

const DropdownMenuItem = React.forwardRef(({ className, onClick, ...props }, ref) => {
  const handleClick = (e) => {
    e.stopPropagation(); // Prevent click from bubbling to overlay
    if (onClick) {
      onClick(e);
    }
  };
  
  return (
    <div
      ref={ref}
      className={cn(
        "relative flex cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors focus:bg-slate-100 focus:text-slate-900 data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
        className
      )}
      onClick={handleClick}
      {...props}
    />
  );
})
DropdownMenuItem.displayName = "DropdownMenuItem"

const DropdownMenuSeparator = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("my-1 h-px bg-slate-200", className)}
    {...props}
  />
))
DropdownMenuSeparator.displayName = "DropdownMenuSeparator"

const DropdownMenuLabel = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("px-2 py-1.5 text-sm font-semibold", className)}
    {...props}
  />
))
DropdownMenuLabel.displayName = "DropdownMenuLabel"

export { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuLabel }

