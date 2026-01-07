import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '@/utils';
import { Button } from "@/components/ui/button";
import { CalendarPlus, Plus, UserPlus, Ticket } from 'lucide-react';

export default function QuickActions({ onCreateBooking }) {
  const actions = [
    { 
      label: "New Booking", 
      icon: CalendarPlus, 
      onClick: onCreateBooking,
      primary: true
    },
    { 
      label: "Add Service", 
      icon: Plus, 
      href: "Services"
    },
    { 
      label: "Add Washer", 
      icon: UserPlus, 
      href: "Washers"
    },
    { 
      label: "Create Coupon", 
      icon: Ticket, 
      href: "Coupons"
    },
  ];

  return (
    <div className="bg-white rounded-2xl border border-slate-100 p-6">
      <h3 className="text-lg font-semibold text-slate-900 mb-4">Quick Actions</h3>
      <div className="grid grid-cols-2 gap-3">
        {actions.map((action, i) => {
          const Icon = action.icon;
          const buttonClass = action.primary 
            ? "bg-blue-600 hover:bg-blue-700 text-white" 
            : "bg-slate-50 hover:bg-slate-100 text-slate-700";
          
          if (action.href) {
            return (
              <Link key={i} to={createPageUrl(action.href)}>
                <Button 
                  variant="ghost" 
                  className={`w-full h-auto py-4 flex flex-col gap-2 ${buttonClass}`}
                >
                  <Icon className="w-5 h-5" />
                  <span className="text-xs font-medium">{action.label}</span>
                </Button>
              </Link>
            );
          }
          
          return (
            <Button 
              key={i}
              variant="ghost" 
              className={`h-auto py-4 flex flex-col gap-2 ${buttonClass}`}
              onClick={action.onClick}
            >
              <Icon className="w-5 h-5" />
              <span className="text-xs font-medium">{action.label}</span>
            </Button>
          );
        })}
      </div>
    </div>
  );
}