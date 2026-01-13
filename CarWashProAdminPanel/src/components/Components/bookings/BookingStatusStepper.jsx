import React from 'react';
import { cn } from "@/lib/utils";
import { Check, Clock, Car, MapPin, Droplets, CheckCircle2, XCircle } from 'lucide-react';

const steps = [
  { key: 'pending', label: 'Pending', icon: Clock },
  { key: 'accepted', label: 'Accepted', icon: Check },
  { key: 'on_the_way', label: 'On The Way', icon: Car },
  { key: 'arrived', label: 'Arrived', icon: MapPin },
  { key: 'in_progress', label: 'In Progress', icon: Droplets },
  { key: 'completed', label: 'Completed', icon: CheckCircle2 },
];

export default function BookingStatusStepper({ currentStatus, timeline = [] }) {
  const isCancelled = currentStatus === 'cancelled';
  const currentIndex = steps.findIndex(s => s.key === currentStatus);

  if (isCancelled) {
    return (
      <div className="flex items-center gap-3 p-4 bg-red-50 rounded-xl border border-red-100">
        <XCircle className="w-6 h-6 text-red-500" />
        <div>
          <p className="font-medium text-red-700">Booking Cancelled</p>
          <p className="text-sm text-red-600">This booking has been cancelled</p>
        </div>
      </div>
    );
  }

  return (
    <div className="relative">
      <div className="flex items-center justify-between">
        {steps.map((step, index) => {
          const Icon = step.icon;
          const isCompleted = index < currentIndex;
          const isCurrent = index === currentIndex;
          const isPending = index > currentIndex;
          
          return (
            <React.Fragment key={step.key}>
              <div className="flex flex-col items-center">
                <div className={cn(
                  "w-10 h-10 rounded-full flex items-center justify-center transition-all duration-300",
                  isCompleted && "bg-emerald-500 text-white",
                  isCurrent && "bg-blue-500 text-white ring-4 ring-blue-100",
                  isPending && "bg-slate-100 text-slate-400"
                )}>
                  <Icon className="w-5 h-5" />
                </div>
                <span className={cn(
                  "mt-2 text-xs font-medium text-center",
                  isCompleted && "text-emerald-600",
                  isCurrent && "text-blue-600",
                  isPending && "text-slate-400"
                )}>
                  {step.label}
                </span>
              </div>
              
              {index < steps.length - 1 && (
                <div className="flex-1 h-0.5 mx-2 mt-[-24px]">
                  <div className={cn(
                    "h-full transition-all duration-300",
                    index < currentIndex ? "bg-emerald-500" : "bg-slate-200"
                  )} />
                </div>
              )}
            </React.Fragment>
          );
        })}
      </div>

      {/* Timeline */}
      {timeline && timeline.length > 0 && (
        <div className="mt-6 pt-6 border-t border-slate-100">
          <h4 className="text-sm font-medium text-slate-700 mb-3">Timeline</h4>
          <div className="space-y-3">
            {timeline.map((event, i) => (
              <div key={i} className="flex items-start gap-3 text-sm">
                <div className="w-2 h-2 rounded-full bg-slate-300 mt-1.5" />
                <div>
                  <p className="font-medium text-slate-700 capitalize">
                    {event.status?.replace(/_/g, ' ')}
                  </p>
                  <p className="text-slate-500">
                    {new Date(event.timestamp).toLocaleString()}
                  </p>
                  {event.note && (
                    <p className="text-slate-600 mt-1">{event.note}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}