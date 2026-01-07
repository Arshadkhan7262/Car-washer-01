import React from 'react';
import { cn } from "@/lib/utils";

const statusStyles = {
  // Booking statuses
  pending: "bg-amber-50 text-amber-700 border-amber-200",
  accepted: "bg-blue-50 text-blue-700 border-blue-200",
  on_the_way: "bg-indigo-50 text-indigo-700 border-indigo-200",
  in_progress: "bg-purple-50 text-purple-700 border-purple-200",
  completed: "bg-emerald-50 text-emerald-700 border-emerald-200",
  cancelled: "bg-red-50 text-red-700 border-red-200",
  
  // Payment statuses
  paid: "bg-emerald-50 text-emerald-700 border-emerald-200",
  unpaid: "bg-amber-50 text-amber-700 border-amber-200",
  refunded: "bg-slate-50 text-slate-700 border-slate-200",
  partial: "bg-orange-50 text-orange-700 border-orange-200",
  failed: "bg-red-50 text-red-700 border-red-200",
  
  // User statuses
  active: "bg-emerald-50 text-emerald-700 border-emerald-200",
  blocked: "bg-red-50 text-red-700 border-red-200",
  suspended: "bg-red-50 text-red-700 border-red-200",
  
  // Ticket statuses
  open: "bg-blue-50 text-blue-700 border-blue-200",
  resolved: "bg-emerald-50 text-emerald-700 border-emerald-200",
  closed: "bg-slate-50 text-slate-700 border-slate-200",
  
  // Priority
  low: "bg-slate-50 text-slate-600 border-slate-200",
  medium: "bg-amber-50 text-amber-700 border-amber-200",
  high: "bg-orange-50 text-orange-700 border-orange-200",
  urgent: "bg-red-50 text-red-700 border-red-200",
  
  // Online status
  online: "bg-emerald-50 text-emerald-700 border-emerald-200",
  offline: "bg-slate-50 text-slate-500 border-slate-200",
  
  // Approval
  approved: "bg-emerald-50 text-emerald-700 border-emerald-200",
  rejected: "bg-red-50 text-red-700 border-red-200",
  
  // Default
  default: "bg-slate-50 text-slate-600 border-slate-200",
};

const statusLabels = {
  pending: "Pending",
  accepted: "Accepted",
  on_the_way: "On The Way",
  in_progress: "In Progress",
  completed: "Completed",
  cancelled: "Cancelled",
  paid: "Paid",
  unpaid: "Unpaid",
  refunded: "Refunded",
  partial: "Partial",
  failed: "Failed",
  active: "Active",
  blocked: "Blocked",
  suspended: "Suspended",
  open: "Open",
  resolved: "Resolved",
  closed: "Closed",
  low: "Low",
  medium: "Medium",
  high: "High",
  urgent: "Urgent",
  online: "Online",
  offline: "Offline",
  approved: "Approved",
  rejected: "Rejected",
};

export default function StatusBadge({ status, className, showDot = false }) {
  const style = statusStyles[status] || statusStyles.default;
  const label = statusLabels[status] || status?.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
  
  return (
    <span className={cn(
      "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border",
      style,
      className
    )}>
      {showDot && (
        <span className={cn(
          "w-1.5 h-1.5 rounded-full",
          status === 'online' ? "bg-emerald-500 animate-pulse" : "bg-current opacity-60"
        )} />
      )}
      {label}
    </span>
  );
}