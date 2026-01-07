import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { toast } from 'sonner';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import FilterBar from '@/components/Components/ui/FilterBar.jsx';
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Textarea } from "@/components/ui/textarea";
import { 
  Plus, MoreHorizontal, Star, Phone, Mail, Building2,
  CheckCircle2, XCircle, Ban, DollarSign, Calendar, TrendingUp, CheckCircle, X
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export default function Washers() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState('all');
  const [selectedWasher, setSelectedWasher] = useState(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectDialog, setShowRejectDialog] = useState(null);
  const [newWasher, setNewWasher] = useState({
    name: '', phone: '', email: '', branch_id: '', branch_name: '', status: 'pending'
  });

  const { data: washers = [], isLoading } = useQuery({
    queryKey: ['washers'],
    queryFn: () => base44.entities.Washer.list('-created_date', 200),
  });

  const { data: branches = [] } = useQuery({
    queryKey: ['branches'],
    queryFn: () => base44.entities.Branch.list(),
  });

  const createMutation = useMutation({
    mutationFn: (data) => base44.entities.Washer.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['washers'] });
      setShowAddModal(false);
      setNewWasher({ name: '', phone: '', email: '', branch_id: '', branch_name: '', status: 'pending' });
    }
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => {
      console.log('Updating washer:', { id, data });
      return base44.entities.Washer.update(id, data);
    },
    onSuccess: (response) => {
      console.log('Washer update success:', response);
      if (response.success) {
        toast.success('Washer status updated successfully');
        queryClient.invalidateQueries({ queryKey: ['washers'] });
        setSelectedWasher(null);
      } else {
        toast.error(response.message || 'Failed to update washer');
      }
    },
    onError: (error) => {
      console.error('Washer update error:', error);
      toast.error(error.message || 'Failed to update washer. Please try again.');
    }
  });

  const handleApprove = (washer) => {
    // Use _id if id is not available (MongoDB compatibility)
    const washerId = washer.id || washer._id;
    console.log('Approving washer:', { washer, washerId });
    
    if (!washerId) {
      console.error('Washer ID not found:', washer);
      return;
    }

    updateMutation.mutate({
      id: washerId,
      data: { status: 'active', approval_note: 'Approved by admin' }
    });
  };

  const handleReject = () => {
    if (showRejectDialog) {
      updateMutation.mutate({
        id: showRejectDialog.id,
        data: { status: 'suspended', rejection_reason: rejectReason }
      });
      setShowRejectDialog(null);
      setRejectReason('');
    }
  };

  const handleSuspend = (washer) => {
    const washerId = washer.id || washer._id;
    if (!washerId) {
      console.error('Washer ID not found:', washer);
      return;
    }
    updateMutation.mutate({
      id: washerId,
      data: { status: 'suspended' }
    });
  };

  const handleActivate = (washer) => {
    const washerId = washer.id || washer._id;
    if (!washerId) {
      console.error('Washer ID not found:', washer);
      return;
    }
    updateMutation.mutate({
      id: washerId,
      data: { status: 'active' }
    });
  };

  const tabCounts = {
    all: washers.length,
    pending: washers.filter(w => w.status === 'pending').length,
    active: washers.filter(w => w.status === 'active').length,
    suspended: washers.filter(w => w.status === 'suspended').length,
  };

  const filteredWashers = washers.filter(w => {
    const matchesSearch = !search ||
      w.name?.toLowerCase().includes(search.toLowerCase()) ||
      w.phone?.includes(search);
    
    const matchesTab = activeTab === 'all' ? true : w.status === activeTab;
    
    return matchesSearch && matchesTab;
  });

  const columns = [
    {
      header: 'Washer',
      cell: (row) => (
        <div className="flex items-center gap-3">
          <div className="relative">
            <Avatar className="w-10 h-10">
              <AvatarImage src={row.avatar} />
              <AvatarFallback className="bg-purple-100 text-purple-600">
                {row.name?.[0]}
              </AvatarFallback>
            </Avatar>
            {row.online_status && (
              <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full" />
            )}
          </div>
          <div>
            <p className="font-medium text-slate-900">{row.name}</p>
            <p className="text-sm text-slate-500">{row.phone}</p>
            {row.email && (
              <p className="text-xs text-slate-400">{row.email}</p>
            )}
          </div>
        </div>
      )
    },
    {
      header: 'Rating',
      cell: (row) => (
        <div className="flex items-center gap-1">
          <Star className="w-4 h-4 text-amber-400 fill-amber-400" />
          <span className="font-medium">{row.rating?.toFixed(1) || '0.0'}</span>
          <span className="text-sm text-slate-500">({row.total_ratings || 0})</span>
        </div>
      )
    },
    {
      header: 'Jobs',
      cell: (row) => (
        <div>
          <p className="font-medium text-slate-900">{row.jobs_completed || 0}</p>
          <p className="text-sm text-slate-500">{row.jobs_cancelled || 0} cancelled</p>
        </div>
      )
    },
    {
      header: 'Branch',
      cell: (row) => (
        <span className="text-slate-600">{row.branch_name || '-'}</span>
      )
    },
    {
      header: 'Email Verified',
      cell: (row) => (
        <div className="flex items-center gap-2">
          {row.email_verified ? (
            <span className="flex items-center gap-1 text-emerald-600 text-sm">
              <CheckCircle className="w-4 h-4" />
              Verified
            </span>
          ) : (
            <span className="flex items-center gap-1 text-amber-600 text-sm">
              <X className="w-4 h-4" />
              Not Verified
            </span>
          )}
        </div>
      )
    },
    {
      header: 'Status',
      cell: (row) => (
        <div className="flex items-center gap-2">
          <StatusBadge status={row.status} />
          {row.status === 'active' && (
            <StatusBadge status={row.online_status ? 'online' : 'offline'} showDot />
          )}
          {/* Show warning if email not verified and status is active */}
          {row.status === 'active' && !row.email_verified && (
            <span className="text-xs text-amber-600" title="Cannot login - email not verified">
              ⚠️
            </span>
          )}
          {/* Show warning if status is pending but email verified */}
          {row.status === 'pending' && row.email_verified && (
            <span className="text-xs text-blue-600" title="Email verified - waiting for admin approval">
              ✓
            </span>
          )}
        </div>
      )
    },
    {
      header: 'Wallet',
      cell: (row) => (
        <span className="font-medium text-emerald-600">${row.wallet_balance?.toFixed(2) || '0.00'}</span>
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
            <DropdownMenuItem onClick={() => setSelectedWasher(row)}>
              View Profile
            </DropdownMenuItem>
            {row.status === 'pending' && (
              <>
                <DropdownMenuItem onClick={() => handleApprove(row)} className="text-emerald-600">
                  <CheckCircle2 className="w-4 h-4 mr-2" />
                  Approve
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => setShowRejectDialog(row)} className="text-red-600">
                  <XCircle className="w-4 h-4 mr-2" />
                  Reject
                </DropdownMenuItem>
              </>
            )}
            {row.status === 'active' && (
              <DropdownMenuItem onClick={() => handleSuspend(row)} className="text-red-600">
                <Ban className="w-4 h-4 mr-2" />
                Suspend
              </DropdownMenuItem>
            )}
            {row.status === 'suspended' && (
              <DropdownMenuItem onClick={() => handleActivate(row)} className="text-emerald-600">
                <CheckCircle2 className="w-4 h-4 mr-2" />
                Reactivate
              </DropdownMenuItem>
            )}
          </DropdownMenuContent>
        </DropdownMenu>
      ),
      className: 'w-12'
    }
  ];

  return (
    <div>
      <PageHeader 
        title="Washers"
        subtitle={`${washers.length} total washers`}
        actions={
          <Button onClick={() => setShowAddModal(true)}>
            <Plus className="w-4 h-4 mr-2" />
            Add Washer
          </Button>
        }
      />

      <Tabs value={activeTab} onValueChange={setActiveTab} className="mb-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="all">All ({tabCounts.all})</TabsTrigger>
          <TabsTrigger value="pending" className="data-[state=active]:text-amber-600">
            Pending ({tabCounts.pending})
          </TabsTrigger>
          <TabsTrigger value="active" className="data-[state=active]:text-emerald-600">
            Active ({tabCounts.active})
          </TabsTrigger>
          <TabsTrigger value="suspended" className="data-[state=active]:text-red-600">
            Suspended ({tabCounts.suspended})
          </TabsTrigger>
        </TabsList>
      </Tabs>

      <FilterBar
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search by name or phone..."
        filters={[]}
        onClearFilters={() => setSearch('')}
      />

      <DataTable
        columns={columns}
        data={filteredWashers}
        isLoading={isLoading}
        emptyMessage="No washers found"
        onRowClick={(row) => setSelectedWasher(row)}
      />

      {/* Washer Detail Sheet */}
      <Sheet open={!!selectedWasher} onOpenChange={() => setSelectedWasher(null)}>
        <SheetContent className="w-full sm:max-w-xl overflow-y-auto">
          {selectedWasher && (
            <>
              <SheetHeader className="pb-4">
                <div className="flex items-center gap-4">
                  <div className="relative">
                    <Avatar className="w-16 h-16">
                      <AvatarImage src={selectedWasher.avatar} />
                      <AvatarFallback className="bg-purple-100 text-purple-600 text-xl">
                        {selectedWasher.name?.[0]}
                      </AvatarFallback>
                    </Avatar>
                    {selectedWasher.online_status && (
                      <span className="absolute bottom-1 right-1 w-4 h-4 bg-emerald-500 border-2 border-white rounded-full" />
                    )}
                  </div>
                  <div>
                    <SheetTitle className="text-xl">{selectedWasher.name}</SheetTitle>
                    <div className="flex items-center gap-2 mt-1">
                      <StatusBadge status={selectedWasher.status} />
                      {selectedWasher.status === 'active' && (
                        <StatusBadge status={selectedWasher.online_status ? 'online' : 'offline'} showDot />
                      )}
                    </div>
                  </div>
                </div>
              </SheetHeader>

              <div className="space-y-6 mt-6">
                {/* Contact */}
                <div className="space-y-3">
                  <h4 className="text-sm font-semibold text-slate-500 uppercase">Contact</h4>
                  <div className="space-y-2">
                    <div className="flex items-center gap-3 text-sm">
                      <Phone className="w-4 h-4 text-slate-400" />
                      <span>{selectedWasher.phone}</span>
                    </div>
                    {selectedWasher.email && (
                      <div className="flex items-center gap-3 text-sm">
                        <Mail className="w-4 h-4 text-slate-400" />
                        <span>{selectedWasher.email}</span>
                      </div>
                    )}
                    {selectedWasher.branch_name && (
                      <div className="flex items-center gap-3 text-sm">
                        <Building2 className="w-4 h-4 text-slate-400" />
                        <span>{selectedWasher.branch_name}</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Performance Stats */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-amber-50 rounded-xl p-4 text-center">
                    <Star className="w-5 h-5 text-amber-500 mx-auto mb-2" />
                    <p className="text-2xl font-bold">{selectedWasher.rating?.toFixed(1) || '0.0'}</p>
                    <p className="text-sm text-slate-500">{selectedWasher.total_ratings || 0} reviews</p>
                  </div>
                  <div className="bg-blue-50 rounded-xl p-4 text-center">
                    <Calendar className="w-5 h-5 text-blue-600 mx-auto mb-2" />
                    <p className="text-2xl font-bold">{selectedWasher.jobs_completed || 0}</p>
                    <p className="text-sm text-slate-500">Completed</p>
                  </div>
                  <div className="bg-emerald-50 rounded-xl p-4 text-center">
                    <DollarSign className="w-5 h-5 text-emerald-600 mx-auto mb-2" />
                    <p className="text-2xl font-bold">${selectedWasher.total_earnings?.toFixed(0) || 0}</p>
                    <p className="text-sm text-slate-500">Total Earnings</p>
                  </div>
                  <div className="bg-purple-50 rounded-xl p-4 text-center">
                    <TrendingUp className="w-5 h-5 text-purple-600 mx-auto mb-2" />
                    <p className="text-2xl font-bold">
                      {selectedWasher.jobs_completed > 0 
                        ? (100 - (selectedWasher.jobs_cancelled / selectedWasher.jobs_completed * 100)).toFixed(0)
                        : 100}%
                    </p>
                    <p className="text-sm text-slate-500">Completion Rate</p>
                  </div>
                </div>

                {/* Wallet */}
                <div className="bg-slate-50 rounded-xl p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-slate-500">Wallet Balance</p>
                      <p className="text-2xl font-bold text-emerald-600">
                        ${selectedWasher.wallet_balance?.toFixed(2) || '0.00'}
                      </p>
                    </div>
                    <Button variant="outline" size="sm">View Transactions</Button>
                  </div>
                </div>

                {/* Actions */}
                <div className="space-y-3 pt-4 border-t">
                  {selectedWasher.status === 'pending' && (
                    <>
                      <Button className="w-full" onClick={() => handleApprove(selectedWasher)}>
                        <CheckCircle2 className="w-4 h-4 mr-2" />
                        Approve Washer
                      </Button>
                      <Button 
                        variant="destructive" 
                        className="w-full"
                        onClick={() => setShowRejectDialog(selectedWasher)}
                      >
                        <XCircle className="w-4 h-4 mr-2" />
                        Reject
                      </Button>
                    </>
                  )}
                  {selectedWasher.status === 'active' && (
                    <Button 
                      variant="destructive" 
                      className="w-full"
                      onClick={() => handleSuspend(selectedWasher)}
                    >
                      <Ban className="w-4 h-4 mr-2" />
                      Suspend Washer
                    </Button>
                  )}
                  {selectedWasher.status === 'suspended' && (
                    <Button className="w-full" onClick={() => handleActivate(selectedWasher)}>
                      <CheckCircle2 className="w-4 h-4 mr-2" />
                      Reactivate Washer
                    </Button>
                  )}
                </div>
              </div>
            </>
          )}
        </SheetContent>
      </Sheet>

      {/* Add Washer Modal */}
      <Dialog open={showAddModal} onOpenChange={setShowAddModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add New Washer</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Full Name</Label>
              <Input
                value={newWasher.name}
                onChange={(e) => setNewWasher({ ...newWasher, name: e.target.value })}
                placeholder="John Doe"
              />
            </div>
            <div className="space-y-2">
              <Label>Phone</Label>
              <Input
                value={newWasher.phone}
                onChange={(e) => setNewWasher({ ...newWasher, phone: e.target.value })}
                placeholder="+1 234 567 8900"
              />
            </div>
            <div className="space-y-2">
              <Label>Email</Label>
              <Input
                type="email"
                value={newWasher.email}
                onChange={(e) => setNewWasher({ ...newWasher, email: e.target.value })}
                placeholder="john@example.com"
              />
            </div>
            <div className="space-y-2">
              <Label>Branch</Label>
              <Select
                value={newWasher.branch_id}
                onValueChange={(v) => {
                  const branch = branches.find(b => b.id === v);
                  setNewWasher({ ...newWasher, branch_id: v, branch_name: branch?.name });
                }}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select branch" />
                </SelectTrigger>
                <SelectContent>
                  {branches.map(b => (
                    <SelectItem key={b.id} value={b.id}>{b.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAddModal(false)}>Cancel</Button>
            <Button onClick={() => createMutation.mutate(newWasher)}>Add Washer</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reject Dialog */}
      <Dialog open={!!showRejectDialog} onOpenChange={() => setShowRejectDialog(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Washer Application</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Reason for rejection</Label>
              <Textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="Enter reason..."
                rows={4}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRejectDialog(null)}>Cancel</Button>
            <Button variant="destructive" onClick={handleReject}>Reject</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}