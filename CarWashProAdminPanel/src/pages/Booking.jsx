import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import FilterBar from '@/components/Components/ui/FilterBar.jsx';
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import BookingDetailDrawer from '@/components/Components/bookings/BookingDetailDrawer.jsx';
import CreateBookingModal from '@/components/Components/bookings/CreateBookingModal.jsx';
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, Eye, MoreHorizontal, UserPlus, CheckCircle2, XCircle } from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export default function Bookings() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [paymentFilter, setPaymentFilter] = useState('all');
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [activeTab, setActiveTab] = useState('all');

  // Check for action param
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (params.get('action') === 'create') {
      setShowCreateModal(true);
    }
  }, []);

  const { data: bookings = [], isLoading } = useQuery({
    queryKey: ['bookings'],
    queryFn: () => base44.entities.Booking.list('-created_date', 200),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.Booking.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      toast.success('Status updated successfully');
    },
    onError: (error) => {
      console.error('Error updating status:', error);
      toast.error(error.message || 'Failed to update status');
    }
  });

  const handleStatusChange = (id, newStatus, note = '') => {
    // MongoDB returns _id, but we might receive id from frontend
    // Use the id parameter directly as it should be the MongoDB _id
    updateMutation.mutate({
      id: id, // This should be MongoDB _id format
      data: {
        status: newStatus,
        status_note: note || undefined,
        // Don't send timeline - backend will handle it automatically
      }
    });
    setSelectedBooking(null);
  };

  const assignWasherMutation = useMutation({
    mutationFn: ({ id, washerId, washerName }) => 
      base44.entities.Booking.assignWasher(id, washerId, washerName),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      toast.success('Washer assigned successfully');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to assign washer');
    }
  });

  const handleAssignWasher = (bookingId, washer) => {
    // bookingId should already be MongoDB _id format
    assignWasherMutation.mutate({
      id: bookingId,
      washerId: washer.id || washer._id,
      washerName: washer.name
    });
  };

  const tabCounts = {
    all: bookings.length,
    pending: bookings.filter(b => b.status === 'pending').length,
    active: bookings.filter(b => ['accepted', 'on_the_way', 'in_progress'].includes(b.status)).length,
    completed: bookings.filter(b => b.status === 'completed').length,
    cancelled: bookings.filter(b => b.status === 'cancelled').length,
  };

  const filteredBookings = bookings.filter(b => {
    const matchesSearch = !search || 
      b.booking_id?.toLowerCase().includes(search.toLowerCase()) ||
      b.customer_name?.toLowerCase().includes(search.toLowerCase()) ||
      b.customer_phone?.includes(search);
    
    const matchesStatus = statusFilter === 'all' || b.status === statusFilter;
    const matchesPayment = paymentFilter === 'all' || b.payment_status === paymentFilter;
    
    const matchesTab = activeTab === 'all' ? true :
      activeTab === 'pending' ? b.status === 'pending' :
      activeTab === 'active' ? ['accepted', 'on_the_way', 'in_progress'].includes(b.status) :
      activeTab === 'completed' ? b.status === 'completed' :
      activeTab === 'cancelled' ? b.status === 'cancelled' : true;
    
    return matchesSearch && matchesStatus && matchesPayment && matchesTab;
  });

  const columns = [
    {
      header: 'Booking',
      cell: (row) => (
        <div>
          <p className="font-medium text-slate-900">#{row.booking_id || row._id?.slice(-6) || row.id?.slice(-6)}</p>
          <p className="text-sm text-slate-500">
            {row.created_date && format(new Date(row.created_date), 'MMM d, h:mm a')}
          </p>
        </div>
      )
    },
    {
      header: 'Customer',
      cell: (row) => (
        <div className="flex items-center gap-3">
          <Avatar className="w-8 h-8">
            <AvatarFallback className="bg-slate-100 text-slate-600 text-xs">
              {row.customer_name?.[0]}
            </AvatarFallback>
          </Avatar>
          <div>
            <p className="font-medium text-slate-900">{row.customer_name}</p>
            <p className="text-sm text-slate-500">{row.customer_phone}</p>
          </div>
        </div>
      )
    },
    {
      header: 'Service',
      cell: (row) => (
        <div>
          <p className="font-medium text-slate-900">{row.service_name}</p>
          <p className="text-sm text-slate-500 capitalize">{row.vehicle_type}</p>
        </div>
      )
    },
    {
      header: 'Schedule',
      cell: (row) => (
        <div>
          <p className="text-sm text-slate-900">
            {row.booking_date && format(new Date(row.booking_date), 'MMM d, yyyy')}
          </p>
          <p className="text-sm text-slate-500">{row.time_slot}</p>
        </div>
      )
    },
    {
      header: 'Amount',
      cell: (row) => (
        <span className="font-medium text-slate-900">${row.total?.toFixed(2) || '0.00'}</span>
      )
    },
    {
      header: 'Status',
      cell: (row) => (
        <div className="flex flex-col gap-1">
          <StatusBadge status={row.status} />
          <StatusBadge status={row.payment_status} />
        </div>
      )
    },
    {
      header: 'Washer',
      cell: (row) => row.washer_name ? (
        <div className="flex items-center gap-2">
          <Avatar className="w-6 h-6">
            <AvatarFallback className="text-xs bg-purple-100 text-purple-600">
              {row.washer_name?.[0]}
            </AvatarFallback>
          </Avatar>
          <span className="text-sm">{row.washer_name}</span>
        </div>
      ) : (
        <span className="text-sm text-slate-400">Unassigned</span>
      )
    },
    {
      header: '',
      cell: (row) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon">
              <MoreHorizontal className="w-4 h-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => setSelectedBooking(row)}>
              <Eye className="w-4 h-4 mr-2" />
              View Details
            </DropdownMenuItem>
            {row.status === 'pending' && (
              <DropdownMenuItem onClick={() => handleStatusChange(String(row._id || row.id), 'accepted')}>
                <CheckCircle2 className="w-4 h-4 mr-2 text-emerald-600" />
                Accept
              </DropdownMenuItem>
            )}
            {row.status !== 'cancelled' && row.status !== 'completed' && (
              <DropdownMenuItem 
                onClick={() => handleStatusChange(String(row._id || row.id), 'cancelled')}
                className="text-red-600"
              >
                <XCircle className="w-4 h-4 mr-2" />
                Cancel
              </DropdownMenuItem>
            )}
          </DropdownMenuContent>
        </DropdownMenu>
      ),
      className: 'w-12'
    }
  ];

  const filters = [
    {
      placeholder: 'Status',
      value: statusFilter,
      onChange: setStatusFilter,
      options: [
        { value: 'pending', label: 'Pending' },
        { value: 'accepted', label: 'Accepted' },
        { value: 'on_the_way', label: 'On The Way' },
        { value: 'in_progress', label: 'In Progress' },
        { value: 'completed', label: 'Completed' },
        { value: 'cancelled', label: 'Cancelled' },
      ]
    },
    {
      placeholder: 'Payment',
      value: paymentFilter,
      onChange: setPaymentFilter,
      options: [
        { value: 'paid', label: 'Paid' },
        { value: 'unpaid', label: 'Unpaid' },
        { value: 'refunded', label: 'Refunded' },
      ]
    }
  ];

  return (
    <div>
      <PageHeader 
        title="Bookings"
        subtitle={`${bookings.length} total bookings`}
        actions={
          <Button onClick={() => setShowCreateModal(true)}>
            <Plus className="w-4 h-4 mr-2" />
            New Booking
          </Button>
        }
      />

      <Tabs value={activeTab} onValueChange={setActiveTab} className="mb-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="all">
            All ({tabCounts.all})
          </TabsTrigger>
          <TabsTrigger value="pending" className="data-[state=active]:text-amber-600">
            Pending ({tabCounts.pending})
          </TabsTrigger>
          <TabsTrigger value="active" className="data-[state=active]:text-blue-600">
            Active ({tabCounts.active})
          </TabsTrigger>
          <TabsTrigger value="completed" className="data-[state=active]:text-emerald-600">
            Completed ({tabCounts.completed})
          </TabsTrigger>
          <TabsTrigger value="cancelled" className="data-[state=active]:text-red-600">
            Cancelled ({tabCounts.cancelled})
          </TabsTrigger>
        </TabsList>
      </Tabs>

      <FilterBar
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search by ID, customer name or phone..."
        filters={filters}
        onClearFilters={() => {
          setSearch('');
          setStatusFilter('all');
          setPaymentFilter('all');
        }}
      />

      <DataTable
        columns={columns}
        data={filteredBookings}
        isLoading={isLoading}
        emptyMessage="No bookings found"
        onRowClick={(row) => setSelectedBooking(row)}
      />

      <BookingDetailDrawer
        booking={selectedBooking}
        open={!!selectedBooking}
        onClose={() => setSelectedBooking(null)}
        onStatusChange={handleStatusChange}
        onAssignWasher={handleAssignWasher}
      />

      <CreateBookingModal
        open={showCreateModal}
        onClose={() => setShowCreateModal(false)}
      />
    </div>
  );
}