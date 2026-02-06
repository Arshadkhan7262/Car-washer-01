import React from 'react';
import { Badge } from '@/components/ui/badge';

const variantMap = {
  success: 'bg-green-100 text-green-800',
  error: 'bg-red-100 text-red-800',
  warning: 'bg-yellow-100 text-yellow-800',
  info: 'bg-blue-100 text-blue-800',
  default: 'bg-slate-100 text-slate-800',
};

export default function StatusBadge({ label, variant = 'default' }) {
  return (
    <Badge className={variantMap[variant] || variantMap.default}>
      {label}
    </Badge>
  );
}
