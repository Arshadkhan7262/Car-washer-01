import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { format, subDays, startOfMonth, endOfMonth, eachDayOfInterval } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { 
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts';
import { 
  Download, DollarSign, Calendar, TrendingUp, Users, 
  Star, BarChart3
} from 'lucide-react';
import DataTable from '@/components/Components/ui/DataTable.jsx';

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4'];

export default function Reports() {
  const [dateRange, setDateRange] = useState('30days');
  const [startDate, setStartDate] = useState(format(subDays(new Date(), 30), 'yyyy-MM-dd'));
  const [endDate, setEndDate] = useState(format(new Date(), 'yyyy-MM-dd'));

  const { data: bookings = [] } = useQuery({
    queryKey: ['bookings'],
    queryFn: () => base44.entities.Booking.list('-created_date', 1000),
  });

  const { data: customers = [] } = useQuery({
    queryKey: ['customers'],
    queryFn: () => base44.entities.Customer.list(),
  });

  const { data: washers = [] } = useQuery({
    queryKey: ['washers'],
    queryFn: () => base44.entities.Washer.filter({ status: 'active' }),
  });

  // Filter bookings by date range
  const filteredBookings = bookings.filter(b => {
    if (!b.booking_date) return false;
    return b.booking_date >= startDate && b.booking_date <= endDate;
  });

  // Revenue data
  const totalRevenue = filteredBookings
    .filter(b => b.payment_status === 'paid')
    .reduce((sum, b) => sum + (b.total || 0), 0);

  const totalBookings = filteredBookings.length;
  const completedBookings = filteredBookings.filter(b => b.status === 'completed').length;
  const avgBookingValue = totalBookings > 0 ? totalRevenue / totalBookings : 0;

  // Daily revenue chart
  const days = eachDayOfInterval({
    start: new Date(startDate),
    end: new Date(endDate)
  });

  const dailyData = days.map(day => {
    const dateStr = format(day, 'yyyy-MM-dd');
    const dayBookings = filteredBookings.filter(b => b.booking_date === dateStr);
    const dayRevenue = dayBookings
      .filter(b => b.payment_status === 'paid')
      .reduce((sum, b) => sum + (b.total || 0), 0);
    
    return {
      name: format(day, 'MMM d'),
      revenue: dayRevenue,
      bookings: dayBookings.length
    };
  });

  // Service popularity
  const serviceCount = {};
  filteredBookings.forEach(b => {
    if (b.service_name) {
      serviceCount[b.service_name] = (serviceCount[b.service_name] || 0) + 1;
    }
  });
  const serviceData = Object.entries(serviceCount)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);

  // Washer performance
  const washerPerformance = washers.map(w => ({
    name: w.name,
    jobs: w.jobs_completed || 0,
    rating: w.rating || 0,
    earnings: w.total_earnings || 0,
    completion_rate: w.jobs_completed > 0 
      ? Math.round((1 - (w.jobs_cancelled / w.jobs_completed)) * 100)
      : 100
  })).sort((a, b) => b.jobs - a.jobs);

  // Payment methods
  const paymentMethods = {};
  filteredBookings.forEach(b => {
    if (b.payment_method) {
      paymentMethods[b.payment_method] = (paymentMethods[b.payment_method] || 0) + 1;
    }
  });
  const paymentData = Object.entries(paymentMethods)
    .map(([name, value]) => ({ 
      name: name.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()), 
      value 
    }));

  const handleExport = () => {
    // Simple CSV export
    const headers = ['Date', 'Booking ID', 'Customer', 'Service', 'Amount', 'Status', 'Payment Status'];
    const rows = filteredBookings.map(b => [
      b.booking_date,
      b.booking_id || b.id?.slice(-6),
      b.customer_name,
      b.service_name,
      b.total,
      b.status,
      b.payment_status
    ]);
    
    const csv = [headers, ...rows].map(row => row.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bookings-report-${startDate}-to-${endDate}.csv`;
    a.click();
  };

  const washerColumns = [
    { header: 'Washer', accessor: 'name' },
    { header: 'Jobs Completed', accessor: 'jobs' },
    { 
      header: 'Rating', 
      cell: (row) => (
        <div className="flex items-center gap-1">
          <Star className="w-4 h-4 text-amber-400 fill-amber-400" />
          {row.rating.toFixed(1)}
        </div>
      )
    },
    { 
      header: 'Completion Rate', 
      cell: (row) => `${row.completion_rate}%` 
    },
    { 
      header: 'Total Earnings', 
      cell: (row) => `$${row.earnings.toFixed(2)}` 
    }
  ];

  return (
    <div>
      <PageHeader 
        title="Reports & Analytics"
        subtitle="Business performance insights"
        actions={
          <Button onClick={handleExport}>
            <Download className="w-4 h-4 mr-2" />
            Export CSV
          </Button>
        }
      />

      {/* Date Range Filter */}
      <Card className="mb-6">
        <CardContent className="py-4">
          <div className="flex flex-wrap items-center gap-4">
            <div className="flex items-center gap-2">
              <Label>Quick Range:</Label>
              <Select 
                value={dateRange} 
                onValueChange={(v) => {
                  setDateRange(v);
                  if (v === '7days') {
                    setStartDate(format(subDays(new Date(), 7), 'yyyy-MM-dd'));
                    setEndDate(format(new Date(), 'yyyy-MM-dd'));
                  } else if (v === '30days') {
                    setStartDate(format(subDays(new Date(), 30), 'yyyy-MM-dd'));
                    setEndDate(format(new Date(), 'yyyy-MM-dd'));
                  } else if (v === 'month') {
                    setStartDate(format(startOfMonth(new Date()), 'yyyy-MM-dd'));
                    setEndDate(format(endOfMonth(new Date()), 'yyyy-MM-dd'));
                  }
                }}
              >
                <SelectTrigger className="w-[150px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="7days">Last 7 Days</SelectItem>
                  <SelectItem value="30days">Last 30 Days</SelectItem>
                  <SelectItem value="month">This Month</SelectItem>
                  <SelectItem value="custom">Custom</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center gap-2">
              <Input
                type="date"
                value={startDate}
                onChange={(e) => {
                  setStartDate(e.target.value);
                  setDateRange('custom');
                }}
                className="w-[150px]"
              />
              <span>to</span>
              <Input
                type="date"
                value={endDate}
                onChange={(e) => {
                  setEndDate(e.target.value);
                  setDateRange('custom');
                }}
                className="w-[150px]"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-xl bg-emerald-50">
                <DollarSign className="w-5 h-5 text-emerald-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">Total Revenue</p>
                <p className="text-2xl font-bold text-emerald-600">${totalRevenue.toFixed(2)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-xl bg-blue-50">
                <Calendar className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">Total Bookings</p>
                <p className="text-2xl font-bold">{totalBookings}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-xl bg-purple-50">
                <TrendingUp className="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">Avg. Booking Value</p>
                <p className="text-2xl font-bold">${avgBookingValue.toFixed(2)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-xl bg-amber-50">
                <Users className="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">Completion Rate</p>
                <p className="text-2xl font-bold">
                  {totalBookings > 0 ? Math.round((completedBookings / totalBookings) * 100) : 0}%
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="revenue" className="space-y-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="revenue">Revenue</TabsTrigger>
          <TabsTrigger value="services">Services</TabsTrigger>
          <TabsTrigger value="washers">Washer Performance</TabsTrigger>
          <TabsTrigger value="payments">Payment Methods</TabsTrigger>
        </TabsList>

        <TabsContent value="revenue">
          <Card>
            <CardHeader>
              <CardTitle>Revenue & Bookings Trend</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="h-[400px]">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={dailyData}>
                    <defs>
                      <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.1}/>
                        <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                    <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12 }} tickFormatter={(v) => `$${v}`} />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: 'white', 
                        border: '1px solid #e2e8f0',
                        borderRadius: '12px'
                      }}
                      formatter={(value, name) => [
                        name === 'revenue' ? `$${value}` : value,
                        name === 'revenue' ? 'Revenue' : 'Bookings'
                      ]}
                    />
                    <Legend />
                    <Area 
                      type="monotone" 
                      dataKey="revenue" 
                      stroke="#3b82f6" 
                      strokeWidth={2}
                      fillOpacity={1} 
                      fill="url(#colorRevenue)" 
                      name="Revenue"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="services">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Service Popularity</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={serviceData}
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={100}
                        paddingAngle={4}
                        dataKey="value"
                        label={(entry) => entry.name}
                      >
                        {serviceData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>Bookings by Service</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-[300px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={serviceData} layout="vertical">
                      <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                      <XAxis type="number" axisLine={false} tickLine={false} />
                      <YAxis type="category" dataKey="name" axisLine={false} tickLine={false} width={100} />
                      <Tooltip />
                      <Bar dataKey="value" fill="#3b82f6" radius={[0, 4, 4, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="washers">
          <Card>
            <CardHeader>
              <CardTitle>Washer Performance</CardTitle>
            </CardHeader>
            <CardContent>
              <DataTable
                columns={washerColumns}
                data={washerPerformance}
                emptyMessage="No washer data available"
              />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="payments">
          <Card>
            <CardHeader>
              <CardTitle>Payment Methods Distribution</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="h-[300px]">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={paymentData}
                      cx="50%"
                      cy="50%"
                      outerRadius={100}
                      dataKey="value"
                      label={(entry) => `${entry.name}: ${entry.value}`}
                    >
                      {paymentData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}