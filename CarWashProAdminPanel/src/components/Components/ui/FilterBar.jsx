import React from 'react';
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Search, X, Filter } from "lucide-react";
import { cn } from "@/lib/utils";

export default function FilterBar({ 
  searchValue,
  onSearchChange,
  searchPlaceholder = "Search...",
  filters = [],
  onClearFilters,
  className
}) {
  const hasActiveFilters = filters.some(f => f.value && f.value !== 'all');
  
  return (
    <div className={cn(
      "bg-white rounded-xl border border-slate-200 shadow-sm p-4 mb-6",
      className
    )}>
      <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-center">
        {/* Search */}
        <div className="relative flex-1 w-full sm:max-w-md">
          <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none z-10">
            <Search className="w-5 h-5 text-slate-400" />
          </div>
          <Input
            placeholder={searchPlaceholder}
            value={searchValue}
            onChange={(e) => onSearchChange(e.target.value)}
            className="pl-10 pr-4 h-10 bg-white border border-slate-300 rounded-lg focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:border-blue-500 transition-colors w-full"
          />
        </div>
        
        {/* Filters */}
        <div className="flex flex-wrap items-center gap-2 w-full sm:w-auto">
          {filters.map((filter, i) => {
            // Find the label for the current value
            const currentLabel = filter.value === 'all' 
              ? `All ${filter.placeholder}`
              : filter.options.find(opt => opt.value === filter.value)?.label || filter.placeholder;
            
            return (
              <Select
                key={i}
                value={filter.value}
                onValueChange={filter.onChange}
              >
                <SelectTrigger className="w-full sm:w-[160px] h-10 bg-white border border-slate-300 rounded-lg shadow-sm hover:border-slate-400 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                  <SelectValue placeholder={filter.placeholder}>
                    {currentLabel}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All {filter.placeholder}</SelectItem>
                  {filter.options.map(opt => (
                    <SelectItem key={opt.value} value={opt.value}>
                      {opt.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            );
          })}
          
          {hasActiveFilters && (
            <Button 
              variant="outline" 
              size="sm"
              onClick={onClearFilters}
              className="h-10 px-4 border-slate-300 text-slate-600 hover:text-slate-900 hover:bg-slate-50 transition-colors"
            >
              <X className="w-4 h-4 mr-2" />
              Clear
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}