import React from 'react';
import { format } from 'date-fns';
import { CalendarPlus, CheckCircle2, CreditCard, UserPlus, Droplets, AlertCircle } from 'lucide-react';
import { cn } from "@/lib/utils";

const activityIcons = {
  booking_created: { icon: CalendarPlus, bg: "bg-blue-50", color: "text-blue-600" },
  booking_completed: { icon: CheckCircle2, bg: "bg-emerald-50", color: "text-emerald-600" },
  payment_received: { icon: CreditCard, bg: "bg-purple-50", color: "text-purple-600" },
  new_customer: { icon: UserPlus, bg: "bg-amber-50", color: "text-amber-600" },
  washer_assigned: { icon: Droplets, bg: "bg-cyan-50", color: "text-cyan-600" },
  booking_cancelled: { icon: AlertCircle, bg: "bg-red-50", color: "text-red-600" },
};

export default function ActivityFeed({ activities = [] }) {
  return (
    <div className="bg-white rounded-2xl border border-slate-100 p-6">
      <h3 className="text-lg font-semibold text-slate-900 mb-4">Recent Activity</h3>
      <div className="space-y-4">
        {activities.length === 0 ? (
          <p className="text-sm text-slate-500 text-center py-8">No recent activity</p>
        ) : (
          activities.map((activity, i) => {
            const config = activityIcons[activity.type] || activityIcons.booking_created;
            const Icon = config.icon;
            return (
              <div key={i} className="flex items-start gap-3">
                <div className={cn("p-2 rounded-lg flex-shrink-0", config.bg)}>
                  <Icon className={cn("w-4 h-4", config.color)} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-900 truncate">
                    {activity.title}
                  </p>
                  <p className="text-xs text-slate-500">
                    {activity.description}
                  </p>
                </div>
                <span className="text-xs text-slate-400 flex-shrink-0">
                  {activity.time}
                </span>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}