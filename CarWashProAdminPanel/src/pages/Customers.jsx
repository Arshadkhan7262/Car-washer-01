import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import FilterBar from '@/components/Components/ui/FilterBar.jsx';
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { 
  Plus, MoreHorizontal, Phone, Mail, MapPin, Car, Calendar, 
  DollarSign, Ban, CheckCircle2, Send, Save
} from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

export default function Customers() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [confirmDialog, setConfirmDialog] = useState({ open: false, customer: null, action: '' });
  const [adminNotes, setAdminNotes] = useState('');

  const { data: customers = [], isLoading, error } = useQuery({
    queryKey: ['customers'],
    queryFn: () => base44.entities.Customer.list('-created_date', 200),
  });


  const { data: bookings = [] } = useQuery({
    queryKey: ['bookings'],
    queryFn: () => base44.entities.Booking.list('-created_date', 500),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.Customer.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['customers'] });
    }
  });

  // Helper function to get status from backend fields
  const getCustomerStatus = (customer) => {
    if (!customer) {
      return 'active'; // Default to active if customer is null/undefined
    }
    if (customer.is_blocked || !customer.is_active) {
      return 'blocked';
    }
    return 'active';
  };

  const handleToggleStatus = (customer) => {
    // Toggle between active and blocked
    const isCurrentlyBlocked = customer.is_blocked || !customer.is_active;
    updateMutation.mutate({
      id: customer.id,
      data: { 
        is_blocked: !isCurrentlyBlocked,
        is_active: !isCurrentlyBlocked
      }
    });
    setConfirmDialog({ open: false, customer: null, action: '' });
  };

  const handleSaveNotes = () => {
    if (selectedCustomer) {
      updateMutation.mutate({
        id: selectedCustomer.id,
        data: { admin_notes: adminNotes }
      });
    }
  };

  const getCustomerBookings = (customerId) => {
    return bookings.filter(b => b.customer_id === customerId);
  };

  const filteredCustomers = customers.filter(c => {
    const matchesSearch = !search ||
      c.name?.toLowerCase().includes(search.toLowerCase()) ||
      c.phone?.includes(search) ||
      c.email?.toLowerCase().includes(search.toLowerCase());
    
    // Map backend fields (is_active, is_blocked) to frontend status
    let customerStatus = 'active';
    if (c.is_blocked) {
      customerStatus = 'blocked';
    } else if (!c.is_active) {
      customerStatus = 'blocked'; // Treat inactive as blocked
    }
    
    const matchesStatus = statusFilter === 'all' || customerStatus === statusFilter;
    
    return matchesSearch && matchesStatus;
  });
  

  const columns = [
    {
      header: 'Customer',
      cell: (row) => (
        <div className="flex items-center gap-3">
          <Avatar className="w-10 h-10">
            <AvatarImage src={row.avatar} />
            <AvatarFallback className="bg-blue-100 text-blue-600">
              {row.name?.[0]}
            </AvatarFallback>
          </Avatar>
          <div>
            <p className="font-medium text-slate-900">{row.name}</p>
            <p className="text-sm text-slate-500">{row.email}</p>
          </div>
        </div>
      )
    },
    {
      header: 'Phone',
      cell: (row) => (
        <span className="text-slate-600">{row.phone}</span>
      )
    },
    {
      header: 'Bookings',
      cell: (row) => (
        <span className="font-medium text-slate-900">{row.total_bookings || 0}</span>
      )
    },
    {
      header: 'Total Spent',
      cell: (row) => (
        <span className="font-medium text-emerald-600">${row.total_spent?.toFixed(2) || '0.00'}</span>
      )
    },
    {
      header: 'Last Booking',
      cell: (row) => row.last_booking_date ? (
        <span className="text-sm text-slate-600">
          {format(new Date(row.last_booking_date), 'MMM d, yyyy')}
        </span>
      ) : (
        <span className="text-sm text-slate-400">Never</span>
      )
    },
    {
      header: 'Status',
      cell: (row) => {
        const status = row.is_blocked ? 'blocked' : (row.is_active ? 'active' : 'blocked');
        return <StatusBadge status={status} />
      }
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
            <DropdownMenuItem onClick={() => {
              setSelectedCustomer(row);
              setAdminNotes(row.admin_notes || '');
            }}>
              View Profile
            </DropdownMenuItem>
            <DropdownMenuItem 
              onClick={() => setConfirmDialog({ open: true, customer: row, action: 'toggle' })}
              className={!row.is_blocked && row.is_active ? 'text-red-600' : 'text-emerald-600'}
            >
              {!row.is_blocked && row.is_active ? (
                <>
                  <Ban className="w-4 h-4 mr-2" />
                  Block Customer
                </>
              ) : (
                <>
                  <CheckCircle2 className="w-4 h-4 mr-2" />
                  Unblock Customer
                </>
              )}
            </DropdownMenuItem>
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
        { value: 'active', label: 'Active' },
        { value: 'blocked', label: 'Blocked' },
      ]
    }
  ];

  const customerBookings = selectedCustomer ? getCustomerBookings(selectedCustomer.id) : [];

  return (
    <div>
      <PageHeader 
        title="Customers"
        subtitle={`${customers.length} registered customers`}
      />

      <FilterBar
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search by name, email or phone..."
        filters={filters}
        onClearFilters={() => {
          setSearch('');
          setStatusFilter('all');
        }}
      />

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
          <p className="text-red-800">Error loading customers: {error.message}</p>
        </div>
      )}
      <DataTable
        columns={columns}
        data={filteredCustomers}
        isLoading={isLoading}
        emptyMessage="No customers found"
        onRowClick={(row) => {
          setSelectedCustomer(row);
          setAdminNotes(row.admin_notes || '');
        }}
      />

      {/* Customer Detail Sheet */}
      <Sheet open={!!selectedCustomer} onOpenChange={() => setSelectedCustomer(null)}>
        <SheetContent className="w-full sm:max-w-xl overflow-y-auto">
          {selectedCustomer && (
            <>
              <SheetHeader className="pb-4">
                <div className="flex items-center gap-4">
                  <Avatar className="w-16 h-16">
                    <AvatarImage src={selectedCustomer.avatar} />
                    <AvatarFallback className="bg-blue-100 text-blue-600 text-xl">
                      {selectedCustomer.name?.[0]}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <SheetTitle className="text-xl">{selectedCustomer.name}</SheetTitle>
                    <StatusBadge status={getCustomerStatus(selectedCustomer)} />
                  </div>
                </div>
              </SheetHeader>

              <Tabs defaultValue="info" className="mt-6">
                <TabsList className="w-full">
                  <TabsTrigger value="info" className="flex-1">Info</TabsTrigger>
                  <TabsTrigger value="bookings" className="flex-1">
                    Bookings ({customerBookings.length})
                  </TabsTrigger>
                  <TabsTrigger value="notes" className="flex-1">Notes</TabsTrigger>
                </TabsList>

                <TabsContent value="info" className="space-y-6 mt-6">
                  {/* Contact Info */}
                  <div className="space-y-3">
                    <h4 className="text-sm font-semibold text-slate-500 uppercase">Contact</h4>
                    <div className="space-y-2">
                      <div className="flex items-center gap-3 text-sm">
                        <Phone className="w-4 h-4 text-slate-400" />
                        <span>{selectedCustomer.phone}</span>
                      </div>
                      <div className="flex items-center gap-3 text-sm">
                        <Mail className="w-4 h-4 text-slate-400" />
                        <span>{selectedCustomer.email}</span>
                      </div>
                    </div>
                  </div>

                  {/* Stats */}
                  <div className="grid grid-cols-3 gap-4">
                    <div className="bg-slate-50 rounded-xl p-4 text-center">
                      <Calendar className="w-5 h-5 text-blue-600 mx-auto mb-2" />
                      <p className="text-2xl font-bold">{selectedCustomer.total_bookings || 0}</p>
                      <p className="text-sm text-slate-500">Bookings</p>
                    </div>
                    <div className="bg-slate-50 rounded-xl p-4 text-center">
                      <DollarSign className="w-5 h-5 text-emerald-600 mx-auto mb-2" />
                      <p className="text-2xl font-bold">${selectedCustomer.total_spent?.toFixed(0) || 0}</p>
                      <p className="text-sm text-slate-500">Spent</p>
                    </div>
                    <div className="bg-slate-50 rounded-xl p-4 text-center">
                      <DollarSign className="w-5 h-5 text-purple-600 mx-auto mb-2" />
                      <p className="text-2xl font-bold">${selectedCustomer.wallet_balance?.toFixed(0) || 0}</p>
                      <p className="text-sm text-slate-500">Wallet</p>
                    </div>
                  </div>

                  {/* Addresses */}
                  {selectedCustomer.addresses?.length > 0 && (
                    <div className="space-y-3">
                      <h4 className="text-sm font-semibold text-slate-500 uppercase">Saved Addresses</h4>
                      <div className="space-y-2">
                        {selectedCustomer.addresses.map((addr, i) => (
                          <div key={i} className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                            <MapPin className="w-4 h-4 text-slate-400 mt-0.5" />
                            <div>
                              <p className="font-medium text-sm">{addr.label}</p>
                              <p className="text-sm text-slate-500">{addr.address}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Vehicles */}
                  {selectedCustomer.vehicles?.length > 0 && (
                    <div className="space-y-3">
                      <h4 className="text-sm font-semibold text-slate-500 uppercase">Saved Vehicles</h4>
                      <div className="space-y-2">
                        {selectedCustomer.vehicles.map((v, i) => (
                          <div key={i} className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                            <Car className="w-4 h-4 text-slate-400" />
                            <div>
                              <p className="font-medium text-sm">{v.make} {v.model}</p>
                              <p className="text-sm text-slate-500">{v.color} • {v.plate}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </TabsContent>

                <TabsContent value="bookings" className="mt-6">
                  <div className="space-y-3">
                    {customerBookings.length === 0 ? (
                      <p className="text-center text-slate-500 py-8">No bookings yet</p>
                    ) : (
                      customerBookings.slice(0, 10).map(b => (
                        <div key={b.id} className="p-4 bg-slate-50 rounded-xl">
                          <div className="flex items-center justify-between mb-2">
                            <span className="font-medium">#{b.booking_id || b.id?.slice(-6)}</span>
                            <StatusBadge status={b.status} />
                          </div>
                          <p className="text-sm text-slate-600">{b.service_name}</p>
                          <div className="flex items-center justify-between mt-2 text-sm text-slate-500">
                            <span>{b.booking_date && format(new Date(b.booking_date), 'MMM d, yyyy')}</span>
                            <span className="font-medium text-slate-900">${b.total?.toFixed(2)}</span>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </TabsContent>

                <TabsContent value="notes" className="mt-6">
                  <div className="space-y-4">
                    <Textarea
                      value={adminNotes}
                      onChange={(e) => setAdminNotes(e.target.value)}
                      placeholder="Add internal notes about this customer..."
                      rows={6}
                    />
                    <Button onClick={handleSaveNotes} className="w-full">
                      <Save className="w-4 h-4 mr-2" />
                      Save Notes
                    </Button>
                  </div>
                </TabsContent>
              </Tabs>

              <div className="mt-6 pt-6 border-t space-y-3">
                <Button variant="outline" className="w-full">
                  <Send className="w-4 h-4 mr-2" />
                  Send Notification
                </Button>
                <Button 
                  variant={getCustomerStatus(selectedCustomer) === 'active' ? 'destructive' : 'default'}
                  className="w-full"
                  onClick={() => setConfirmDialog({ 
                    open: true, 
                    customer: selectedCustomer, 
                    action: 'toggle' 
                  })}
                >
                  {getCustomerStatus(selectedCustomer) === 'active' ? (
                    <>
                      <Ban className="w-4 h-4 mr-2" />
                      Block Customer
                    </>
                  ) : (
                    <>
                      <CheckCircle2 className="w-4 h-4 mr-2" />
                      Unblock Customer
                    </>
                  )}
                </Button>
              </div>
            </>
          )}
        </SheetContent>
      </Sheet>

      {/* Confirm Dialog */}
      <AlertDialog open={confirmDialog.open && !!confirmDialog.customer} onOpenChange={(open) => !open && setConfirmDialog({ open: false, customer: null, action: '' })}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {confirmDialog.customer && getCustomerStatus(confirmDialog.customer) === 'active' ? 'Block Customer' : 'Unblock Customer'}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {confirmDialog.customer && getCustomerStatus(confirmDialog.customer) === 'active' 
                ? `Are you sure you want to block ${confirmDialog.customer?.name}? They won't be able to make new bookings.`
                : confirmDialog.customer ? `Are you sure you want to unblock ${confirmDialog.customer?.name}?` : ''
              }
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={() => confirmDialog.customer && handleToggleStatus(confirmDialog.customer)}>
              {confirmDialog.customer && getCustomerStatus(confirmDialog.customer) === 'active' ? 'Block' : 'Unblock'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}