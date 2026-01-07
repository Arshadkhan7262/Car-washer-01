import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '@/utils';
import { cn } from "@/lib/utils";
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
  ChevronLeft,
  ChevronRight,
  LogOut,
  Sparkles
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
  { name: "Reviews", icon: Star, page: "Reviews" },
  { name: "Support", icon: Headphones, page: "Support" },
  { name: "Content", icon: Megaphone, page: "Content" },
  { name: "Settings", icon: Settings, page: "Settings" },
  { name: "Reports", icon: BarChart3, page: "Reports" },
];

export default function Sidebar({ currentPage, collapsed, onToggle }) {
  return (
    <aside className={cn(
      "h-full bg-slate-900 text-white transition-all duration-300 flex flex-col",
      collapsed ? "w-20" : "w-64"
    )}>
      {/* Logo */}
      <div className={cn(
        "h-16 flex items-center border-b border-slate-800 px-4",
        collapsed ? "justify-center" : "justify-between"
      )}>
        {!collapsed && (
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-400 flex items-center justify-center">
              <Sparkles className="w-5 h-5 text-white" />
            </div>
            <span className="font-bold text-lg">CarWash Pro</span>
          </div>
        )}
        {collapsed && (
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-400 flex items-center justify-center">
            <Sparkles className="w-5 h-5 text-white" />
          </div>
        )}
      </div>
      
      {/* Toggle button */}
      <button
        onClick={onToggle}
        className="absolute -right-3 top-20 w-6 h-6 bg-slate-900 rounded-full border border-slate-700 flex items-center justify-center text-slate-400 hover:text-white transition-colors"
      >
        {collapsed ? (
          <ChevronRight className="w-3 h-3" />
        ) : (
          <ChevronLeft className="w-3 h-3" />
        )}
      </button>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto py-4 px-3">
        <ul className="space-y-1">
          {menuItems.map((item) => {
            const isActive = currentPage === item.page;
            return (
              <li key={item.name}>
                <Link
                  to={createPageUrl(item.page)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200",
                    isActive 
                      ? "bg-blue-600 text-white shadow-lg shadow-blue-600/30" 
                      : "text-slate-400 hover:text-white hover:bg-slate-800",
                    collapsed && "justify-center"
                  )}
                >
                  <item.icon className={cn("w-5 h-5 flex-shrink-0", isActive && "text-white")} />
                  {!collapsed && (
                    <span className="font-medium text-sm">{item.name}</span>
                  )}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* Logout */}
      <div className="p-3 border-t border-slate-800">
        <Button
          variant="ghost"
          className={cn(
            "w-full text-slate-400 hover:text-white hover:bg-slate-800",
            collapsed ? "justify-center px-0" : "justify-start"
          )}
        >
          <LogOut className="w-5 h-5" />
          {!collapsed && <span className="ml-3">Logout</span>}
        </Button>
      </div>
    </aside>
  );
}