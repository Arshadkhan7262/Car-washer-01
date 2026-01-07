import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { 
  Plus, MoreHorizontal, Clock, DollarSign, Star, Pencil, Trash2,
  GripVertical, CheckCircle2
} from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

const vehicleTypes = ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury'];

export default function Services() {
  const queryClient = useQueryClient();
  const [showServiceModal, setShowServiceModal] = useState(false);
  const [showAddonModal, setShowAddonModal] = useState(false);
  const [editingService, setEditingService] = useState(null);
  const [editingAddon, setEditingAddon] = useState(null);

  const [serviceForm, setServiceForm] = useState({
    name: '', description: '', short_description: '', duration_minutes: 60,
    base_price: 0, pricing: {}, includes: [], is_popular: false, is_active: true
  });

  const [addonForm, setAddonForm] = useState({
    name: '', description: '', price: 0, duration_minutes: 15, is_active: true
  });

  const [newInclude, setNewInclude] = useState('');

  const { data: services = [], isLoading: servicesLoading } = useQuery({
    queryKey: ['services'],
    queryFn: () => base44.entities.Service.list('display_order', 50),
  });

  const { data: addons = [], isLoading: addonsLoading } = useQuery({
    queryKey: ['addons'],
    queryFn: () => base44.entities.Addon.list(),
  });

  const serviceMutation = useMutation({
    mutationFn: (data) => editingService 
      ? base44.entities.Service.update(editingService.id, data)
      : base44.entities.Service.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['services'] });
      closeServiceModal();
    }
  });

  const addonMutation = useMutation({
    mutationFn: (data) => editingAddon
      ? base44.entities.Addon.update(editingAddon.id, data)
      : base44.entities.Addon.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['addons'] });
      closeAddonModal();
    }
  });

  const deleteServiceMutation = useMutation({
    mutationFn: (id) => base44.entities.Service.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['services'] })
  });

  const deleteAddonMutation = useMutation({
    mutationFn: (id) => base44.entities.Addon.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['addons'] })
  });

  const openServiceModal = (service = null) => {
    if (service) {
      setEditingService(service);
      setServiceForm({
        name: service.name || '',
        description: service.description || '',
        short_description: service.short_description || '',
        duration_minutes: service.duration_minutes || 60,
        base_price: service.base_price || 0,
        pricing: service.pricing || {},
        includes: service.includes || [],
        is_popular: service.is_popular || false,
        is_active: service.is_active !== false
      });
    } else {
      setEditingService(null);
      setServiceForm({
        name: '', description: '', short_description: '', duration_minutes: 60,
        base_price: 0, pricing: {}, includes: [], is_popular: false, is_active: true
      });
    }
    setShowServiceModal(true);
  };

  const closeServiceModal = () => {
    setShowServiceModal(false);
    setEditingService(null);
  };

  const openAddonModal = (addon = null) => {
    if (addon) {
      setEditingAddon(addon);
      setAddonForm({
        name: addon.name || '',
        description: addon.description || '',
        price: addon.price || 0,
        duration_minutes: addon.duration_minutes || 15,
        is_active: addon.is_active !== false
      });
    } else {
      setEditingAddon(null);
      setAddonForm({
        name: '', description: '', price: 0, duration_minutes: 15, is_active: true
      });
    }
    setShowAddonModal(true);
  };

  const closeAddonModal = () => {
    setShowAddonModal(false);
    setEditingAddon(null);
  };

  const addInclude = () => {
    if (newInclude.trim()) {
      setServiceForm({
        ...serviceForm,
        includes: [...serviceForm.includes, newInclude.trim()]
      });
      setNewInclude('');
    }
  };

  const removeInclude = (index) => {
    setServiceForm({
      ...serviceForm,
      includes: serviceForm.includes.filter((_, i) => i !== index)
    });
  };

  const updatePricing = (type, value) => {
    setServiceForm({
      ...serviceForm,
      pricing: { ...serviceForm.pricing, [type]: parseFloat(value) || 0 }
    });
  };

  return (
    <div>
      <PageHeader 
        title="Services & Add-ons"
        subtitle="Manage your service offerings"
      />

      <Tabs defaultValue="services" className="space-y-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="services">Services ({services.length})</TabsTrigger>
          <TabsTrigger value="addons">Add-ons ({addons.length})</TabsTrigger>
        </TabsList>

        <TabsContent value="services">
          <div className="flex justify-end mb-6">
            <Button onClick={() => openServiceModal()}>
              <Plus className="w-4 h-4 mr-2" />
              Add Service
            </Button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            {services.map(service => (
              <Card key={service.id} className={!service.is_active ? 'opacity-60' : ''}>
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-2">
                      <CardTitle className="text-lg">{service.name}</CardTitle>
                      {service.is_popular && (
                        <Badge className="bg-amber-100 text-amber-700 border-amber-200">
                          <Star className="w-3 h-3 mr-1" />
                          Popular
                        </Badge>
                      )}
                    </div>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon">
                          <MoreHorizontal className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => openServiceModal(service)}>
                          <Pencil className="w-4 h-4 mr-2" />
                          Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem 
                          onClick={() => deleteServiceMutation.mutate(service.id)}
                          className="text-red-600"
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                  <p className="text-sm text-slate-500">{service.short_description}</p>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2 text-slate-600">
                      <Clock className="w-4 h-4" />
                      <span className="text-sm">{service.duration_minutes} min</span>
                    </div>
                    <div className="flex items-center gap-1 text-lg font-bold text-blue-600">
                      <DollarSign className="w-4 h-4" />
                      <span>From ${service.base_price}</span>
                    </div>
                  </div>

                  {service.includes?.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-xs font-semibold text-slate-500 uppercase">Includes</p>
                      <div className="space-y-1">
                        {service.includes.slice(0, 4).map((item, i) => (
                          <div key={i} className="flex items-center gap-2 text-sm text-slate-600">
                            <CheckCircle2 className="w-3 h-3 text-emerald-500" />
                            <span>{item}</span>
                          </div>
                        ))}
                        {service.includes.length > 4 && (
                          <p className="text-sm text-slate-400">+{service.includes.length - 4} more</p>
                        )}
                      </div>
                    </div>
                  )}

                  <div className="pt-2 border-t flex items-center justify-between">
                    <span className="text-sm text-slate-500">
                      {service.is_active ? 'Active' : 'Inactive'}
                    </span>
                    <div className={`w-2 h-2 rounded-full ${service.is_active ? 'bg-emerald-500' : 'bg-slate-300'}`} />
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="addons">
          <div className="flex justify-end mb-6">
            <Button onClick={() => openAddonModal()}>
              <Plus className="w-4 h-4 mr-2" />
              Add Add-on
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {addons.map(addon => (
              <Card key={addon.id} className={!addon.is_active ? 'opacity-60' : ''}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <h3 className="font-medium">{addon.name}</h3>
                      <p className="text-sm text-slate-500">{addon.description}</p>
                    </div>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon" className="h-8 w-8">
                          <MoreHorizontal className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => openAddonModal(addon)}>
                          <Pencil className="w-4 h-4 mr-2" />
                          Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem 
                          onClick={() => deleteAddonMutation.mutate(addon.id)}
                          className="text-red-600"
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                  <div className="flex items-center justify-between mt-3">
                    <span className="text-lg font-bold text-blue-600">+${addon.price}</span>
                    <span className="text-sm text-slate-500">+{addon.duration_minutes} min</span>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>
      </Tabs>

      {/* Service Modal */}
      <Dialog open={showServiceModal} onOpenChange={closeServiceModal}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingService ? 'Edit Service' : 'Add New Service'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2 space-y-2">
                <Label>Service Name</Label>
                <Input
                  value={serviceForm.name}
                  onChange={(e) => setServiceForm({ ...serviceForm, name: e.target.value })}
                  placeholder="Premium Wash"
                />
              </div>
              <div className="col-span-2 space-y-2">
                <Label>Short Description</Label>
                <Input
                  value={serviceForm.short_description}
                  onChange={(e) => setServiceForm({ ...serviceForm, short_description: e.target.value })}
                  placeholder="Complete exterior and interior cleaning"
                />
              </div>
              <div className="col-span-2 space-y-2">
                <Label>Full Description</Label>
                <Textarea
                  value={serviceForm.description}
                  onChange={(e) => setServiceForm({ ...serviceForm, description: e.target.value })}
                  placeholder="Detailed description..."
                  rows={3}
                />
              </div>
              <div className="space-y-2">
                <Label>Duration (minutes)</Label>
                <Input
                  type="number"
                  value={serviceForm.duration_minutes}
                  onChange={(e) => setServiceForm({ ...serviceForm, duration_minutes: parseInt(e.target.value) })}
                />
              </div>
              <div className="space-y-2">
                <Label>Base Price ($)</Label>
                <Input
                  type="number"
                  value={serviceForm.base_price}
                  onChange={(e) => setServiceForm({ ...serviceForm, base_price: parseFloat(e.target.value) })}
                />
              </div>
            </div>

            {/* Pricing by Vehicle Type */}
            <div className="space-y-3">
              <Label>Pricing by Vehicle Type</Label>
              <div className="grid grid-cols-3 gap-3">
                {vehicleTypes.map(type => (
                  <div key={type} className="space-y-1">
                    <label className="text-sm text-slate-500 capitalize">{type}</label>
                    <Input
                      type="number"
                      placeholder={serviceForm.base_price}
                      value={serviceForm.pricing[type] || ''}
                      onChange={(e) => updatePricing(type, e.target.value)}
                    />
                  </div>
                ))}
              </div>
            </div>

            {/* What's Included */}
            <div className="space-y-3">
              <Label>What's Included</Label>
              <div className="flex gap-2">
                <Input
                  value={newInclude}
                  onChange={(e) => setNewInclude(e.target.value)}
                  placeholder="Add item..."
                  onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), addInclude())}
                />
                <Button type="button" onClick={addInclude}>Add</Button>
              </div>
              <div className="flex flex-wrap gap-2">
                {serviceForm.includes.map((item, i) => (
                  <Badge key={i} variant="secondary" className="gap-1">
                    {item}
                    <button onClick={() => removeInclude(i)} className="ml-1 hover:text-red-500">×</button>
                  </Badge>
                ))}
              </div>
            </div>

            {/* Toggles */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Switch
                  checked={serviceForm.is_popular}
                  onCheckedChange={(v) => setServiceForm({ ...serviceForm, is_popular: v })}
                />
                <Label>Mark as Popular</Label>
              </div>
              <div className="flex items-center gap-3">
                <Switch
                  checked={serviceForm.is_active}
                  onCheckedChange={(v) => setServiceForm({ ...serviceForm, is_active: v })}
                />
                <Label>Active</Label>
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={closeServiceModal}>Cancel</Button>
            <Button onClick={() => serviceMutation.mutate(serviceForm)}>
              {editingService ? 'Save Changes' : 'Add Service'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Add-on Modal */}
      <Dialog open={showAddonModal} onOpenChange={closeAddonModal}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingAddon ? 'Edit Add-on' : 'Add New Add-on'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Add-on Name</Label>
              <Input
                value={addonForm.name}
                onChange={(e) => setAddonForm({ ...addonForm, name: e.target.value })}
                placeholder="Engine Wash"
              />
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Input
                value={addonForm.description}
                onChange={(e) => setAddonForm({ ...addonForm, description: e.target.value })}
                placeholder="Deep engine cleaning..."
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Price ($)</Label>
                <Input
                  type="number"
                  value={addonForm.price}
                  onChange={(e) => setAddonForm({ ...addonForm, price: parseFloat(e.target.value) })}
                />
              </div>
              <div className="space-y-2">
                <Label>Duration (min)</Label>
                <Input
                  type="number"
                  value={addonForm.duration_minutes}
                  onChange={(e) => setAddonForm({ ...addonForm, duration_minutes: parseInt(e.target.value) })}
                />
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Switch
                checked={addonForm.is_active}
                onCheckedChange={(v) => setAddonForm({ ...addonForm, is_active: v })}
              />
              <Label>Active</Label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={closeAddonModal}>Cancel</Button>
            <Button onClick={() => addonMutation.mutate(addonForm)}>
              {editingAddon ? 'Save Changes' : 'Add Add-on'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}