import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '@/utils';
import { cn } from "@/lib/utils";
import { useQuery } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import {
  LayoutDashboard,
  CalendarDays,
  Users,
  Droplets,
  Wrench,
  DollarSign,
  Clock,
  CreditCard,
  Star,
  Headphones,
  Megaphone,
  Settings,
  BarChart3,
  Building2,
  Car,
  LogOut,
  Sparkles,
  Bell
} from "lucide-react";
import { Button } from "@/components/ui/button";

const menuItems = [
  { name: "Dashboard", icon: LayoutDashboard, page: "Dashboard" },
  { name: "Bookings", icon: CalendarDays, page: "Bookings" },
  { name: "Customers", icon: Users, page: "Customers" },
  { name: "Washers", icon: Droplets, page: "Washers" },
  { name: "Services", icon: Wrench, page: "Services" },
  { name: "Vehicles", icon: Car, page: "Vehicles" },
  { name: "Pricing & Coupons", icon: DollarSign, page: "Coupons" },
  { name: "Schedule", icon: Clock, page: "Schedule" },
  { name: "Payments", icon: CreditCard, page: "Payments" },
  { name: "Notifications", icon: Bell, page: "Notifications" },
  { name: "Reviews", icon: Star, page: "Reviews" },
  { name: "Support", icon: Headphones, page: "Support" },
  { name: "Content", icon: Megaphone, page: "Content" },
  { name: "Settings", icon: Settings, page: "Settings" },
  { name: "Reports", icon: BarChart3, page: "Reports" },
];

export default function Sidebar({ currentPage, collapsed, onToggle }) {
  // Fetch pending withdrawals count for badge
  const { data: pendingWithdrawals = [] } = useQuery({
    queryKey: ['withdrawals', 'pending'],
    queryFn: () => base44.entities.Withdrawal.list({ status: 'pending' }),
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  const pendingCount = pendingWithdrawals.length || 0;

  return (
    <>
      <style>{`
        .sidebar-scrollbar::-webkit-scrollbar {
          display: none;
          width: 0;
        }
        .sidebar-scrollbar {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    <aside className={cn(
      "bg-slate-900 text-white transition-all duration-300 flex flex-col",
      collapsed ? "w-20" : "w-64",
      "h-full max-h-full"
    )}>
      {/* Logo - Desktop only */}
      <div className={cn(
        "hidden lg:flex flex-shrink-0 h-16 items-center border-b border-slate-800 px-4",
        collapsed ? "justify-center" : "justify-start"
      )}>
        {!collapsed ? (
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-400 flex items-center justify-center">
              <Sparkles className="w-5 h-5 text-white" />
            </div>
            <span className="font-bold text-lg">CarWash Pro</span>
          </div>
        ) : (
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-400 flex items-center justify-center">
            <Sparkles className="w-5 h-5 text-white" />
          </div>
        )}
      </div>

      {/* Navigation */}
      <nav className="flex-1 min-h-0 overflow-y-auto py-4 px-3 sidebar-scrollbar">
        <ul className="space-y-1">
          {menuItems.map((item) => {
            const isActive = currentPage === item.page;
            return (
              <li key={item.name}>
                <Link
                  to={createPageUrl(item.page)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 transition-all duration-200",
                    isActive 
                      ? "bg-blue-600 text-white shadow-lg shadow-blue-600/30" 
                      : "text-slate-400 hover:text-white hover:bg-slate-800",
                    collapsed && "justify-center"
                  )}
                >
                  <item.icon className={cn("w-5 h-5 flex-shrink-0", isActive && "text-white")} />
                  {!collapsed && (
                    <span className="font-medium text-sm flex-1">{item.name}</span>
                  )}
                  {item.page === 'Payments' && pendingCount > 0 && (
                    <span className={cn(
                      "px-2 py-0.5 rounded-full text-xs font-bold",
                      "bg-red-500 text-white",
                      collapsed && "absolute top-1 right-1"
                    )}>
                      {pendingCount}
                    </span>
                  )}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* Logout */}
      <div className="flex-shrink-0 p-3 border-t border-slate-800">
        <Button
          variant="ghost"
          className={cn(
            "w-full text-red-500 hover:text-red-400 hover:bg-slate-800",
            collapsed ? "justify-center px-0" : "justify-start"
          )}
        >
          <LogOut className="w-5 h-5 text-red-500" />
          {!collapsed && <span className="ml-3 text-red-500">Logout</span>}
        </Button>
      </div>
    </aside>
    </>
  );
}