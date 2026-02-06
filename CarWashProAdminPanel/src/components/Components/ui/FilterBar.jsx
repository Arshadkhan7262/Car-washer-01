import React from 'react';
import { Input } from '@/components/ui/input';
import { Search } from 'lucide-react';

export default function FilterBar({ search, onSearchChange, placeholder = "Search..." }) {
  return (
    <div className="mb-4">
      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400 w-4 h-4" />
        <Input
          type="text"
          placeholder={placeholder}
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          className="pl-10"
        />
      </div>
    </div>
  );
}
