import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import FilterBar from '@/components/Components/ui/FilterBar.jsx';
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { 
  CreditCard, DollarSign, Wallet, ArrowDownCircle, 
  CheckCircle2, XCircle, Clock, MoreHorizontal
} from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";

export default function Payments() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [methodFilter, setMethodFilter] = useState('all');
  const [showRefundModal, setShowRefundModal] = useState(null);
  const [refundReason, setRefundReason] = useState('');

  const { data: payments = [], isLoading: paymentsLoading } = useQuery({
    queryKey: ['payments'],
    queryFn: () => base44.entities.Payment.list('-created_date', 200),
  });

  const { data: withdrawals = [], isLoading: withdrawalsLoading } = useQuery({
    queryKey: ['washer-transactions'],
    queryFn: () => base44.entities.WasherTransaction.filter({ type: 'withdrawal' }),
  });

  const refundMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.Payment.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['payments'] });
      setShowRefundModal(null);
      setRefundReason('');
    }
  });

  const withdrawalMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.WasherTransaction.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['washer-transactions'] });
    }
  });

  const handleRefund = () => {
    if (showRefundModal) {
      refundMutation.mutate({
        id: showRefundModal.id,
        data: { 
          status: 'refunded', 
          refund_reason: refundReason,
          refund_amount: showRefundModal.amount
        }
      });
    }
  };

  const handleWithdrawalAction = (withdrawal, status) => {
    withdrawalMutation.mutate({
      id: withdrawal.id,
      data: { status }
    });
  };

  // Stats
  const totalRevenue = payments
    .filter(p => p.status === 'completed')
    .reduce((sum, p) => sum + (p.amount || 0), 0);
  
  const pendingWithdrawals = withdrawals.filter(w => w.status === 'pending');
  const pendingAmount = pendingWithdrawals.reduce((sum, w) => sum + (w.amount || 0), 0);

  const filteredPayments = payments.filter(p => {
    const matchesSearch = !search ||
      p.booking_id?.toLowerCase().includes(search.toLowerCase()) ||
      p.customer_name?.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
    const matchesMethod = methodFilter === 'all' || p.method === methodFilter;
    return matchesSearch && matchesStatus && matchesMethod;
  });

  const paymentColumns = [
    {
      header: 'Transaction',
      cell: (row) => (
        <div>
          <p className="font-medium text-slate-900">#{row.transaction_id || row.id?.slice(-8)}</p>
          <p className="text-sm text-slate-500">Booking: #{row.booking_id?.slice(-6)}</p>
        </div>
      )
    },
    {
      header: 'Customer',
      cell: (row) => (
        <span className="text-slate-600">{row.customer_name}</span>
      )
    },
    {
      header: 'Amount',
      cell: (row) => (
        <span className="font-semibold text-slate-900">${row.amount?.toFixed(2)}</span>
      )
    },
    {
      header: 'Method',
      cell: (row) => (
        <div className="flex items-center gap-2">
          <CreditCard className="w-4 h-4 text-slate-400" />
          <span className="capitalize text-sm">{row.method?.replace(/_/g, ' ')}</span>
        </div>
      )
    },
    {
      header: 'Date',
      cell: (row) => (
        <span className="text-sm text-slate-600">
          {row.created_date && format(new Date(row.created_date), 'MMM d, h:mm a')}
        </span>
      )
    },
    {
      header: 'Status',
      cell: (row) => <StatusBadge status={row.status} />
    },
    {
      header: '',
      cell: (row) => row.status === 'completed' && (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon">
              <MoreHorizontal className="w-4 h-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem 
              onClick={() => setShowRefundModal(row)}
              className="text-red-600"
            >
              Refund Payment
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
      className: 'w-12'
    }
  ];

  const withdrawalColumns = [
    {
      header: 'Washer',
      cell: (row) => (
        <span className="font-medium text-slate-900">{row.washer_name}</span>
      )
    },
    {
      header: 'Amount',
      cell: (row) => (
        <span className="font-semibold text-emerald-600">${row.amount?.toFixed(2)}</span>
      )
    },
    {
      header: 'Bank Details',
      cell: (row) => (
        <span className="text-sm text-slate-600">{row.bank_details || '-'}</span>
      )
    },
    {
      header: 'Date',
      cell: (row) => (
        <span className="text-sm text-slate-600">
          {row.created_date && format(new Date(row.created_date), 'MMM d, h:mm a')}
        </span>
      )
    },
    {
      header: 'Status',
      cell: (row) => <StatusBadge status={row.status} />
    },
    {
      header: '',
      cell: (row) => row.status === 'pending' && (
        <div className="flex items-center gap-2">
          <Button 
            size="sm" 
            variant="outline"
            className="text-emerald-600"
            onClick={() => handleWithdrawalAction(row, 'approved')}
          >
            <CheckCircle2 className="w-4 h-4 mr-1" />
            Approve
          </Button>
          <Button 
            size="sm" 
            variant="outline"
            className="text-red-600"
            onClick={() => handleWithdrawalAction(row, 'rejected')}
          >
            <XCircle className="w-4 h-4 mr-1" />
            Reject
          </Button>
        </div>
      )
    }
  ];

  const filters = [
    {
      placeholder: 'Status',
      value: statusFilter,
      onChange: setStatusFilter,
      options: [
        { value: 'pending', label: 'Pending' },
        { value: 'completed', label: 'Completed' },
        { value: 'failed', label: 'Failed' },
        { value: 'refunded', label: 'Refunded' },
      ]
    },
    {
      placeholder: 'Method',
      value: methodFilter,
      onChange: setMethodFilter,
      options: [
        { value: 'cash', label: 'Cash' },
        { value: 'card', label: 'Card' },
        { value: 'apple_pay', label: 'Apple Pay' },
        { value: 'google_pay', label: 'Google Pay' },
        { value: 'wallet', label: 'Wallet' },
      ]
    }
  ];

  return (
    <div>
      <PageHeader 
        title="Payments"
        subtitle="Manage payments and washer payouts"
      />

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-8">
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-emerald-50">
              <DollarSign className="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Total Revenue</p>
              <p className="text-2xl font-bold text-emerald-600">${totalRevenue.toFixed(2)}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-blue-50">
              <CreditCard className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Total Transactions</p>
              <p className="text-2xl font-bold">{payments.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-amber-50">
              <Clock className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Pending Withdrawals</p>
              <p className="text-2xl font-bold">{pendingWithdrawals.length} (${pendingAmount.toFixed(2)})</p>
            </div>
          </div>
        </div>
      </div>

      <Tabs defaultValue="payments" className="space-y-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="payments">Payments ({payments.length})</TabsTrigger>
          <TabsTrigger value="withdrawals">
            Withdrawals 
            {pendingWithdrawals.length > 0 && (
              <span className="ml-2 px-2 py-0.5 rounded-full bg-amber-100 text-amber-700 text-xs">
                {pendingWithdrawals.length}
              </span>
            )}
          </TabsTrigger>
        </TabsList>

        <TabsContent value="payments">
          <FilterBar
            searchValue={search}
            onSearchChange={setSearch}
            searchPlaceholder="Search by booking ID or customer..."
            filters={filters}
            onClearFilters={() => {
              setSearch('');
              setStatusFilter('all');
              setMethodFilter('all');
            }}
          />

          <DataTable
            columns={paymentColumns}
            data={filteredPayments}
            isLoading={paymentsLoading}
            emptyMessage="No payments found"
          />
        </TabsContent>

        <TabsContent value="withdrawals">
          <DataTable
            columns={withdrawalColumns}
            data={withdrawals}
            isLoading={withdrawalsLoading}
            emptyMessage="No withdrawal requests"
          />
        </TabsContent>
      </Tabs>

      {/* Refund Modal */}
      <Dialog open={!!showRefundModal} onOpenChange={() => setShowRefundModal(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Refund Payment</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="bg-slate-50 rounded-lg p-4">
              <p className="text-sm text-slate-500">Refund Amount</p>
              <p className="text-2xl font-bold">${showRefundModal?.amount?.toFixed(2)}</p>
            </div>
            <div className="space-y-2">
              <Label>Reason for Refund</Label>
              <Textarea
                value={refundReason}
                onChange={(e) => setRefundReason(e.target.value)}
                placeholder="Enter reason..."
                rows={3}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRefundModal(null)}>Cancel</Button>
            <Button variant="destructive" onClick={handleRefund}>
              Process Refund
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}