import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import { toast } from 'sonner';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import FilterBar from '@/components/Components/ui/FilterBar.jsx';
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { 
  CreditCard, DollarSign, Wallet, ArrowDownCircle, 
  CheckCircle2, XCircle, Clock, MoreHorizontal, Settings, Zap
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
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
} from "@/components/ui/card";

export default function Payments() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [methodFilter, setMethodFilter] = useState('all');
  const [withdrawalStatusFilter, setWithdrawalStatusFilter] = useState('all');
  const [activeTab, setActiveTab] = useState('payments');
  const [showRefundModal, setShowRefundModal] = useState(null);
  const [showRejectModal, setShowRejectModal] = useState(null);
  const [showApproveModal, setShowApproveModal] = useState(null);
  const [showLimitModal, setShowLimitModal] = useState(false);
  const [refundReason, setRefundReason] = useState('');
  const [rejectReason, setRejectReason] = useState('');
  const [newLimit, setNewLimit] = useState('');
  const [adminNote, setAdminNote] = useState('');

  // Check URL params for tab navigation
  useEffect(() => {
    try {
      const params = new URLSearchParams(window.location.search);
      const tab = params.get('tab');
      const status = params.get('status');
      if (tab === 'withdrawals') {
        setActiveTab('withdrawals');
        if (status) {
          setWithdrawalStatusFilter(status);
        }
      }
    } catch (error) {
      // Silently handle URL parsing errors
    }
  }, []);

  const { data: payments = [], isLoading: paymentsLoading, error: paymentsError } = useQuery({
    queryKey: ['payments'],
    queryFn: async () => {
      try {
        const result = await base44.entities.Payment.list('-created_date', 200);
        return result;
      } catch (error) {
        throw error;
      }
    },
  });

  const { data: withdrawalsData, isLoading: withdrawalsLoading, error: withdrawalsError } = useQuery({
    queryKey: ['withdrawals', withdrawalStatusFilter],
    queryFn: async () => {
      try {
        const result = await base44.entities.Withdrawal.list(
          withdrawalStatusFilter !== 'all' ? { status: withdrawalStatusFilter } : {}
        );
        return result;
      } catch (error) {
        throw error;
      }
    },
    refetchInterval: 30000, // Auto-refresh every 30 seconds to show new withdrawal requests
  });

  const withdrawals = withdrawalsData || [];

  const { data: withdrawalLimit = 2000 } = useQuery({
    queryKey: ['withdrawal-limit'],
    queryFn: () => base44.entities.Withdrawal.getLimit(),
  });

  const refundMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.Payment.update(id, data),
    onSuccess: () => {
      toast.success('Refund processed successfully');
      queryClient.invalidateQueries({ queryKey: ['payments'] });
      setShowRefundModal(null);
      setRefundReason('');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to process refund');
    }
  });

  const approveMutation = useMutation({
    mutationFn: ({ id, note }) => base44.entities.Withdrawal.approve(id, note),
    onSuccess: () => {
      toast.success('Withdrawal approved successfully');
      queryClient.invalidateQueries({ queryKey: ['withdrawals'] });
      setShowApproveModal(null);
      setAdminNote('');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to approve withdrawal');
    }
  });

  const processMutation = useMutation({
    mutationFn: (id) => base44.entities.Withdrawal.process(id),
    onSuccess: () => {
      toast.success('Withdrawal processed successfully via Stripe');
      queryClient.invalidateQueries({ queryKey: ['withdrawals'] });
      queryClient.invalidateQueries({ queryKey: ['washers'] }); // Refresh washer wallet balance
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to process withdrawal');
    }
  });

  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }) => base44.entities.Withdrawal.reject(id, reason),
    onSuccess: () => {
      toast.success('Withdrawal rejected');
      queryClient.invalidateQueries({ queryKey: ['withdrawals'] });
      setShowRejectModal(null);
      setRejectReason('');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to reject withdrawal');
    }
  });

  const setLimitMutation = useMutation({
    mutationFn: (limit) => base44.entities.Withdrawal.setLimit(limit),
    onSuccess: () => {
      toast.success('Withdrawal limit updated successfully');
      queryClient.invalidateQueries({ queryKey: ['withdrawal-limit'] });
      setShowLimitModal(false);
      setNewLimit('');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to update withdrawal limit');
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

  const handleApprove = () => {
    if (showApproveModal) {
      approveMutation.mutate({
        id: showApproveModal._id || showApproveModal.id,
        note: adminNote || null
      });
    }
  };

  const handleProcess = (withdrawal) => {
    if (confirm(`Process withdrawal of $${withdrawal.amount?.toFixed(2)} via Stripe? This will deduct from washer's wallet.`)) {
      processMutation.mutate(withdrawal._id || withdrawal.id);
    }
  };

  const handleReject = () => {
    if (showRejectModal && rejectReason.trim()) {
      rejectMutation.mutate({
        id: showRejectModal._id || showRejectModal.id,
        reason: rejectReason
      });
    } else {
      toast.error('Please provide a rejection reason');
    }
  };

  const handleSetLimit = () => {
    const limit = parseFloat(newLimit);
    if (isNaN(limit) || limit < 0) {
      toast.error('Please enter a valid limit amount');
      return;
    }
    setLimitMutation.mutate(limit);
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
      cell: (row) => {
        const washer = row.washer_id || row.washer;
        return (
          <div>
            <p className="font-medium text-slate-900">{washer?.name || row.washer_name || 'Unknown'}</p>
            {washer?.email && (
              <p className="text-xs text-slate-500">{washer.email}</p>
            )}
          </div>
        );
      }
    },
    {
      header: 'Amount',
      cell: (row) => (
        <span className="font-semibold text-emerald-600">${row.amount?.toFixed(2)}</span>
      )
    },
    {
      header: 'Payment Method',
      cell: (row) => (
        <div className="flex items-center gap-2">
          <CreditCard className="w-4 h-4 text-slate-400" />
          <span className="capitalize text-sm">{row.payment_method?.replace(/_/g, ' ') || 'stripe'}</span>
        </div>
      )
    },
    {
      header: 'Requested Date',
      cell: (row) => (
        <span className="text-sm text-slate-600">
          {row.requested_date && format(new Date(row.requested_date), 'MMM d, h:mm a')}
        </span>
      )
    },
    {
      header: 'Status',
      cell: (row) => <StatusBadge status={row.status} />
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


  // Safety check for withdrawalLimit
  const safeWithdrawalLimit = typeof withdrawalLimit === 'number' ? withdrawalLimit : 2000;

  return (
    <div>
      <PageHeader 
        title="Payments"
        subtitle="Manage payments and washer payouts"
        actions={
          <Button 
            variant="outline" 
            onClick={() => setShowLimitModal(true)}
            className="gap-2"
          >
            <Settings className="w-4 h-4" />
            Withdrawal Limit: ${safeWithdrawalLimit.toFixed(2)}
          </Button>
        }
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

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
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
          <div className="mb-4 flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Label>Filter by Status:</Label>
              <select
                value={withdrawalStatusFilter}
                onChange={(e) => setWithdrawalStatusFilter(e.target.value)}
                className="px-3 py-1.5 border border-slate-300 rounded-md text-sm"
              >
                <option value="all">All</option>
                <option value="pending">Pending</option>
                <option value="approved">Approved</option>
                <option value="processing">Processing</option>
                <option value="completed">Completed</option>
                <option value="rejected">Rejected</option>
              </select>
            </div>
          </div>
          {withdrawalsLoading ? (
            <div className="bg-white rounded-2xl border border-slate-100 p-12 text-center">
              <p className="text-slate-500">Loading...</p>
            </div>
          ) : withdrawals.length === 0 ? (
            <div className="bg-white rounded-2xl border border-slate-100 p-12 text-center">
              <p className="text-slate-500">No withdrawal requests</p>
            </div>
          ) : (
            <div className="space-y-4">
              {withdrawals.map((row) => (
                <Card key={row._id || row.id} className="overflow-hidden">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <div className="flex-1 grid grid-cols-5 gap-4">
                        <div>
                          <p className="text-xs text-slate-500 mb-1">Washer</p>
                          <p className="font-medium text-slate-900">{row.washer_name || 'Unknown'}</p>
                        </div>
                        <div>
                          <p className="text-xs text-slate-500 mb-1">Amount</p>
                          <p className="font-semibold text-emerald-600">${row.amount?.toFixed(2)}</p>
                        </div>
                        <div>
                          <p className="text-xs text-slate-500 mb-1">Method</p>
                          <p className="text-sm capitalize">{row.payment_method?.replace(/_/g, ' ') || 'stripe'}</p>
                        </div>
                        <div>
                          <p className="text-xs text-slate-500 mb-1">Requested</p>
                          <p className="text-sm text-slate-600">
                            {row.requested_date && format(new Date(row.requested_date), 'MMM d, h:mm a')}
                          </p>
                        </div>
                        <div>
                          <p className="text-xs text-slate-500 mb-1">Status</p>
                          <StatusBadge status={row.status} />
                        </div>
                      </div>
                      <div className="ml-4 flex items-center gap-2">
                        {row.status === 'pending' && (
                          <>
                            <Button 
                              size="sm" 
                              variant="outline"
                              className="text-emerald-600"
                              onClick={() => {
                                setShowApproveModal(row);
                                setAdminNote('');
                              }}
                              disabled={approveMutation.isPending}
                            >
                              <CheckCircle2 className="w-4 h-4 mr-1" />
                              Approve
                            </Button>
                            <Button 
                              size="sm" 
                              variant="outline"
                              className="text-red-600"
                              onClick={() => setShowRejectModal(row)}
                              disabled={rejectMutation.isPending}
                            >
                              <XCircle className="w-4 h-4 mr-1" />
                              Reject
                            </Button>
                          </>
                        )}
                        {row.status === 'approved' && (
                          <Button 
                            size="sm" 
                            className="bg-emerald-600 hover:bg-emerald-700"
                            onClick={() => handleProcess(row)}
                            disabled={processMutation.isPending}
                          >
                            <Zap className="w-4 h-4 mr-1" />
                            {processMutation.isPending ? 'Processing...' : 'Process via Stripe'}
                          </Button>
                        )}
                        {row.status === 'completed' && row.stripe_transfer_id && (
                          <span className="text-xs text-slate-500">
                            Stripe: {row.stripe_transfer_id.slice(-8)}
                          </span>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
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
            <Button 
              variant="destructive" 
              onClick={handleRefund}
              disabled={refundMutation.isPending}
            >
              {refundMutation.isPending ? 'Processing...' : 'Process Refund'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reject Withdrawal Modal */}
      <Dialog open={!!showRejectModal} onOpenChange={() => setShowRejectModal(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Withdrawal Request</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="bg-slate-50 rounded-lg p-4">
              <p className="text-sm text-slate-500">Withdrawal Amount</p>
              <p className="text-2xl font-bold">${showRejectModal?.amount?.toFixed(2)}</p>
            </div>
            <div className="space-y-2">
              <Label>Reason for Rejection *</Label>
              <Textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="Enter rejection reason..."
                rows={3}
                required
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRejectModal(null)}>Cancel</Button>
            <Button 
              variant="destructive" 
              onClick={handleReject}
              disabled={rejectMutation.isPending || !rejectReason.trim()}
            >
              {rejectMutation.isPending ? 'Rejecting...' : 'Reject Withdrawal'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Approve Withdrawal Modal */}
      <Dialog open={!!showApproveModal} onOpenChange={() => {
        setShowApproveModal(null);
        setAdminNote('');
      }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Approve Withdrawal Request</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="bg-emerald-50 rounded-lg p-4">
              <p className="text-sm text-slate-500">Withdrawal Amount</p>
              <p className="text-2xl font-bold text-emerald-600">${showApproveModal?.amount?.toFixed(2)}</p>
            </div>
            <div className="space-y-2">
              <Label>Admin Note (Optional)</Label>
              <Textarea
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                placeholder="Add a note for this approval..."
                rows={3}
              />
            </div>
            <div className="bg-blue-50 rounded-lg p-3">
              <p className="text-sm text-blue-700">
                <strong>Note:</strong> After approval, you can process the withdrawal via Stripe to complete the transaction.
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => {
              setShowApproveModal(null);
              setAdminNote('');
            }}>Cancel</Button>
            <Button 
              className="bg-emerald-600 hover:bg-emerald-700"
              onClick={handleApprove}
              disabled={approveMutation.isPending}
            >
              {approveMutation.isPending ? 'Approving...' : 'Approve'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Withdrawal Limit Modal */}
      <Dialog open={showLimitModal} onOpenChange={setShowLimitModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Set Minimum Withdrawal Limit</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="bg-slate-50 rounded-lg p-4">
              <p className="text-sm text-slate-500">Current Limit</p>
              <p className="text-2xl font-bold">${withdrawalLimit.toFixed(2)}</p>
            </div>
            <div className="space-y-2">
              <Label>New Minimum Withdrawal Limit ($)</Label>
              <Input
                type="number"
                value={newLimit}
                onChange={(e) => setNewLimit(e.target.value)}
                placeholder={`e.g., ${withdrawalLimit}`}
                min="0"
                step="0.01"
              />
              <p className="text-xs text-slate-500">
                Washers must have at least this amount in their wallet to request withdrawal.
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => {
              setShowLimitModal(false);
              setNewLimit('');
            }}>Cancel</Button>
            <Button 
              onClick={handleSetLimit}
              disabled={setLimitMutation.isPending || !newLimit}
            >
              {setLimitMutation.isPending ? 'Updating...' : 'Update Limit'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}