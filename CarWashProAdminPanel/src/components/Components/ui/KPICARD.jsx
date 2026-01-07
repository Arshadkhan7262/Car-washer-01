import React from 'react';
import { cn } from "@/lib/utils";
import { TrendingUp, TrendingDown } from "lucide-react";

export default function KPICard({ 
  title, 
  value, 
  subtitle,
  icon: Icon, 
  trend, 
  trendValue,
  iconBg = "bg-blue-50",
  iconColor = "text-blue-600",
  className 
}) {
  const isPositive = trend === 'up';
  
  return (
    <div className={cn(
      "bg-white rounded-2xl p-4 sm:p-6 border border-slate-100 shadow-sm hover:shadow-md transition-all duration-300",
      className
    )}>
      <div className="flex items-start justify-between gap-3">
        <div className="space-y-2 sm:space-y-3 flex-1 min-w-0">
          <p className="text-xs sm:text-sm font-medium text-slate-500">{title}</p>
          <div className="space-y-1">
            <h3 className="text-2xl sm:text-3xl font-bold text-slate-900 tracking-tight break-words">{value}</h3>
            {subtitle && (
              <p className="text-sm text-slate-500">{subtitle}</p>
            )}
          </div>
          {trendValue && (
            <div className={cn(
              "flex items-center gap-1 text-sm font-medium",
              isPositive ? "text-emerald-600" : "text-red-500"
            )}>
              {isPositive ? (
                <TrendingUp className="w-4 h-4" />
              ) : (
                <TrendingDown className="w-4 h-4" />
              )}
              <span>{trendValue}</span>
            </div>
          )}
        </div>
        {Icon && (
          <div className={cn(
            "p-3 rounded-xl",
            iconBg
          )}>
            <Icon className={cn("w-6 h-6", iconColor)} />
          </div>
        )}
      </div>
    </div>
  );
}