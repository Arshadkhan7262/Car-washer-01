import React from 'react';
import { LucideIcon } from 'lucide-react';

export default function PageHeader({ title, description, icon: Icon }) {
  return (
    <div className="mb-6">
      <div className="flex items-center gap-3 mb-2">
        {Icon && <Icon className="w-8 h-8 text-blue-600" />}
        <h1 className="text-3xl font-bold text-slate-900">{title}</h1>
      </div>
      {description && (
        <p className="text-slate-600 ml-11">{description}</p>
      )}
    </div>
  );
}
