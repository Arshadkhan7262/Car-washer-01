import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { createPageUrl } from '@/utils';
import { base44 } from '@/api/base44Client';
import { useQuery } from '@tanstack/react-query';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import KPICard from '@/components/Components/ui/KPICARD.jsx';
import RevenueChart from '@/components/Components/dashboard/RevenueChart.jsx';
import ServicesPieChart from '@/components/Components/dashboard/ServicePieChart.jsx';
import ActivityFeed from '@/components/Components/dashboard/ActivityFeed.jsx';
import QuickActions from '@/components/Components/dashboard/QuickActions.jsx';
import { 
  CalendarDays, 
  Clock, 
  CheckCircle2, 
  DollarSign, 
  Users, 
  Droplets,
  TrendingUp
} from 'lucide-react';

export default function Dashboard() {
  const navigate = useNavigate();

  const { data: bookings = [] } = useQuery({
    queryKey: ['bookings'],
    queryFn: () => base44.entities.Booking.list('-created_date', 100),
  });

  const { data: customers = [] } = useQuery({
    queryKey: ['customers'],
    queryFn: () => base44.entities.Customer.list('-created_date', 50),
  });

  const { data: washers = [] } = useQuery({
    queryKey: ['washers'],
    queryFn: () => base44.entities.Washer.filter({ status: 'active' }),
  });

  // Calculate KPIs
  const today = new Date().toISOString().split('T')[0];
  const todayBookings = bookings.filter(b => b.booking_date === today);
  const pendingBookings = bookings.filter(b => b.status === 'pending');
  const activeBookings = bookings.filter(b => ['accepted', 'on_the_way', 'in_progress'].includes(b.status));
  const completedBookings = bookings.filter(b => b.status === 'completed');
  
  const todayRevenue = todayBookings
    .filter(b => b.payment_status === 'paid')
    .reduce((sum, b) => sum + (b.total || 0), 0);
  
  const weekRevenue = bookings
    .filter(b => {
      const bookingDate = new Date(b.booking_date);
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      return bookingDate >= weekAgo && b.payment_status === 'paid';
    })
    .reduce((sum, b) => sum + (b.total || 0), 0);

  const monthRevenue = bookings
    .filter(b => {
      const bookingDate = new Date(b.booking_date);
      const monthAgo = new Date();
      monthAgo.setMonth(monthAgo.getMonth() - 1);
      return bookingDate >= monthAgo && b.payment_status === 'paid';
    })
    .reduce((sum, b) => sum + (b.total || 0), 0);

  const onlineWashers = washers.filter(w => w.online_status);

  // Chart data
  const last7Days = Array.from({ length: 7 }, (_, i) => {
    const date = new Date();
    date.setDate(date.getDate() - (6 - i));
    const dateStr = date.toISOString().split('T')[0];
    const dayBookings = bookings.filter(b => b.booking_date === dateStr);
    const dayRevenue = dayBookings
      .filter(b => b.payment_status === 'paid')
      .reduce((sum, b) => sum + (b.total || 0), 0);
    
    return {
      name: date.toLocaleDateString('en-US', { weekday: 'short' }),
      revenue: dayRevenue,
      bookings: dayBookings.length
    };
  });

  // Service popularity
  const serviceCount = {};
  bookings.forEach(b => {
    if (b.service_name) {
      serviceCount[b.service_name] = (serviceCount[b.service_name] || 0) + 1;
    }
  });
  const serviceData = Object.entries(serviceCount)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 5);

  // Activity feed
  const recentActivities = bookings.slice(0, 5).map(b => ({
    type: b.status === 'completed' ? 'booking_completed' : 
          b.status === 'cancelled' ? 'booking_cancelled' : 'booking_created',
    title: `Booking #${b.booking_id || b.id?.slice(-6)}`,
    description: `${b.customer_name} - ${b.service_name}`,
    time: new Date(b.created_date).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
  }));

  return (
    <div>
      <PageHeader 
        title="Dashboard"
        subtitle="Welcome back! Here's what's happening today."
      />

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <KPICard
          title="Today's Bookings"
          value={todayBookings.length}
          subtitle={`${pendingBookings.length} pending`}
          icon={CalendarDays}
          iconBg="bg-blue-50"
          iconColor="text-blue-600"
          trendValue="+12%"
          trend="up"
        />
        <KPICard
          title="Active Jobs"
          value={activeBookings.length}
          subtitle={`${completedBookings.length} completed today`}
          icon={Clock}
          iconBg="bg-amber-50"
          iconColor="text-amber-600"
        />
        <KPICard
          title="Today's Revenue"
          value={`$${todayRevenue.toLocaleString()}`}
          subtitle={`$${weekRevenue.toLocaleString()} this week`}
          icon={DollarSign}
          iconBg="bg-emerald-50"
          iconColor="text-emerald-600"
          trendValue="+8%"
          trend="up"
        />
        <KPICard
          title="Online Washers"
          value={`${onlineWashers.length}/${washers.length}`}
          subtitle={`${customers.length} total customers`}
          icon={Droplets}
          iconBg="bg-purple-50"
          iconColor="text-purple-600"
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 mb-8">
        <div className="xl:col-span-2">
          <RevenueChart data={last7Days} />
        </div>
        <div className="xl:col-span-1">
          <ServicesPieChart data={serviceData} />
        </div>
      </div>

      {/* Bottom Row */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="xl:col-span-2">
          <ActivityFeed activities={recentActivities} />
        </div>
        <div className="xl:col-span-1">
          <QuickActions onCreateBooking={() => navigate(createPageUrl('Bookings') + '?action=create')} />
        </div>
      </div>
    </div>
  );
}