import React, { useState, useEffect, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  Bell, DollarSign, User, Calendar, 
  X, CreditCard, Wallet
} from 'lucide-react';
import {
  Card,
  CardContent,
} from "@/components/ui/card";
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useNotifications } from '@/contexts/NotificationContext';
import { cn } from '@/lib/utils';

export default function Notifications() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const { deleteNotification, getNotificationCategory, getEntityId } = useNotifications();
  const [activeTab, setActiveTab] = useState('all');
  const [highlightedRefId, setHighlightedRefId] = useState(null);
  const tableRef = useRef(null);

  // Check URL params for tab navigation and refId highlighting
  useEffect(() => {
    const tab = searchParams.get('tab');
    const refId = searchParams.get('refId');
    
    // Set active tab from URL
    if (tab && ['all', 'customer', 'washer', 'booking', 'wallet'].includes(tab)) {
      setActiveTab(tab);
    }
    
    // Handle refId highlighting
    if (refId) {
      setHighlightedRefId(refId);
      // Scroll to highlighted notification after a short delay
      setTimeout(() => {
        const element = document.querySelector(`[data-ref-id="${refId}"]`);
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }, 100);
      
      // Remove highlight after 5 seconds
      setTimeout(() => {
        setHighlightedRefId(null);
        const newSearchParams = new URLSearchParams(searchParams);
        newSearchParams.delete('refId');
        setSearchParams(newSearchParams, { replace: true });
      }, 5000);
    }
  }, [searchParams, setSearchParams]);

  // Fetch ALL notifications for stats calculation
  const { data: allNotificationsData } = useQuery({
    queryKey: ['notifications', 'all-stats'],
    queryFn: async () => {
      const response = await fetch(
        `${import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:3000/api/v1'}/admin/notifications?limit=1000&sort=-created_at&role=all`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'Content-Type': 'application/json',
          },
        }
      );
      const data = await response.json();
      return data.success ? data.data.notifications : [];
    },
    refetchInterval: 30000,
  });

  // Fetch notifications with role filter for current tab
  const { data: notificationsData, isLoading } = useQuery({
    queryKey: ['notifications', activeTab],
    queryFn: async () => {
      const role = activeTab === 'all' ? 'all' : activeTab;
      const response = await fetch(
        `${import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:3000/api/v1'}/admin/notifications?limit=100&sort=-created_at&role=${role}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'Content-Type': 'application/json',
          },
        }
      );
      const data = await response.json();
      return data.success ? data.data.notifications : [];
    },
    refetchInterval: 30000, // Auto-refresh every 30 seconds
  });

  const allNotifications = allNotificationsData || [];
  const notifications = notificationsData || [];

  // Helper function to get notification type
  const getNotificationType = (notification) => {
    // Backend transforms notifications and adds 'type' at root level
    if (notification.type && notification.type !== 'general') {
      return notification.type;
    }
    
    // Handle both Map and object formats for data field
    let dataObj = {};
    if (notification.data) {
      if (notification.data instanceof Map) {
        dataObj = Object.fromEntries(notification.data);
      } else if (typeof notification.data === 'object') {
        dataObj = notification.data;
      }
    }
    
    if (dataObj.type) {
      return dataObj.type;
    }
    
    // Fallback: Try to infer type from title or message
    const title = (notification.title || '').toLowerCase();
    const message = (notification.message || '').toLowerCase();
    
    // Check for customer-related keywords
    if (title.includes('customer') || title.includes('booking created') || message.includes('customer')) {
      return 'customer_booking';
    }
    
    // Check for washer-related keywords
    if (title.includes('washer') || title.includes('job') || message.includes('washer') || message.includes('accepted') || message.includes('on the way') || message.includes('arrived') || message.includes('washing')) {
      return 'washer_booking';
    }
    
    // Check for withdrawal keywords
    if (title.includes('withdrawal') || message.includes('withdrawal')) {
      return 'withdrawal_request';
    }
    
    // Default fallback
    return 'general';
  };

  // Filter notifications by category for stats (from ALL notifications)
  const customerNotifications = allNotifications.filter(n => {
    const type = getNotificationType(n);
    return ['customer_booking', 'customer_payment', 'customer_general', 'booking_status'].includes(type);
  });

  const washerNotifications = allNotifications.filter(n => {
    const type = getNotificationType(n);
    return ['washer_booking', 'washer_payment', 'washer_general', 'job_accepted', 'job_status_update', 'job_assigned', 'bank_account_request'].includes(type);
  });

  const bookingNotifications = allNotifications.filter(n => {
    const type = getNotificationType(n);
    return ['customer_booking', 'washer_booking', 'job_accepted', 'job_status_update', 'job_assigned', 'booking_status'].includes(type);
  });

  const walletNotifications = allNotifications.filter(n => {
    const type = getNotificationType(n);
    return ['withdrawal_request'].includes(type);
  });

  // Filter notifications for current tab display
  const getFilteredNotificationsForTab = () => {
    switch (activeTab) {
      case 'customer':
        return notifications.filter(n => {
          const type = getNotificationType(n);
          return ['customer_booking', 'customer_payment', 'customer_general', 'booking_status'].includes(type);
        });
      case 'washer':
        return notifications.filter(n => {
          const type = getNotificationType(n);
          return ['washer_booking', 'washer_payment', 'washer_general', 'job_accepted', 'job_status_update', 'job_assigned', 'bank_account_request'].includes(type);
        });
      case 'booking':
        return notifications.filter(n => {
          const type = getNotificationType(n);
          return ['customer_booking', 'washer_booking', 'job_accepted', 'job_status_update', 'job_assigned', 'booking_status'].includes(type);
        });
      case 'wallet':
        return notifications.filter(n => {
          const type = getNotificationType(n);
          return ['withdrawal_request'].includes(type);
        });
      default:
        return notifications;
    }
  };

  const displayedNotifications = getFilteredNotificationsForTab();

  // Handle notification click - navigate based on type
  const handleNotificationClick = (notification) => {
    const type = getNotificationType(notification);
    const entityId = getEntityId(notification);
    
    if (type === 'withdrawal_request') {
      navigate('/payments?tab=withdrawals&status=pending');
    } else if (type.includes('booking') || type.includes('job')) {
      navigate('/booking');
    } else {
      // Stay on notifications page
      const category = getNotificationCategory(type);
      navigate(`/notifications?tab=${category}&refId=${entityId}`);
    }
  };

  // Handle tab change
  const handleTabChange = (value) => {
    setActiveTab(value);
    const newSearchParams = new URLSearchParams(searchParams);
    newSearchParams.set('tab', value);
    newSearchParams.delete('refId'); // Clear refId when changing tabs
    setSearchParams(newSearchParams, { replace: true });
  };

  // Get notification icon and color based on type
  const getNotificationIcon = (notification) => {
    const type = getNotificationType(notification);
    if (type === 'withdrawal_request') {
      return { icon: Wallet, color: 'text-emerald-600', bg: 'bg-emerald-50' };
    } else if (type === 'bank_account_request') {
      return { icon: CreditCard, color: 'text-blue-600', bg: 'bg-blue-50' };
    } else if (['customer_booking', 'customer_payment', 'customer_general', 'booking_status'].includes(type)) {
      return { icon: User, color: 'text-blue-600', bg: 'bg-blue-50' };
    } else if (['washer_booking', 'washer_payment', 'washer_general', 'job_accepted', 'job_status_update', 'job_assigned'].includes(type)) {
      return { icon: User, color: 'text-purple-600', bg: 'bg-purple-50' };
    } else if (type.includes('booking') || type.includes('job')) {
      return { icon: Calendar, color: 'text-amber-600', bg: 'bg-amber-50' };
    }
    return { icon: Bell, color: 'text-slate-600', bg: 'bg-slate-50' };
  };

  // Common columns for notifications
  const getColumns = (role) => [
    {
      header: 'Type',
      className: 'min-w-[120px]',
      width: '120px',
      cellClassName: 'text-left',
      cell: (row) => {
        const type = getNotificationType(row);
        const { icon: Icon, color, bg } = getNotificationIcon(row);
        const entityId = getEntityId(row);
        const isHighlighted = highlightedRefId === entityId;
        
        return (
          <div 
            className={`flex items-center gap-2 p-2 rounded-lg ${bg} w-fit ${isHighlighted ? 'ring-2 ring-blue-500' : ''}`}
            data-ref-id={entityId}
          >
            <Icon className={`w-4 h-4 ${color}`} />
            <span className="text-sm font-medium text-slate-700">
              {type === 'withdrawal_request' ? 'Withdrawal' : 
               type === 'bank_account_request' ? 'Bank Account' :
               ['customer_booking', 'customer_payment', 'customer_general', 'booking_status'].includes(type) ? 'Customer' :
               ['washer_booking', 'washer_payment', 'washer_general', 'job_accepted', 'job_status_update', 'job_assigned'].includes(type) ? 'Washer' : 'General'}
            </span>
          </div>
        );
      }
    },
    {
      header: role === 'washer' ? 'Washer' : role === 'customer' ? 'Customer' : 'User',
      className: 'min-w-[140px]',
      width: '140px',
      cellClassName: 'text-left',
      cell: (row) => {
        const data = row.data instanceof Map ? Object.fromEntries(row.data) : (row.data || {});
        const userName = data.washer_name || 
                        data.customer_name || 
                        row.user_ids?.[0]?.name || 
                        'Unknown';
        return (
          <span className="font-medium text-slate-900">{userName}</span>
        );
      }
    },
    {
      header: 'Title',
      className: 'min-w-[180px]',
      width: '180px',
      cellClassName: 'text-left',
      cell: (row) => (
        <span className="font-medium text-slate-900">{row.title}</span>
      )
    },
    {
      header: 'Message',
      className: 'min-w-[200px]',
      width: '200px',
      cellClassName: 'text-left',
      cell: (row) => (
        <span className="text-sm text-slate-600">{row.message}</span>
      )
    },
    {
      header: role === 'washer' ? 'Amount' : 'Details',
      className: 'min-w-[140px]',
      width: '140px',
      cellClassName: 'text-left',
      cell: (row) => {
        const data = row.data instanceof Map ? Object.fromEntries(row.data) : (row.data || {});
        const type = getNotificationType(row);
        if (type === 'withdrawal_request') {
          return (
            <span className="font-semibold text-emerald-600">
              ${parseFloat(data.amount || 0).toFixed(2)}
            </span>
          );
        }
        return (
          <span className="text-sm text-slate-500">
            {data.booking_id ? `Booking: #${data.booking_id.slice(-6)}` : '-'}
          </span>
        );
      }
    },
    {
      header: 'Status',
      className: 'min-w-[120px]',
      width: '120px',
      cellClassName: 'text-center',
      cell: (row) => {
        const data = row.data instanceof Map ? Object.fromEntries(row.data) : (row.data || {});
        return <StatusBadge status={data.status || 'completed'} />;
      }
    },
    {
      header: 'Date',
      className: 'min-w-[140px]',
      width: '140px',
      cellClassName: 'text-left',
      cell: (row) => (
        <span className="text-sm text-slate-600">
          {row.created_at && format(new Date(row.created_at), 'MMM d, h:mm a')}
        </span>
      )
    },
    {
      header: '',
      className: 'w-12',
      width: '48px',
      cellClassName: 'text-center',
      cell: (row) => {
        const notificationId = row._id || row.id;
        
        return (
          <Button
            size="sm"
            variant="ghost"
            onClick={() => deleteNotification(notificationId)}
            className="text-red-600 hover:text-red-700"
          >
            <X className="w-4 h-4" />
          </Button>
        );
      }
    }
  ];

  // Stats - calculated from ALL notifications
  const totalNotifications = allNotifications.length;
  const customerCount = customerNotifications.length;
  const washerCount = washerNotifications.length;
  const bookingCount = bookingNotifications.length;
  const walletCount = walletNotifications.length;

  // Mobile card component for notifications
  const NotificationCard = ({ notification, isHighlighted }) => {
    const type = getNotificationType(notification);
    const { icon: Icon, color, bg } = getNotificationIcon(notification);
    const data = notification.data instanceof Map ? Object.fromEntries(notification.data) : (notification.data || {});
    const entityId = getEntityId(notification);
    const userName = data.washer_name || data.customer_name || notification.user_ids?.[0]?.name || 'Unknown';
    
    return (
      <Card 
        className={cn(
          "transition-all",
          isHighlighted && "ring-2 ring-blue-500 bg-blue-50"
        )}
        data-ref-id={entityId}
      >
        <CardContent className="p-4">
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-start gap-3 flex-1 min-w-0">
              <div className={cn("p-2 rounded-lg flex-shrink-0", bg)}>
                <Icon className={cn("w-4 h-4", color)} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs font-medium text-slate-500 uppercase">
                    {type === 'withdrawal_request' ? 'Withdrawal' : 
                     type === 'bank_account_request' ? 'Bank Account' :
                     ['customer_booking', 'customer_payment', 'customer_general', 'booking_status'].includes(type) ? 'Customer' :
                     ['washer_booking', 'washer_payment', 'washer_general', 'job_accepted', 'job_status_update', 'job_assigned'].includes(type) ? 'Washer' : 'General'}
                  </span>
                  <StatusBadge status={data.status || 'completed'} />
                </div>
                <h3 className="font-semibold text-slate-900 mb-1 line-clamp-1">{notification.title}</h3>
                <p className="text-sm text-slate-600 mb-2 line-clamp-2">{notification.message}</p>
                <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500">
                  <span>{userName}</span>
                  {type === 'withdrawal_request' && (
                    <span className="font-semibold text-emerald-600">
                      ${parseFloat(data.amount || 0).toFixed(2)}
                    </span>
                  )}
                  {data.booking_id && (
                    <span>Booking: #{data.booking_id.slice(-6)}</span>
                  )}
                  {notification.created_at && (
                    <span className="ml-auto">
                      {format(new Date(notification.created_at), 'MMM d, h:mm a')}
                    </span>
                  )}
                </div>
              </div>
            </div>
            <Button
              size="sm"
              variant="ghost"
              onClick={(e) => {
                e.stopPropagation();
                deleteNotification(notification._id || notification.id);
              }}
              className="text-red-600 hover:text-red-700 flex-shrink-0"
            >
              <X className="w-4 h-4" />
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  };

  return (
    <div className="w-full">
      <PageHeader 
        title="Notifications"
        subtitle="View all customer and washer notifications"
      />

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-5 gap-4 sm:gap-6 mb-6 sm:mb-8">
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-blue-50 flex-shrink-0">
                <Bell className="w-4 h-4 sm:w-5 sm:h-5 text-blue-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Total</p>
                <p className="text-xl sm:text-2xl font-bold">{totalNotifications}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-emerald-50 flex-shrink-0">
                <User className="w-4 h-4 sm:w-5 sm:h-5 text-emerald-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Customer</p>
                <p className="text-xl sm:text-2xl font-bold">{customerCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-purple-50 flex-shrink-0">
                <User className="w-4 h-4 sm:w-5 sm:h-5 text-purple-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Washer</p>
                <p className="text-xl sm:text-2xl font-bold">{washerCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-orange-50 flex-shrink-0">
                <Calendar className="w-4 h-4 sm:w-5 sm:h-5 text-orange-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Booking</p>
                <p className="text-xl sm:text-2xl font-bold">{bookingCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-emerald-50 flex-shrink-0">
                <Wallet className="w-4 h-4 sm:w-5 sm:h-5 text-emerald-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Wallet</p>
                <p className="text-xl sm:text-2xl font-bold">{walletCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs value={activeTab} onValueChange={handleTabChange} className="space-y-4 sm:space-y-6">
        <div className="overflow-x-auto -mx-4 px-4 sm:mx-0 sm:px-0">
          <TabsList className="bg-white border w-full sm:w-auto inline-flex min-w-full sm:min-w-0">
            <TabsTrigger value="all" className="text-xs sm:text-sm whitespace-nowrap">All ({totalNotifications})</TabsTrigger>
            <TabsTrigger value="customer" className="text-xs sm:text-sm whitespace-nowrap">Customer ({customerCount})</TabsTrigger>
            <TabsTrigger value="washer" className="text-xs sm:text-sm whitespace-nowrap">Washer ({washerCount})</TabsTrigger>
            <TabsTrigger value="booking" className="text-xs sm:text-sm whitespace-nowrap">Booking ({bookingCount})</TabsTrigger>
            <TabsTrigger value="wallet" className="text-xs sm:text-sm whitespace-nowrap">Wallet ({walletCount})</TabsTrigger>
          </TabsList>
        </div>

        <TabsContent value="all">
          <div ref={tableRef}>
            {/* Desktop Table View */}
            <div className="hidden lg:block">
              <DataTable
                columns={getColumns('all')}
                data={notifications}
                isLoading={isLoading}
                emptyMessage="No notifications found"
              />
            </div>
            {/* Mobile Card View */}
            <div className="lg:hidden space-y-3">
              {isLoading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => (
                    <Card key={i}>
                      <CardContent className="p-4">
                        <div className="animate-pulse space-y-3">
                          <div className="h-4 bg-slate-200 rounded w-3/4"></div>
                          <div className="h-4 bg-slate-200 rounded w-full"></div>
                          <div className="h-4 bg-slate-200 rounded w-1/2"></div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              ) : notifications.length === 0 ? (
                <div className="bg-white rounded-2xl border border-slate-100 p-12 text-center">
                  <p className="text-slate-500">No notifications found</p>
                </div>
              ) : (
                notifications.map((notification) => {
                  const entityId = getEntityId(notification);
                  return (
                    <NotificationCard
                      key={notification._id || notification.id}
                      notification={notification}
                      isHighlighted={highlightedRefId === entityId}
                    />
                  );
                })
              )}
            </div>
          </div>
        </TabsContent>

        <TabsContent value="customer">
          <div ref={tableRef}>
            {/* Desktop Table View */}
            <div className="hidden lg:block">
              <DataTable
                columns={getColumns('customer')}
                data={displayedNotifications}
                isLoading={isLoading}
                emptyMessage="No customer notifications found"
              />
            </div>
            {/* Mobile Card View */}
            <div className="lg:hidden space-y-3">
              {isLoading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => (
                    <Card key={i}>
                      <CardContent className="p-4">
                        <div className="animate-pulse space-y-3">
                          <div className="h-4 bg-slate-200 rounded w-3/4"></div>
                          <div className="h-4 bg-slate-200 rounded w-full"></div>
                          <div className="h-4 bg-slate-200 rounded w-1/2"></div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              ) : displayedNotifications.length === 0 ? (
                <div className="bg-white rounded-2xl border border-slate-100 p-12 text-center">
                  <p className="text-slate-500">No customer notifications found</p>
                </div>
              ) : (
                displayedNotifications.map((notification) => {
                  const entityId = getEntityId(notification);
                  return (
                    <NotificationCard
                      key={notification._id || notification.id}
                      notification={notification}
                      isHighlighted={highlightedRefId === entityId}
                    />
                  );
                })
              )}
            </div>
          </div>
        </TabsContent>

        <TabsContent value="washer">
          <div ref={tableRef}>
            {/* Desktop Table View */}
            <div className="hidden lg:block">
              <DataTable
                columns={getColumns('washer')}
                data={displayedNotifications}
                isLoading={isLoading}
                emptyMessage="No washer notifications found"
              />
            </div>
            {/* Mobile Card View */}
            <div className="lg:hidden space-y-3">
              {isLoading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => (
                    <Card key={i}>
                      <CardContent className="p-4">
                        <div className="animate-pulse space-y-3">
                          <div className="h-4 bg-slate-200 rounded w-3/4"></div>
                          <div className="h-4 bg-slate-200 rounded w-full"></div>
                          <div className="h-4 bg-slate-200 rounded w-1/2"></div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              ) : displayedNotifications.length === 0 ? (
                <div className="bg-white rounded-2xl border border-slate-100 p-12 text-center">
                  <p className="text-slate-500">No washer notifications found</p>
                </div>
              ) : (
                displayedNotifications.map((notification) => {
                  const entityId = getEntityId(notification);
                  return (
                    <NotificationCard
                      key={notification._id || notification.id}
                      notification={notification}
                      isHighlighted={highlightedRefId === entityId}
                    />
                  );
                })
              )}
            </div>
          </div>
        </TabsContent>

        <TabsContent value="booking">
          <div ref={tableRef}>
            {/* Desktop Table View */}
            <div className="hidden lg:block">
              <DataTable
                columns={getColumns('booking')}
                data={displayedNotifications}
                isLoading={isLoading}
                emptyMessage="No booking notifications found"
              />
            </div>
            {/* Mobile Card View */}
            <div className="lg:hidden space-y-3">
              {isLoading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => (
                    <Card key={i}>
                      <CardContent className="p-4">
                        <div className="animate-pulse space-y-3">
                          <div className="h-4 bg-slate-200 rounded w-3/4"></div>
                          <div className="h-4 bg-slate-200 rounded w-full"></div>
                          <div className="h-4 bg-slate-200 rounded w-1/2"></div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              ) : displayedNotifications.length === 0 ? (
                <div className="bg-white rounded-2xl border border-slate-100 p-12 text-center">
                  <p className="text-slate-500">No booking notifications found</p>
                </div>
              ) : (
                displayedNotifications.map((notification) => {
                  const entityId = getEntityId(notification);
                  return (
                    <NotificationCard
                      key={notification._id || notification.id}
                      notification={notification}
                      isHighlighted={highlightedRefId === entityId}
                    />
                  );
                })
              )}
            </div>
          </div>
        </TabsContent>

        <TabsContent value="wallet">
          <div ref={tableRef}>
            {/* Desktop Table View */}
            <div className="hidden lg:block">
              <DataTable
                columns={getColumns('wallet')}
                data={displayedNotifications}
                isLoading={isLoading}
                emptyMessage="No wallet notifications found"
              />
            </div>
            {/* Mobile Card View */}
            <div className="lg:hidden space-y-3">
              {isLoading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => (
                    <Card key={i}>
                      <CardContent className="p-4">
                        <div className="animate-pulse space-y-3">
                          <div className="h-4 bg-slate-200 rounded w-3/4"></div>
                          <div className="h-4 bg-slate-200 rounded w-full"></div>
                          <div className="h-4 bg-slate-200 rounded w-1/2"></div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              ) : displayedNotifications.length === 0 ? (
                <div className="bg-white rounded-2xl border border-slate-100 p-12 text-center">
                  <p className="text-slate-500">No wallet notifications found</p>
                </div>
              ) : (
                displayedNotifications.map((notification) => {
                  const entityId = getEntityId(notification);
                  return (
                    <NotificationCard
                      key={notification._id || notification.id}
                      notification={notification}
                      isHighlighted={highlightedRefId === entityId}
                    />
                  );
                })
              )}
            </div>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
