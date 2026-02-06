import React from 'react';
import { Bell, Search, Menu, LogOut, DollarSign, ExternalLink } from "lucide-react";
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../../contexts/AuthContext';
import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

export default function TopBar({ onMenuClick }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  // Fetch recent notifications
  const { data: notifications = [] } = useQuery({
    queryKey: ['notifications', 'recent'],
    queryFn: async () => {
      const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:3000/api/v1'}/admin/notifications?limit=5&sort=-created_at`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
          'Content-Type': 'application/json',
        },
      });
      const data = await response.json();
      return data.success ? data.data.notifications : [];
    },
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  // Filter to show only withdrawal notifications
  const withdrawalNotifications = notifications.filter(n => 
    n.data?.type === 'withdrawal_request'
  );

  // Count pending withdrawal requests (only show withdrawal notifications)
  const pendingWithdrawals = withdrawalNotifications.filter(n => 
    n.data?.status === 'pending'
  );
  const unreadCount = pendingWithdrawals.length;

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const handleViewWithdrawal = (notification) => {
    navigate('/payments?tab=withdrawals&status=pending');
  };

  const getInitials = (name) => {
    if (!name) return 'A';
    const parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  };
  return (
    <header className="h-16 bg-white border-b border-slate-100 flex items-center justify-between px-6 sticky top-0 z-40">
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="icon"
          className="lg:hidden"
          onClick={onMenuClick}
        >
          <Menu className="w-5 h-5" />
        </Button>
        
        <div className="hidden md:flex items-center gap-2 bg-slate-50 rounded-xl px-4 py-2 w-80">
          <Search className="w-4 h-4 text-slate-400" />
          <Input 
            placeholder="Search bookings, customers..." 
            className="border-0 bg-transparent focus-visible:ring-0 p-0 h-auto placeholder:text-slate-400"
          />
        </div>
      </div>

      <div className="flex items-center gap-4">
        {/* Notifications */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="relative">
              <Bell className="w-5 h-5 text-slate-600" />
              {unreadCount > 0 && (
                <span className="absolute top-1 right-1 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center text-white text-xs font-bold">
                  {unreadCount}
                </span>
              )}
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-96 max-h-[500px] overflow-y-auto">
            <DropdownMenuLabel className="flex items-center justify-between">
              <span>Notifications</span>
              <Button
                variant="ghost"
                size="sm"
                className="h-auto p-0 text-xs text-blue-600"
                onClick={() => navigate('/notifications')}
              >
                View All
              </Button>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            {withdrawalNotifications.length === 0 ? (
              <DropdownMenuItem disabled className="text-sm text-slate-500">
                No withdrawal requests
              </DropdownMenuItem>
            ) : (
              withdrawalNotifications.slice(0, 5).map((notif) => {
                const isWithdrawal = notif.data?.type === 'withdrawal_request';
                const isPending = notif.data?.status === 'pending';
                return (
                  <DropdownMenuItem
                    key={notif._id}
                    className={`flex flex-col items-start gap-1 py-3 cursor-pointer ${
                      isPending ? 'bg-amber-50 hover:bg-amber-100' : ''
                    }`}
                    onClick={() => {
                      // Always navigate to withdrawals tab for withdrawal notifications
                      handleViewWithdrawal(notif);
                    }}
                  >
                    <div className="flex items-start gap-2 w-full">
                      {isWithdrawal ? (
                        <DollarSign className="w-4 h-4 text-emerald-600 mt-0.5 flex-shrink-0" />
                      ) : (
                        <Bell className="w-4 h-4 text-blue-600 mt-0.5 flex-shrink-0" />
                      )}
                      <div className="flex-1 min-w-0">
                        <span className="font-medium text-sm block">{notif.title}</span>
                        <span className="text-xs text-slate-500 block mt-1">{notif.message}</span>
                        {isWithdrawal && (
                          <div className="mt-1 flex items-center gap-2">
                            <span className="text-xs font-medium text-emerald-600">
                              ${parseFloat(notif.data?.amount || 0).toFixed(2)}
                            </span>
                            {isPending && (
                              <span className="text-xs px-2 py-0.5 bg-amber-100 text-amber-700 rounded-full">
                                Pending
                              </span>
                            )}
                          </div>
                        )}
                        <span className="text-xs text-slate-400 block mt-1">
                          {notif.created_at && format(new Date(notif.created_at), 'MMM d, h:mm a')}
                        </span>
                      </div>
                    </div>
                  </DropdownMenuItem>
                );
              })
            )}
            {withdrawalNotifications.length > 5 && (
              <>
                <DropdownMenuSeparator />
                <DropdownMenuItem
                  className="text-center justify-center text-sm text-blue-600 cursor-pointer"
                  onClick={() => navigate('/payments?tab=withdrawals&status=pending')}
                >
                  View All Withdrawal Requests
                </DropdownMenuItem>
              </>
            )}
          </DropdownMenuContent>
        </DropdownMenu>

        {/* User menu */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="flex items-center gap-3 pl-2 pr-4 h-10">
              <Avatar className="w-8 h-8">
                <AvatarImage src={user?.avatar} />
                <AvatarFallback className="bg-blue-100 text-blue-600 font-semibold text-sm">
                  {getInitials(user?.name || 'Admin')}
                </AvatarFallback>
              </Avatar>
              <div className="hidden sm:block text-left">
                <p className="text-sm font-medium text-slate-900">{user?.name || 'Admin'}</p>
                <p className="text-xs text-slate-500 capitalize">{user?.role?.replace('_', ' ') || 'Super Admin'}</p>
              </div>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel>My Account</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => navigate('/settings')}>Settings</DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem 
              className="text-red-600 cursor-pointer"
              onClick={handleLogout}
            >
              <LogOut className="mr-2 h-4 w-4" />
              Logout
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}