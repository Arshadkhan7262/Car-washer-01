import React, { useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import Sidebar from '@/components/Components/layout/Sidebar.jsx';
import TopBar from '@/components/Components/layout/Topbar.jsx';
import { cn } from "@/lib/utils";

export default function Layout() {
  const location = useLocation();
  const { user } = useAuth();
  const [collapsed, setCollapsed] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  
  const pageMap = {
    '/dashboard': 'Dashboard',
    '/bookings': 'Bookings',
    '/customers': 'Customers',
    '/washers': 'Washers',
    '/services': 'Services',
    '/vehicles': 'Vehicles',
    '/coupons': 'Coupons',
    '/schedule': 'Schedule',
    '/payments': 'Payments',
    '/reviews': 'Reviews',
    '/support': 'Support',
    '/content': 'Content',
    '/settings': 'Settings',
    '/reports': 'Reports',
  };
  const currentPageName = pageMap[location.pathname] || 'Dashboard';

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Sidebar - Desktop */}
      <div className="hidden lg:block fixed left-0 top-0 h-screen z-50">
        <Sidebar 
          currentPage={currentPageName} 
          collapsed={collapsed}
          onToggle={() => setCollapsed(!collapsed)}
        />
      </div>

      {/* Mobile sidebar overlay */}
      {mobileMenuOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setMobileMenuOpen(false)}
        />
      )}

      {/* Mobile sidebar */}
      <div className={cn(
        "fixed inset-y-0 left-0 z-50 lg:hidden transition-transform duration-300 w-64 flex flex-col",
        mobileMenuOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="flex-shrink-0 h-16 flex items-center justify-between border-b border-slate-800 px-4 bg-slate-900">
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-400 flex items-center justify-center">
              <span className="text-white text-sm">🚗</span>
            </div>
            <span className="font-bold text-lg text-white">CarWash Pro</span>
          </div>
          <button onClick={() => setMobileMenuOpen(false)} className="text-slate-400 hover:text-white">
            ✕
          </button>
        </div>
        <div className="flex-1 min-h-0 overflow-hidden">
          <Sidebar 
            currentPage={currentPageName}
            collapsed={false}
            onToggle={() => setMobileMenuOpen(false)}
          />
        </div>
      </div>

      {/* Main content */}
      <div className={cn(
        "transition-all duration-300 min-h-screen",
        collapsed ? "lg:pl-20" : "lg:pl-64"
      )}>
        <TopBar 
          onMenuClick={() => setMobileMenuOpen(true)}
        />
        <main className="p-4 sm:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}