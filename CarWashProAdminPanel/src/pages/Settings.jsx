import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  Building2, CreditCard, Bell, Shield, Users, MapPin, 
  Save, Plus, Trash2, Pencil
} from 'lucide-react';
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
import DataTable from '@/components/Components/ui/DataTable.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';

export default function Settings() {
  const queryClient = useQueryClient();
  const [showBranchModal, setShowBranchModal] = useState(false);
  const [editingBranch, setEditingBranch] = useState(null);
  const [branchForm, setBranchForm] = useState({
    name: '', address: '', phone: '', email: '', 
    service_radius_km: 10, is_active: true
  });

  const { data: settings = [], isLoading } = useQuery({
    queryKey: ['settings'],
    queryFn: () => base44.entities.BusinessSettings.list(),
  });

  const { data: branches = [] } = useQuery({
    queryKey: ['branches'],
    queryFn: () => base44.entities.Branch.list(),
  });

  const { data: adminUsers = [] } = useQuery({
    queryKey: ['admin-users'],
    queryFn: () => base44.entities.AdminUser.list(),
  });

  const businessSettings = settings[0] || {};

  const [form, setForm] = useState({
    business_name: '',
    logo_url: '',
    contact_email: '',
    contact_phone: '',
    address: '',
    tax_rate: 8,
    service_fee: 0,
    currency: 'USD',
    currency_symbol: '$',
    cancellation_fee_percentage: 0,
    free_cancellation_hours: 24,
    cancellation_policy: ''
  });

  useEffect(() => {
    if (businessSettings.id) {
      setForm({
        business_name: businessSettings.business_name || '',
        logo_url: businessSettings.logo_url || '',
        contact_email: businessSettings.contact_email || '',
        contact_phone: businessSettings.contact_phone || '',
        address: businessSettings.address || '',
        tax_rate: businessSettings.tax_rate || 8,
        service_fee: businessSettings.service_fee || 0,
        currency: businessSettings.currency || 'USD',
        currency_symbol: businessSettings.currency_symbol || '$',
        cancellation_fee_percentage: businessSettings.cancellation_fee_percentage || 0,
        free_cancellation_hours: businessSettings.free_cancellation_hours || 24,
        cancellation_policy: businessSettings.cancellation_policy || ''
      });
    }
  }, [businessSettings]);

  const settingsMutation = useMutation({
    mutationFn: (data) => businessSettings.id 
      ? base44.entities.BusinessSettings.update(businessSettings.id, data)
      : base44.entities.BusinessSettings.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings'] });
    }
  });

  const branchMutation = useMutation({
    mutationFn: (data) => editingBranch
      ? base44.entities.Branch.update(editingBranch.id, data)
      : base44.entities.Branch.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['branches'] });
      closeBranchModal();
    }
  });

  const deleteBranchMutation = useMutation({
    mutationFn: (id) => base44.entities.Branch.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['branches'] })
  });

  const openBranchModal = (branch = null) => {
    if (branch) {
      setEditingBranch(branch);
      setBranchForm({
        name: branch.name || '',
        address: branch.address || '',
        phone: branch.phone || '',
        email: branch.email || '',
        service_radius_km: branch.service_radius_km || 10,
        is_active: branch.is_active !== false
      });
    } else {
      setEditingBranch(null);
      setBranchForm({
        name: '', address: '', phone: '', email: '', 
        service_radius_km: 10, is_active: true
      });
    }
    setShowBranchModal(true);
  };

  const closeBranchModal = () => {
    setShowBranchModal(false);
    setEditingBranch(null);
  };

  const branchColumns = [
    {
      header: 'Branch',
      cell: (row) => (
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center">
            <MapPin className="w-5 h-5 text-slate-600" />
          </div>
          <div>
            <p className="font-medium text-slate-900">{row.name}</p>
            <p className="text-sm text-slate-500">{row.address}</p>
          </div>
        </div>
      )
    },
    {
      header: 'Contact',
      cell: (row) => (
        <div className="text-sm">
          <p>{row.phone}</p>
          <p className="text-slate-500">{row.email}</p>
        </div>
      )
    },
    {
      header: 'Service Radius',
      cell: (row) => `${row.service_radius_km || 10} km`
    },
    {
      header: 'Status',
      cell: (row) => <StatusBadge status={row.is_active ? 'active' : 'suspended'} />
    },
    {
      header: '',
      cell: (row) => (
        <div className="flex gap-2">
          <Button variant="ghost" size="icon" onClick={() => openBranchModal(row)}>
            <Pencil className="w-4 h-4" />
          </Button>
          <Button variant="ghost" size="icon" onClick={() => deleteBranchMutation.mutate(row.id)}>
            <Trash2 className="w-4 h-4 text-red-500" />
          </Button>
        </div>
      )
    }
  ];

  const roleLabels = {
    super_admin: 'Super Admin',
    business_admin: 'Business Admin',
    branch_manager: 'Branch Manager',
    support_staff: 'Support Staff'
  };

  const userColumns = [
    {
      header: 'User',
      cell: (row) => (
        <div>
          <p className="font-medium text-slate-900">{row.name}</p>
          <p className="text-sm text-slate-500">{row.email}</p>
        </div>
      )
    },
    {
      header: 'Role',
      cell: (row) => (
        <span className="px-2 py-1 rounded bg-slate-100 text-slate-700 text-sm">
          {roleLabels[row.role] || row.role}
        </span>
      )
    },
    {
      header: 'Branch',
      cell: (row) => row.branch_name || 'All Branches'
    },
    {
      header: 'Status',
      cell: (row) => <StatusBadge status={row.is_active ? 'active' : 'suspended'} />
    }
  ];

  return (
    <div>
      <PageHeader 
        title="Settings"
        subtitle="Configure your business settings"
      />

      <Tabs defaultValue="business" className="space-y-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="business">
            <Building2 className="w-4 h-4 mr-2" />
            Business
          </TabsTrigger>
          <TabsTrigger value="branches">
            <MapPin className="w-4 h-4 mr-2" />
            Branches
          </TabsTrigger>
          <TabsTrigger value="users">
            <Users className="w-4 h-4 mr-2" />
            Admin Users
          </TabsTrigger>
          <TabsTrigger value="payments">
            <CreditCard className="w-4 h-4 mr-2" />
            Payments
          </TabsTrigger>
          <TabsTrigger value="policies">
            <Shield className="w-4 h-4 mr-2" />
            Policies
          </TabsTrigger>
        </TabsList>

        <TabsContent value="business">
          <Card>
            <CardHeader>
              <CardTitle>Business Profile</CardTitle>
              <CardDescription>General business information</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label>Business Name</Label>
                  <Input
                    value={form.business_name}
                    onChange={(e) => setForm({ ...form, business_name: e.target.value })}
                    placeholder="CarWash Pro"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Logo URL</Label>
                  <Input
                    value={form.logo_url}
                    onChange={(e) => setForm({ ...form, logo_url: e.target.value })}
                    placeholder="https://..."
                  />
                </div>
                <div className="space-y-2">
                  <Label>Contact Email</Label>
                  <Input
                    type="email"
                    value={form.contact_email}
                    onChange={(e) => setForm({ ...form, contact_email: e.target.value })}
                    placeholder="info@carwash.com"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Contact Phone</Label>
                  <Input
                    value={form.contact_phone}
                    onChange={(e) => setForm({ ...form, contact_phone: e.target.value })}
                    placeholder="+1 234 567 8900"
                  />
                </div>
                <div className="col-span-2 space-y-2">
                  <Label>Business Address</Label>
                  <Textarea
                    value={form.address}
                    onChange={(e) => setForm({ ...form, address: e.target.value })}
                    placeholder="Enter full address..."
                  />
                </div>
              </div>
              <Button onClick={() => settingsMutation.mutate(form)}>
                <Save className="w-4 h-4 mr-2" />
                Save Changes
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="branches">
          <div className="flex justify-end mb-6">
            <Button onClick={() => openBranchModal()}>
              <Plus className="w-4 h-4 mr-2" />
              Add Branch
            </Button>
          </div>
          <DataTable
            columns={branchColumns}
            data={branches}
            isLoading={isLoading}
            emptyMessage="No branches configured"
          />
        </TabsContent>

        <TabsContent value="users">
          <DataTable
            columns={userColumns}
            data={adminUsers}
            isLoading={isLoading}
            emptyMessage="No admin users"
          />
        </TabsContent>

        <TabsContent value="payments">
          <Card>
            <CardHeader>
              <CardTitle>Payment Settings</CardTitle>
              <CardDescription>Configure taxes and fees</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label>Tax Rate (%)</Label>
                  <Input
                    type="number"
                    value={form.tax_rate}
                    onChange={(e) => setForm({ ...form, tax_rate: parseFloat(e.target.value) })}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Service Fee ($)</Label>
                  <Input
                    type="number"
                    value={form.service_fee}
                    onChange={(e) => setForm({ ...form, service_fee: parseFloat(e.target.value) })}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Currency</Label>
                  <Select
                    value={form.currency}
                    onValueChange={(v) => setForm({ ...form, currency: v })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="USD">USD ($)</SelectItem>
                      <SelectItem value="EUR">EUR (€)</SelectItem>
                      <SelectItem value="GBP">GBP (£)</SelectItem>
                      <SelectItem value="AED">AED (د.إ)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <Button onClick={() => settingsMutation.mutate(form)}>
                <Save className="w-4 h-4 mr-2" />
                Save Changes
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="policies">
          <Card>
            <CardHeader>
              <CardTitle>Cancellation Policy</CardTitle>
              <CardDescription>Set up cancellation rules</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label>Free Cancellation Window (hours)</Label>
                  <Input
                    type="number"
                    value={form.free_cancellation_hours}
                    onChange={(e) => setForm({ ...form, free_cancellation_hours: parseInt(e.target.value) })}
                  />
                  <p className="text-sm text-slate-500">
                    Customers can cancel for free up to this many hours before the booking
                  </p>
                </div>
                <div className="space-y-2">
                  <Label>Cancellation Fee (%)</Label>
                  <Input
                    type="number"
                    value={form.cancellation_fee_percentage}
                    onChange={(e) => setForm({ ...form, cancellation_fee_percentage: parseFloat(e.target.value) })}
                  />
                  <p className="text-sm text-slate-500">
                    Fee charged for late cancellations
                  </p>
                </div>
              </div>
              <div className="space-y-2">
                <Label>Cancellation Policy Text</Label>
                <Textarea
                  value={form.cancellation_policy}
                  onChange={(e) => setForm({ ...form, cancellation_policy: e.target.value })}
                  placeholder="Describe your cancellation policy..."
                  rows={4}
                />
              </div>
              <Button onClick={() => settingsMutation.mutate(form)}>
                <Save className="w-4 h-4 mr-2" />
                Save Changes
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Branch Modal */}
      <Dialog open={showBranchModal} onOpenChange={closeBranchModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingBranch ? 'Edit Branch' : 'Add New Branch'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Branch Name</Label>
              <Input
                value={branchForm.name}
                onChange={(e) => setBranchForm({ ...branchForm, name: e.target.value })}
                placeholder="Downtown Branch"
              />
            </div>
            <div className="space-y-2">
              <Label>Address</Label>
              <Textarea
                value={branchForm.address}
                onChange={(e) => setBranchForm({ ...branchForm, address: e.target.value })}
                placeholder="Full address..."
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Phone</Label>
                <Input
                  value={branchForm.phone}
                  onChange={(e) => setBranchForm({ ...branchForm, phone: e.target.value })}
                  placeholder="+1 234 567 8900"
                />
              </div>
              <div className="space-y-2">
                <Label>Email</Label>
                <Input
                  type="email"
                  value={branchForm.email}
                  onChange={(e) => setBranchForm({ ...branchForm, email: e.target.value })}
                  placeholder="branch@carwash.com"
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Service Radius (km)</Label>
              <Input
                type="number"
                value={branchForm.service_radius_km}
                onChange={(e) => setBranchForm({ ...branchForm, service_radius_km: parseFloat(e.target.value) })}
              />
            </div>
            <div className="flex items-center gap-3">
              <Switch
                checked={branchForm.is_active}
                onCheckedChange={(v) => setBranchForm({ ...branchForm, is_active: v })}
              />
              <Label>Active</Label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={closeBranchModal}>Cancel</Button>
            <Button onClick={() => branchMutation.mutate(branchForm)}>
              {editingBranch ? 'Save Changes' : 'Add Branch'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}