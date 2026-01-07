import React from 'react';
import { cn } from "@/lib/utils";

export default function PageHeader({ 
  title, 
  subtitle, 
  actions,
  breadcrumbs,
  className 
}) {
  return (
    <div className={cn("mb-8", className)}>
      {breadcrumbs && (
        <div className="flex items-center gap-2 text-sm text-slate-500 mb-2">
          {breadcrumbs.map((crumb, i) => (
            <React.Fragment key={i}>
              {i > 0 && <span>/</span>}
              <span className={i === breadcrumbs.length - 1 ? "text-slate-900 font-medium" : ""}>
                {crumb}
              </span>
            </React.Fragment>
          ))}
        </div>
      )}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-900 tracking-tight">{title}</h1>
          {subtitle && (
            <p className="mt-1 text-slate-500">{subtitle}</p>
          )}
        </div>
        {actions && (
          <div className="flex items-center gap-3 flex-shrink-0">
            {actions}
          </div>
        )}
      </div>
    </div>
  );
}