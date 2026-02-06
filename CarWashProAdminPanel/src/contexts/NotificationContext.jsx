import React, { createContext, useContext, useCallback } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';

const NotificationContext = createContext(null);

export const useNotifications = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within NotificationProvider');
  }
  return context;
};

export const NotificationProvider = ({ children }) => {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:3000/api/v1';

  // Fetch unread notification count
  const { data: unreadCountData } = useQuery({
    queryKey: ['notifications', 'unread-count'],
    queryFn: async () => {
      const response = await fetch(
        `${API_BASE_URL}/admin/notifications?limit=1&status=unread`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'Content-Type': 'application/json',
          },
        }
      );
      const data = await response.json();
      // Return count from pagination total
      return data.success ? (data.data?.pagination?.total || 0) : 0;
    },
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  const unreadCount = unreadCountData || 0;

  // Fetch recent notifications for dropdown
  const { data: recentNotifications = [] } = useQuery({
    queryKey: ['notifications', 'recent'],
    queryFn: async () => {
      const response = await fetch(
        `${API_BASE_URL}/admin/notifications?limit=10&sort=-created_at&status=unread`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'Content-Type': 'application/json',
          },
        }
      );
      const data = await response.json();
      return data.success ? (data.data?.notifications || []) : [];
    },
    refetchInterval: 30000,
  });

  // Mark notification as read mutation
  const markAsReadMutation = useMutation({
    mutationFn: async (notificationId) => {
      const response = await fetch(
        `${API_BASE_URL}/admin/notifications/${notificationId}/read`,
        {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'Content-Type': 'application/json',
          },
        }
      );
      const data = await response.json();
      if (!data.success) throw new Error(data.message || 'Failed to mark as read');
      return data;
    },
    onSuccess: () => {
      // Invalidate all notification queries
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
  });

  // Mark all as read mutation
  const markAllAsReadMutation = useMutation({
    mutationFn: async () => {
      // Get all unread notifications
      const response = await fetch(
        `${API_BASE_URL}/admin/notifications?limit=1000&status=unread`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'Content-Type': 'application/json',
          },
        }
      );
      const data = await response.json();
      if (!data.success) throw new Error('Failed to fetch notifications');

      const notifications = data.data?.notifications || [];
      
      // Mark each as read
      const promises = notifications.map(notif => 
        fetch(`${API_BASE_URL}/admin/notifications/${notif._id || notif.id}/read`, {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'Content-Type': 'application/json',
          },
        })
      );

      await Promise.all(promises);
      return { success: true };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      toast.success('All notifications marked as read');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to mark all as read');
    },
  });

  // Delete notification mutation
  const deleteNotificationMutation = useMutation({
    mutationFn: async (notificationId) => {
      const response = await fetch(
        `${API_BASE_URL}/admin/notifications/${notificationId}`,
        {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'Content-Type': 'application/json',
          },
        }
      );
      const data = await response.json();
      if (!data.success) throw new Error(data.message || 'Failed to delete');
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to delete notification');
    },
  });

  // Get notification type category
  const getNotificationCategory = useCallback((type) => {
    if (!type) return 'all';
    
    // Customer notifications
    if (['customer_booking', 'customer_payment', 'customer_general', 'booking_status'].includes(type)) {
      return 'customer';
    }
    
    // Washer notifications
    if (['washer_booking', 'washer_payment', 'washer_general', 'job_accepted', 'job_status_update', 'job_assigned', 'bank_account_request'].includes(type)) {
      return 'washer';
    }
    
    // Booking notifications
    if (type.includes('booking') || type.includes('job')) {
      return 'booking';
    }
    
    // Wallet notifications
    if (type === 'withdrawal_request') {
      return 'wallet';
    }
    
    return 'all';
  }, []);

  // Get entity ID from notification
  const getEntityId = useCallback((notification) => {
    return notification.data?.booking_id || 
           notification.data?.washer_id || 
           notification.data?.customer_id || 
           notification.data?.entityId ||
           notification._id || 
           notification.id;
  }, []);

  // Handle notification click
  const handleNotificationClick = useCallback(async (notification, closeDropdown) => {
    const notificationId = notification._id || notification.id;
    const type = notification.data?.type || '';
    const category = getNotificationCategory(type);
    const entityId = getEntityId(notification);

    try {
      // Optimistically update UI
      queryClient.setQueryData(['notifications', 'recent'], (oldData) => {
        if (!oldData) return [];
        return oldData.filter(n => (n._id || n.id) !== notificationId);
      });

      // Mark as read
      await markAsReadMutation.mutateAsync(notificationId);

      // Close dropdown if provided
      if (closeDropdown) {
        closeDropdown();
      }

      // Navigate based on category
      const refId = entityId ? `&refId=${entityId}` : '';
      
      switch (category) {
        case 'washer':
          navigate(`/notifications?tab=washer${refId}`);
          break;
        case 'customer':
          navigate(`/notifications?tab=customer${refId}`);
          break;
        case 'booking':
          navigate(`/notifications?tab=booking${refId}`);
          break;
        case 'wallet':
          navigate(`/payments?tab=withdrawals&status=pending`);
          break;
        default:
          navigate(`/notifications?tab=all${refId}`);
      }
    } catch (error) {
      // Revert optimistic update on error
      queryClient.invalidateQueries({ queryKey: ['notifications', 'recent'] });
      toast.error(error.message || 'Failed to process notification');
    }
  }, [navigate, getNotificationCategory, getEntityId, markAsReadMutation, queryClient]);

  const value = {
    unreadCount,
    recentNotifications: recentNotifications.filter(n => !n.is_deleted),
    markAsRead: markAsReadMutation.mutate,
    markAllAsRead: markAllAsReadMutation.mutate,
    deleteNotification: deleteNotificationMutation.mutate,
    handleNotificationClick,
    getNotificationCategory,
    getEntityId,
    isLoading: markAsReadMutation.isPending || deleteNotificationMutation.isPending,
  };

  return (
    <NotificationContext.Provider value={value}>
      {children}
    </NotificationContext.Provider>
  );
};
