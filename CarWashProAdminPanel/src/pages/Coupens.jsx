import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Plus, MoreHorizontal, Pencil, Trash2, Ticket, Copy, TrendingUp } from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { toast } from "sonner";

export default function Coupons() {
  const queryClient = useQueryClient();
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    code: '',
    description: '',
    discount_type: 'percentage',
    discount_value: 10,
    min_order_value: 0,
    max_discount: 0,
    expiry_date: '',
    usage_limit: 100,
    is_active: true
  });

  const { data: coupons = [], isLoading } = useQuery({
    queryKey: ['coupons'],
    queryFn: () => base44.entities.Coupon.list('-created_date'),
  });

  const createMutation = useMutation({
    mutationFn: (data) => editing 
      ? base44.entities.Coupon.update(editing.id, data)
      : base44.entities.Coupon.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['coupons'] });
      closeModal();
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => base44.entities.Coupon.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['coupons'] })
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, is_active }) => base44.entities.Coupon.update(id, { is_active }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['coupons'] })
  });

  const openModal = (coupon = null) => {
    if (coupon) {
      setEditing(coupon);
      setForm({
        code: coupon.code || '',
        description: coupon.description || '',
        discount_type: coupon.discount_type || 'percentage',
        discount_value: coupon.discount_value || 10,
        min_order_value: coupon.min_order_value || 0,
        max_discount: coupon.max_discount || 0,
        expiry_date: coupon.expiry_date || '',
        usage_limit: coupon.usage_limit || 100,
        is_active: coupon.is_active !== false
      });
    } else {
      setEditing(null);
      setForm({
        code: '',
        description: '',
        discount_type: 'percentage',
        discount_value: 10,
        min_order_value: 0,
        max_discount: 0,
        expiry_date: '',
        usage_limit: 100,
        is_active: true
      });
    }
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditing(null);
  };

  const generateCode = () => {
    const code = 'WASH' + Math.random().toString(36).substring(2, 8).toUpperCase();
    setForm({ ...form, code });
  };

  const copyCode = (code) => {
    navigator.clipboard.writeText(code);
    toast.success('Code copied to clipboard');
  };

  const isExpired = (date) => {
    if (!date) return false;
    return new Date(date) < new Date();
  };

  const columns = [
    {
      header: 'Coupon',
      cell: (row) => (
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-purple-100 flex items-center justify-center">
            <Ticket className="w-5 h-5 text-purple-600" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-mono font-bold text-slate-900">{row.code}</span>
              <button onClick={() => copyCode(row.code)} className="text-slate-400 hover:text-slate-600">
                <Copy className="w-3 h-3" />
              </button>
            </div>
            <p className="text-sm text-slate-500">{row.description}</p>
          </div>
        </div>
      )
    },
    {
      header: 'Discount',
      cell: (row) => (
        <span className="font-semibold text-emerald-600">
          {row.discount_type === 'percentage' 
            ? `${row.discount_value}%` 
            : `$${row.discount_value}`
          }
        </span>
      )
    },
    {
      header: 'Min. Order',
      cell: (row) => (
        <span className="text-slate-600">
          {row.min_order_value > 0 ? `$${row.min_order_value}` : '-'}
        </span>
      )
    },
    {
      header: 'Usage',
      cell: (row) => (
        <div className="flex items-center gap-2">
          <div className="flex-1 h-2 bg-slate-100 rounded-full w-20">
            <div 
              className="h-full bg-blue-500 rounded-full"
              style={{ width: `${Math.min((row.times_used || 0) / (row.usage_limit || 100) * 100, 100)}%` }}
            />
          </div>
          <span className="text-sm text-slate-600">
            {row.times_used || 0}/{row.usage_limit || '∞'}
          </span>
        </div>
      )
    },
    {
      header: 'Expiry',
      cell: (row) => {
        const expired = isExpired(row.expiry_date);
        return row.expiry_date ? (
          <span className={expired ? 'text-red-500' : 'text-slate-600'}>
            {format(new Date(row.expiry_date), 'MMM d, yyyy')}
            {expired && ' (Expired)'}
          </span>
        ) : (
          <span className="text-slate-400">No expiry</span>
        );
      }
    },
    {
      header: 'Status',
      cell: (row) => (
        <Switch
          checked={row.is_active}
          onCheckedChange={(v) => toggleMutation.mutate({ id: row.id, is_active: v })}
        />
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
            <DropdownMenuItem onClick={() => openModal(row)}>
              <Pencil className="w-4 h-4 mr-2" />
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem 
              onClick={() => deleteMutation.mutate(row.id)}
              className="text-red-600"
            >
              <Trash2 className="w-4 h-4 mr-2" />
              Delete
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
      className: 'w-12'
    }
  ];

  // Stats
  const activeCoupons = coupons.filter(c => c.is_active && !isExpired(c.expiry_date));
  const totalRedemptions = coupons.reduce((sum, c) => sum + (c.times_used || 0), 0);

  return (
    <div>
      <PageHeader 
        title="Pricing & Coupons"
        subtitle="Manage discount codes and promotions"
        actions={
          <Button onClick={() => openModal()}>
            <Plus className="w-4 h-4 mr-2" />
            Create Coupon
          </Button>
        }
      />

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-8">
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-purple-50">
              <Ticket className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Total Coupons</p>
              <p className="text-2xl font-bold">{coupons.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-emerald-50">
              <Ticket className="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Active Coupons</p>
              <p className="text-2xl font-bold">{activeCoupons.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-blue-50">
              <TrendingUp className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Total Redemptions</p>
              <p className="text-2xl font-bold">{totalRedemptions}</p>
            </div>
          </div>
        </div>
      </div>

      <DataTable
        columns={columns}
        data={coupons}
        isLoading={isLoading}
        emptyMessage="No coupons created yet"
      />

      {/* Create/Edit Modal */}
      <Dialog open={showModal} onOpenChange={closeModal}>
        <DialogContent className="max-w-2xl max-h-[90vh] flex flex-col">
          <DialogHeader className="flex-shrink-0 pb-4 border-b">
            <DialogTitle className="text-xl font-semibold">
              {editing ? 'Edit Coupon' : 'Create New Coupon'}
            </DialogTitle>
          </DialogHeader>
          
          {/* Scrollable Content */}
          <div className="flex-1 overflow-y-auto px-1 py-4">
            <div className="space-y-6">
              {/* Basic Information Section */}
              <div className="space-y-4">
                <h3 className="text-sm font-semibold text-slate-700 uppercase tracking-wide">
                  Basic Information
                </h3>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">Coupon Code *</Label>
                    <div className="flex gap-2">
                      <Input
                        value={form.code}
                        onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })}
                        placeholder="SUMMER20"
                        className="font-mono flex-1"
                      />
                      <Button 
                        type="button" 
                        variant="outline" 
                        onClick={generateCode}
                        className="whitespace-nowrap"
                      >
                        Generate
                      </Button>
                    </div>
                    <p className="text-xs text-slate-500">
                      Enter a unique code or generate one automatically
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">Description</Label>
                    <Input
                      value={form.description}
                      onChange={(e) => setForm({ ...form, description: e.target.value })}
                      placeholder="Summer sale discount"
                    />
                    <p className="text-xs text-slate-500">
                      Optional description for internal reference
                    </p>
                  </div>
                </div>
              </div>

              {/* Discount Configuration Section */}
              <div className="space-y-4 pt-4 border-t">
                <h3 className="text-sm font-semibold text-slate-700 uppercase tracking-wide">
                  Discount Configuration
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">Discount Type *</Label>
                    <Select
                      value={form.discount_type}
                      onValueChange={(v) => setForm({ ...form, discount_type: v })}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="percentage">Percentage (%)</SelectItem>
                        <SelectItem value="fixed">Fixed Amount ($)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">
                      Discount Value * 
                      {form.discount_type === 'percentage' && ' (0-100%)'}
                    </Label>
                    <Input
                      type="number"
                      min="0"
                      max={form.discount_type === 'percentage' ? '100' : undefined}
                      step={form.discount_type === 'percentage' ? '0.1' : '0.01'}
                      value={form.discount_value}
                      onChange={(e) => setForm({ ...form, discount_value: parseFloat(e.target.value) || 0 })}
                      placeholder={form.discount_type === 'percentage' ? '10' : '5.00'}
                    />
                  </div>
                </div>
              </div>

              {/* Conditions Section */}
              <div className="space-y-4 pt-4 border-t">
                <h3 className="text-sm font-semibold text-slate-700 uppercase tracking-wide">
                  Conditions & Limits
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">Min. Order Value ($)</Label>
                    <Input
                      type="number"
                      min="0"
                      step="0.01"
                      value={form.min_order_value}
                      onChange={(e) => setForm({ ...form, min_order_value: parseFloat(e.target.value) || 0 })}
                      placeholder="0"
                    />
                    <p className="text-xs text-slate-500">
                      Minimum order amount required (0 = no minimum)
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">Max. Discount ($)</Label>
                    <Input
                      type="number"
                      min="0"
                      step="0.01"
                      value={form.max_discount}
                      onChange={(e) => setForm({ ...form, max_discount: parseFloat(e.target.value) || 0 })}
                      placeholder="0 = no limit"
                    />
                    <p className="text-xs text-slate-500">
                      Maximum discount amount (0 = unlimited)
                    </p>
                  </div>
                </div>
              </div>

              {/* Validity Section */}
              <div className="space-y-4 pt-4 border-t">
                <h3 className="text-sm font-semibold text-slate-700 uppercase tracking-wide">
                  Validity & Usage
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">Expiry Date</Label>
                    <Input
                      type="date"
                      value={form.expiry_date}
                      onChange={(e) => setForm({ ...form, expiry_date: e.target.value })}
                      min={new Date().toISOString().split('T')[0]}
                    />
                    <p className="text-xs text-slate-500">
                      Leave empty for no expiration
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label className="text-sm font-medium">Usage Limit</Label>
                    <Input
                      type="number"
                      min="1"
                      value={form.usage_limit}
                      onChange={(e) => setForm({ ...form, usage_limit: parseInt(e.target.value) || 100 })}
                      placeholder="100"
                    />
                    <p className="text-xs text-slate-500">
                      Maximum number of times this coupon can be used
                    </p>
                  </div>
                </div>
              </div>

              {/* Status Section */}
              <div className="space-y-4 pt-4 border-t">
                <h3 className="text-sm font-semibold text-slate-700 uppercase tracking-wide">
                  Status
                </h3>
                <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                  <Switch
                    checked={form.is_active}
                    onCheckedChange={(v) => setForm({ ...form, is_active: v })}
                  />
                  <div className="flex-1">
                    <Label className="text-sm font-medium cursor-pointer">
                      Active
                    </Label>
                    <p className="text-xs text-slate-500">
                      Only active coupons can be used by customers
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Fixed Footer */}
          <DialogFooter className="flex-shrink-0 pt-4 border-t mt-4">
            <Button variant="outline" onClick={closeModal}>
              Cancel
            </Button>
            <Button 
              onClick={() => createMutation.mutate(form)}
              disabled={createMutation.isPending}
            >
              {createMutation.isPending 
                ? (editing ? 'Saving...' : 'Creating...') 
                : (editing ? 'Save Changes' : 'Create Coupon')
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}