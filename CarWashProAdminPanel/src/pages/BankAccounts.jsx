import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
import { base44 } from '@/api/base44Client';
import { toast } from 'sonner';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import FilterBar from '@/components/Components/ui/FilterBar.jsx';
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import { Button } from "@/components/ui/button";
import { 
  CheckCircle2, XCircle, Building2, CreditCard, User, Phone, Mail,
  Eye, AlertCircle
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import {
  Card,
  CardContent,
} from "@/components/ui/card";
import { cn } from '@/lib/utils';

export default function BankAccounts() {
  const queryClient = useQueryClient();
  const [searchParams, setSearchParams] = useSearchParams();
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState(() => {
    // Check URL params for initial tab
    const statusParam = searchParams.get('status');
    return statusParam || 'all';
  });
  const [selectedAccount, setSelectedAccount] = useState(null);
  const [showRejectDialog, setShowRejectDialog] = useState(null);
  const [rejectReason, setRejectReason] = useState('');

  // Update tab when URL params change
  useEffect(() => {
    const statusParam = searchParams.get('status');
    if (statusParam) {
      setActiveTab(statusParam);
    }
  }, [searchParams]);

  const { data: bankAccounts = [], isLoading } = useQuery({
    queryKey: ['bankAccounts', activeTab],
    queryFn: () => {
      const filters = {};
      if (activeTab !== 'all') {
        filters.status = activeTab;
      }
      return base44.entities.BankAccount.list(filters);
    },
    refetchInterval: 30000, // Auto-refresh every 30 seconds
  });

  const verifyMutation = useMutation({
    mutationFn: (id) => base44.entities.BankAccount.verify(id),
    onSuccess: () => {
      toast.success('Bank account verified successfully');
      queryClient.invalidateQueries({ queryKey: ['bankAccounts'] });
      setSelectedAccount(null);
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to verify bank account');
    }
  });

  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }) => base44.entities.BankAccount.reject(id, reason),
    onSuccess: () => {
      toast.success('Bank account rejected');
      queryClient.invalidateQueries({ queryKey: ['bankAccounts'] });
      setShowRejectDialog(null);
      setRejectReason('');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to reject bank account');
    }
  });

  const handleVerify = (account) => {
    verifyMutation.mutate(account._id);
  };

  const handleReject = () => {
    if (showRejectDialog) {
      rejectMutation.mutate({
        id: showRejectDialog._id,
        reason: rejectReason || 'Bank account verification failed'
      });
    }
  };

  const filteredAccounts = bankAccounts.filter(account => {
    if (!search) return true;
    const searchLower = search.toLowerCase();
    const washerName = account.washer_id?.name || '';
    const accountHolder = account.account_holder_name || '';
    const accountLast4 = account.account_number_last4 || '';
    return washerName.toLowerCase().includes(searchLower) ||
           accountHolder.toLowerCase().includes(searchLower) ||
           accountLast4.includes(searchLower);
  });

  const pendingCount = bankAccounts.filter(a => a.status === 'pending').length;
  const verifiedCount = bankAccounts.filter(a => a.status === 'verified').length;
  const rejectedCount = bankAccounts.filter(a => a.status === 'rejected').length;

  // Mobile card component for bank accounts
  const BankAccountCard = ({ account }) => {
    const washer = account.washer_id;
    const status = account.status || 'pending';
    const statusMap = {
      pending: { label: 'Pending', variant: 'warning' },
      verified: { label: 'Verified', variant: 'success' },
      rejected: { label: 'Rejected', variant: 'error' }
    };
    const statusInfo = statusMap[status] || statusMap.pending;

    return (
      <Card className="transition-all hover:shadow-md">
        <CardContent className="p-4">
          <div className="space-y-3">
            {/* Header */}
            <div className="flex items-start justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <StatusBadge label={statusInfo.label} variant={statusInfo.variant} />
                </div>
                <h3 className="font-semibold text-slate-900 line-clamp-1">
                  {washer?.name || 'N/A'}
                </h3>
                <p className="text-xs text-slate-500 line-clamp-1">{washer?.email || ''}</p>
              </div>
              <Button
                size="sm"
                variant="outline"
                onClick={() => setSelectedAccount(account)}
                className="flex-shrink-0"
              >
                <Eye className="w-4 h-4" />
              </Button>
            </div>

            {/* Account Details */}
            <div className="space-y-2 pt-2 border-t border-slate-100">
              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-500">Account Holder:</span>
                <span className="font-medium text-slate-900">{account.account_holder_name || 'N/A'}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-500">Account Number:</span>
                <div className="flex items-center gap-1">
                  <CreditCard className="w-3 h-3 text-slate-400" />
                  <span className="font-medium">****{account.account_number_last4 || '****'}</span>
                </div>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-500">Bank:</span>
                <span className="font-medium text-slate-900">{account.bank_name || 'N/A'}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-500">Type:</span>
                <span className="font-medium capitalize text-slate-900">{account.account_type || 'N/A'}</span>
              </div>
              {account.created_date && (
                <div className="flex items-center justify-between text-sm">
                  <span className="text-slate-500">Created:</span>
                  <span className="text-slate-600">{new Date(account.created_date).toLocaleDateString()}</span>
                </div>
              )}
            </div>

            {/* Actions */}
            {account.status === 'pending' && (
              <div className="flex gap-2 pt-2 border-t border-slate-100">
                <Button
                  size="sm"
                  variant="outline"
                  className="flex-1 text-emerald-600 border-emerald-200 hover:bg-emerald-50"
                  onClick={() => handleVerify(account)}
                  disabled={verifyMutation.isPending}
                >
                  <CheckCircle2 className="w-4 h-4 mr-1" />
                  Verify
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  className="flex-1 text-red-600 border-red-200 hover:bg-red-50"
                  onClick={() => setShowRejectDialog(account)}
                  disabled={rejectMutation.isPending}
                >
                  <XCircle className="w-4 h-4 mr-1" />
                  Reject
                </Button>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    );
  };

  const getColumns = () => [
    {
      header: 'Washer',
      accessorKey: 'washer_id',
      cell: (row) => {
        const washer = row.washer_id;
        return (
          <div className="flex items-center gap-2">
            <div className="flex flex-col">
              <span className="font-medium">{washer?.name || 'N/A'}</span>
              <span className="text-xs text-slate-500">{washer?.email || ''}</span>
            </div>
          </div>
        );
      }
    },
    {
      header: 'Account Holder',
      accessorKey: 'account_holder_name',
      cell: (row) => (
        <span className="font-medium">{row.account_holder_name || 'N/A'}</span>
      )
    },
    {
      header: 'Account Number',
      accessorKey: 'account_number_last4',
      cell: (row) => (
        <div className="flex items-center gap-2">
          <CreditCard className="w-4 h-4 text-slate-400" />
          <span>****{row.account_number_last4 || '****'}</span>
        </div>
      )
    },
    {
      header: 'Bank Name',
      accessorKey: 'bank_name',
      cell: (row) => (
        <span>{row.bank_name || 'N/A'}</span>
      )
    },
    {
      header: 'Account Type',
      accessorKey: 'account_type',
      cell: (row) => (
        <span className="capitalize">{row.account_type || 'N/A'}</span>
      )
    },
    {
      header: 'Status',
      accessorKey: 'status',
      cell: (row) => {
        const status = row.status || 'pending';
        const statusMap = {
          pending: { label: 'Pending', variant: 'warning' },
          verified: { label: 'Verified', variant: 'success' },
          rejected: { label: 'Rejected', variant: 'error' }
        };
        const statusInfo = statusMap[status] || statusMap.pending;
        return <StatusBadge label={statusInfo.label} variant={statusInfo.variant} />;
      }
    },
    {
      header: 'Created',
      accessorKey: 'created_date',
      cell: (row) => {
        const date = row.created_date;
        if (!date) return 'N/A';
        return new Date(date).toLocaleDateString();
      }
    },
    {
      header: 'Actions',
      accessorKey: 'actions',
      cell: (row) => {
        const account = row;
        return (
          <div className="flex items-center gap-2">
            <Button
              size="sm"
              variant="outline"
              onClick={() => setSelectedAccount(account)}
            >
              <Eye className="w-4 h-4" />
            </Button>
            {account.status === 'pending' && (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  className="text-emerald-600"
                  onClick={() => handleVerify(account)}
                  disabled={verifyMutation.isPending}
                >
                  <CheckCircle2 className="w-4 h-4 mr-1" />
                  Verify
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  className="text-red-600"
                  onClick={() => setShowRejectDialog(account)}
                  disabled={rejectMutation.isPending}
                >
                  <XCircle className="w-4 h-4 mr-1" />
                  Reject
                </Button>
              </>
            )}
          </div>
        );
      }
    }
  ];

  return (
    <div className="w-full space-y-4 sm:space-y-6">
      <PageHeader
        title="Bank Accounts"
        description="Manage washer bank accounts for withdrawals"
        icon={Building2}
      />

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-blue-50 flex-shrink-0">
                <Building2 className="w-4 h-4 sm:w-5 sm:h-5 text-blue-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Total</p>
                <p className="text-xl sm:text-2xl font-bold">{bankAccounts.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-amber-50 flex-shrink-0">
                <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 text-amber-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Pending</p>
                <p className="text-xl sm:text-2xl font-bold">{pendingCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-emerald-50 flex-shrink-0">
                <CheckCircle2 className="w-4 h-4 sm:w-5 sm:h-5 text-emerald-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Verified</p>
                <p className="text-xl sm:text-2xl font-bold">{verifiedCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 sm:p-6">
            <div className="flex items-center gap-3">
              <div className="p-2 sm:p-3 rounded-xl bg-red-50 flex-shrink-0">
                <XCircle className="w-4 h-4 sm:w-5 sm:h-5 text-red-600" />
              </div>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm text-slate-500 truncate">Rejected</p>
                <p className="text-xl sm:text-2xl font-bold">{rejectedCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4 sm:space-y-6">
        <div className="overflow-x-auto -mx-4 px-4 sm:mx-0 sm:px-0">
          <TabsList className="bg-white border w-full sm:w-auto inline-flex min-w-full sm:min-w-0">
            <TabsTrigger value="all" className="text-xs sm:text-sm whitespace-nowrap">All ({bankAccounts.length})</TabsTrigger>
            <TabsTrigger value="pending" className="text-xs sm:text-sm whitespace-nowrap">Pending ({pendingCount})</TabsTrigger>
            <TabsTrigger value="verified" className="text-xs sm:text-sm whitespace-nowrap">Verified ({verifiedCount})</TabsTrigger>
            <TabsTrigger value="rejected" className="text-xs sm:text-sm whitespace-nowrap">Rejected ({rejectedCount})</TabsTrigger>
          </TabsList>
        </div>

        <div className="space-y-4">
          <FilterBar
            search={search}
            onSearchChange={setSearch}
            placeholder="Search by washer name, account holder, or account number..."
          />

          {/* Desktop Table View */}
          <div className="hidden lg:block">
            <DataTable
              columns={getColumns()}
              data={filteredAccounts}
              isLoading={isLoading}
              emptyMessage="No bank accounts found"
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
                        <div className="h-10 bg-slate-200 rounded"></div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            ) : filteredAccounts.length === 0 ? (
              <div className="bg-white rounded-2xl border border-slate-100 p-12 text-center">
                <p className="text-slate-500">No bank accounts found</p>
              </div>
            ) : (
              filteredAccounts.map((account) => (
                <BankAccountCard key={account._id || account.id} account={account} />
              ))
            )}
          </div>
        </div>
      </Tabs>

      {/* Account Details Sheet */}
      <Sheet open={!!selectedAccount} onOpenChange={() => setSelectedAccount(null)}>
        <SheetContent className="w-full sm:max-w-2xl overflow-y-auto p-4 sm:p-6">
          <SheetHeader className="pb-4">
            <SheetTitle className="text-lg sm:text-xl">Bank Account Details</SheetTitle>
          </SheetHeader>
          {selectedAccount && (
            <div className="mt-4 sm:mt-6 space-y-4 sm:space-y-6">
              {/* Washer Info */}
              <div className="bg-slate-50 rounded-lg p-3 sm:p-4">
                <h3 className="font-semibold mb-2 sm:mb-3 flex items-center gap-2 text-sm sm:text-base">
                  <User className="w-4 h-4 sm:w-5 sm:h-5" />
                  Washer Information
                </h3>
                <div className="space-y-2">
                  <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-2">
                    <span className="text-xs sm:text-sm text-slate-600">Name:</span>
                    <span className="font-medium text-sm sm:text-base">{selectedAccount.washer_id?.name || 'N/A'}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Mail className="w-3 h-3 sm:w-4 sm:h-4 text-slate-400 flex-shrink-0" />
                    <span className="text-xs sm:text-sm break-all">{selectedAccount.washer_id?.email || 'N/A'}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone className="w-3 h-3 sm:w-4 sm:h-4 text-slate-400 flex-shrink-0" />
                    <span className="text-xs sm:text-sm">{selectedAccount.washer_id?.phone || 'N/A'}</span>
                  </div>
                </div>
              </div>

              {/* Bank Account Info */}
              <div className="bg-blue-50 rounded-lg p-3 sm:p-4">
                <h3 className="font-semibold mb-2 sm:mb-3 flex items-center gap-2 text-sm sm:text-base">
                  <CreditCard className="w-4 h-4 sm:w-5 sm:h-5" />
                  Bank Account Information
                </h3>
                <div className="space-y-2 sm:space-y-3">
                  <div>
                    <span className="text-xs sm:text-sm text-slate-600 block mb-1">Account Holder:</span>
                    <p className="font-medium text-sm sm:text-base break-words">{selectedAccount.account_holder_name}</p>
                  </div>
                  <div>
                    <span className="text-xs sm:text-sm text-slate-600 block mb-1">Account Number:</span>
                    <p className="font-medium text-sm sm:text-base">****{selectedAccount.account_number_last4}</p>
                  </div>
                  {selectedAccount.account_number && (
                    <div>
                      <span className="text-xs sm:text-sm text-slate-600 block mb-1">Full Account Number:</span>
                      <p className="font-medium font-mono text-xs sm:text-sm break-all">{selectedAccount.account_number}</p>
                    </div>
                  )}
                  <div>
                    <span className="text-xs sm:text-sm text-slate-600 block mb-1">Routing Number:</span>
                    <p className="font-medium font-mono text-xs sm:text-sm break-all">{selectedAccount.routing_number || 'N/A'}</p>
                  </div>
                  <div>
                    <span className="text-xs sm:text-sm text-slate-600 block mb-1">Account Type:</span>
                    <p className="font-medium capitalize text-sm sm:text-base">{selectedAccount.account_type}</p>
                  </div>
                  {selectedAccount.bank_name && (
                    <div>
                      <span className="text-xs sm:text-sm text-slate-600 block mb-1">Bank Name:</span>
                      <p className="font-medium text-sm sm:text-base break-words">{selectedAccount.bank_name}</p>
                    </div>
                  )}
                  <div>
                    <span className="text-xs sm:text-sm text-slate-600 block mb-1">Status:</span>
                    <div className="mt-1">
                      <StatusBadge
                        label={selectedAccount.status === 'verified' ? 'Verified' : selectedAccount.status === 'rejected' ? 'Rejected' : 'Pending'}
                        variant={selectedAccount.status === 'verified' ? 'success' : selectedAccount.status === 'rejected' ? 'error' : 'warning'}
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Actions */}
              {selectedAccount.status === 'pending' && (
                <div className="flex flex-col sm:flex-row gap-2 pt-2 border-t border-slate-200">
                  <Button
                    className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-sm sm:text-base"
                    onClick={() => {
                      handleVerify(selectedAccount);
                      setSelectedAccount(null);
                    }}
                    disabled={verifyMutation.isPending}
                  >
                    <CheckCircle2 className="w-4 h-4 mr-2" />
                    Verify Account
                  </Button>
                  <Button
                    variant="outline"
                    className="flex-1 text-red-600 text-sm sm:text-base"
                    onClick={() => {
                      setSelectedAccount(null);
                      setShowRejectDialog(selectedAccount);
                    }}
                    disabled={rejectMutation.isPending}
                  >
                    <XCircle className="w-4 h-4 mr-2" />
                    Reject
                  </Button>
                </div>
              )}
            </div>
          )}
        </SheetContent>
      </Sheet>

      {/* Reject Dialog */}
      <Dialog open={!!showRejectDialog} onOpenChange={() => {
        setShowRejectDialog(null);
        setRejectReason('');
      }}>
        <DialogContent className="w-[95vw] sm:w-full max-w-md mx-4 sm:mx-auto">
          <DialogHeader>
            <DialogTitle className="text-lg sm:text-xl">Reject Bank Account</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="bg-red-50 rounded-lg p-3 sm:p-4">
              <p className="text-xs sm:text-sm text-red-700">
                <AlertCircle className="w-4 h-4 inline mr-2 align-middle" />
                Are you sure you want to reject this bank account? The washer will need to add a new account.
              </p>
            </div>
            <div className="space-y-2">
              <Label className="text-sm sm:text-base">Rejection Reason (Optional)</Label>
              <Textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="Enter reason for rejection..."
                rows={3}
                className="text-sm sm:text-base"
              />
            </div>
          </div>
          <DialogFooter className="flex-col sm:flex-row gap-2 sm:gap-0">
            <Button 
              variant="outline" 
              className="w-full sm:w-auto text-sm sm:text-base"
              onClick={() => {
                setShowRejectDialog(null);
                setRejectReason('');
              }}
            >
              Cancel
            </Button>
            <Button
              className="w-full sm:w-auto bg-red-600 hover:bg-red-700 text-sm sm:text-base"
              onClick={handleReject}
              disabled={rejectMutation.isPending}
            >
              {rejectMutation.isPending ? 'Rejecting...' : 'Reject Account'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
