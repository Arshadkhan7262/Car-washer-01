import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Loader2, Plus } from 'lucide-react';

const vehicleTypes = ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury'];
const paymentMethods = ['cash', 'card', 'apple_pay', 'google_pay', 'wallet'];

export default function CreateBookingModal({ open, onClose }) {
  const queryClient = useQueryClient();
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    customer_name: '',
    customer_phone: '',
    customer_email: '',
    vehicle_type: 'sedan',
    vehicle_make: '',
    vehicle_model: '',
    vehicle_color: '',
    vehicle_plate: '',
    service_id: '',
    service_name: '',
    addons: [],
    booking_date: '',
    time_slot: '',
    location_type: 'home',
    address: '',
    branch_id: '',
    payment_method: 'cash',
    customer_notes: '',
    subtotal: 0,
    tax: 0,
    total: 0,
  });

  const { data: services = [] } = useQuery({
    queryKey: ['services'],
    queryFn: () => base44.entities.Service.filter({ is_active: true }),
  });

  const { data: addons = [] } = useQuery({
    queryKey: ['addons'],
    queryFn: () => base44.entities.Addon.filter({ is_active: true }),
  });

  const { data: branches = [] } = useQuery({
    queryKey: ['branches'],
    queryFn: () => base44.entities.Branch.list(),
  });

  const createBookingMutation = useMutation({
    mutationFn: (data) => base44.entities.Booking.create({
      ...data,
      booking_id: `BK-${Date.now().toString(36).toUpperCase()}`,
      status: 'pending',
      payment_status: 'unpaid',
      timeline: [{ status: 'pending', timestamp: new Date().toISOString(), note: 'Booking created' }]
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      onClose();
      resetForm();
    }
  });

  const resetForm = () => {
    setFormData({
      customer_name: '',
      customer_phone: '',
      customer_email: '',
      vehicle_type: 'sedan',
      vehicle_make: '',
      vehicle_model: '',
      vehicle_color: '',
      vehicle_plate: '',
      service_id: '',
      service_name: '',
      addons: [],
      booking_date: '',
      time_slot: '',
      location_type: 'home',
      address: '',
      branch_id: '',
      payment_method: 'cash',
      customer_notes: '',
      subtotal: 0,
      tax: 0,
      total: 0,
    });
    setStep(1);
  };

  const handleServiceChange = (serviceId) => {
    const service = services.find(s => s.id === serviceId);
    if (service) {
      const price = service.pricing?.[formData.vehicle_type] || service.base_price || 0;
      setFormData({
        ...formData,
        service_id: serviceId,
        service_name: service.name,
        subtotal: price,
        tax: price * 0.08,
        total: price * 1.08,
      });
    }
  };

  const handleAddonToggle = (addon) => {
    const exists = formData.addons.find(a => a.name === addon.name);
    let newAddons;
    if (exists) {
      newAddons = formData.addons.filter(a => a.name !== addon.name);
    } else {
      newAddons = [...formData.addons, { name: addon.name, price: addon.price }];
    }
    
    const addonTotal = newAddons.reduce((sum, a) => sum + a.price, 0);
    const selectedService = services.find(s => s.id === formData.service_id);
    const servicePrice = selectedService?.pricing?.[formData.vehicle_type] || selectedService?.base_price || 0;
    const subtotal = servicePrice + addonTotal;
    
    setFormData({
      ...formData,
      addons: newAddons,
      subtotal,
      tax: subtotal * 0.08,
      total: subtotal * 1.08,
    });
  };

  const handleSubmit = () => {
    createBookingMutation.mutate(formData);
  };

  const timeSlots = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
    '04:00 PM', '05:00 PM', '06:00 PM'
  ];

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Booking</DialogTitle>
        </DialogHeader>

        {/* Step Indicator */}
        <div className="flex items-center justify-center gap-2 py-4">
          {[1, 2, 3, 4].map(s => (
            <div 
              key={s}
              className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium transition-colors ${
                s === step 
                  ? 'bg-blue-600 text-white' 
                  : s < step 
                    ? 'bg-emerald-100 text-emerald-600' 
                    : 'bg-slate-100 text-slate-400'
              }`}
            >
              {s}
            </div>
          ))}
        </div>

        <div className="space-y-4">
          {/* Step 1: Customer Info */}
          {step === 1 && (
            <div className="space-y-4">
              <h3 className="font-medium text-slate-900">Customer Information</h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Full Name *</Label>
                  <Input
                    value={formData.customer_name}
                    onChange={(e) => setFormData({ ...formData, customer_name: e.target.value })}
                    placeholder="John Doe"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Phone *</Label>
                  <Input
                    value={formData.customer_phone}
                    onChange={(e) => setFormData({ ...formData, customer_phone: e.target.value })}
                    placeholder="+1 234 567 8900"
                  />
                </div>
                <div className="col-span-2 space-y-2">
                  <Label>Email</Label>
                  <Input
                    type="email"
                    value={formData.customer_email}
                    onChange={(e) => setFormData({ ...formData, customer_email: e.target.value })}
                    placeholder="john@example.com"
                  />
                </div>
              </div>

              <h3 className="font-medium text-slate-900 pt-4">Vehicle Information</h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Vehicle Type</Label>
                  <Select
                    value={formData.vehicle_type}
                    onValueChange={(v) => setFormData({ ...formData, vehicle_type: v })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {vehicleTypes.map(t => (
                        <SelectItem key={t} value={t} className="capitalize">{t}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Make</Label>
                  <Input
                    value={formData.vehicle_make}
                    onChange={(e) => setFormData({ ...formData, vehicle_make: e.target.value })}
                    placeholder="Toyota"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Model</Label>
                  <Input
                    value={formData.vehicle_model}
                    onChange={(e) => setFormData({ ...formData, vehicle_model: e.target.value })}
                    placeholder="Camry"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Color</Label>
                  <Input
                    value={formData.vehicle_color}
                    onChange={(e) => setFormData({ ...formData, vehicle_color: e.target.value })}
                    placeholder="Black"
                  />
                </div>
                <div className="col-span-2 space-y-2">
                  <Label>License Plate</Label>
                  <Input
                    value={formData.vehicle_plate}
                    onChange={(e) => setFormData({ ...formData, vehicle_plate: e.target.value })}
                    placeholder="ABC 1234"
                  />
                </div>
              </div>
            </div>
          )}

          {/* Step 2: Service Selection */}
          {step === 2 && (
            <div className="space-y-4">
              <h3 className="font-medium text-slate-900">Select Service</h3>
              <div className="grid grid-cols-2 gap-3">
                {services.map(service => (
                  <button
                    key={service.id}
                    onClick={() => handleServiceChange(service.id)}
                    className={`p-4 rounded-xl border text-left transition-all ${
                      formData.service_id === service.id
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-slate-200 hover:border-slate-300'
                    }`}
                  >
                    <p className="font-medium text-slate-900">{service.name}</p>
                    <p className="text-sm text-slate-500">{service.short_description}</p>
                    <p className="text-lg font-semibold text-blue-600 mt-2">
                      ${service.pricing?.[formData.vehicle_type] || service.base_price}
                    </p>
                  </button>
                ))}
              </div>

              {addons.length > 0 && (
                <>
                  <h3 className="font-medium text-slate-900 pt-4">Add-ons</h3>
                  <div className="grid grid-cols-2 gap-3">
                    {addons.map(addon => (
                      <label
                        key={addon.id}
                        className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer ${
                          formData.addons.find(a => a.name === addon.name)
                            ? 'border-blue-500 bg-blue-50'
                            : 'border-slate-200'
                        }`}
                      >
                        <Checkbox
                          checked={!!formData.addons.find(a => a.name === addon.name)}
                          onCheckedChange={() => handleAddonToggle(addon)}
                        />
                        <div className="flex-1">
                          <p className="font-medium text-sm">{addon.name}</p>
                          <p className="text-sm text-slate-500">+${addon.price}</p>
                        </div>
                      </label>
                    ))}
                  </div>
                </>
              )}
            </div>
          )}

          {/* Step 3: Schedule & Location */}
          {step === 3 && (
            <div className="space-y-4">
              <h3 className="font-medium text-slate-900">Schedule</h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Date *</Label>
                  <Input
                    type="date"
                    value={formData.booking_date}
                    onChange={(e) => setFormData({ ...formData, booking_date: e.target.value })}
                    min={new Date().toISOString().split('T')[0]}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Time Slot *</Label>
                  <Select
                    value={formData.time_slot}
                    onValueChange={(v) => setFormData({ ...formData, time_slot: v })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select time" />
                    </SelectTrigger>
                    <SelectContent>
                      {timeSlots.map(t => (
                        <SelectItem key={t} value={t}>{t}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <h3 className="font-medium text-slate-900 pt-4">Location</h3>
              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setFormData({ ...formData, location_type: 'home' })}
                  className={`p-4 rounded-xl border text-center ${
                    formData.location_type === 'home'
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-slate-200'
                  }`}
                >
                  <p className="font-medium">Home Service</p>
                  <p className="text-sm text-slate-500">We come to you</p>
                </button>
                <button
                  type="button"
                  onClick={() => setFormData({ ...formData, location_type: 'branch' })}
                  className={`p-4 rounded-xl border text-center ${
                    formData.location_type === 'branch'
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-slate-200'
                  }`}
                >
                  <p className="font-medium">Branch Visit</p>
                  <p className="text-sm text-slate-500">Visit our location</p>
                </button>
              </div>

              {formData.location_type === 'home' ? (
                <div className="space-y-2">
                  <Label>Address *</Label>
                  <Textarea
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    placeholder="Enter full address..."
                  />
                </div>
              ) : (
                <div className="space-y-2">
                  <Label>Select Branch *</Label>
                  <Select
                    value={formData.branch_id}
                    onValueChange={(v) => {
                      const branch = branches.find(b => b.id === v);
                      setFormData({ ...formData, branch_id: v, branch_name: branch?.name });
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
              )}
            </div>
          )}

          {/* Step 4: Payment & Confirmation */}
          {step === 4 && (
            <div className="space-y-4">
              <h3 className="font-medium text-slate-900">Payment Method</h3>
              <Select
                value={formData.payment_method}
                onValueChange={(v) => setFormData({ ...formData, payment_method: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {paymentMethods.map(m => (
                    <SelectItem key={m} value={m} className="capitalize">
                      {m.replace(/_/g, ' ')}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>

              <div className="space-y-2">
                <Label>Notes for Washer</Label>
                <Textarea
                  value={formData.customer_notes}
                  onChange={(e) => setFormData({ ...formData, customer_notes: e.target.value })}
                  placeholder="Any special instructions..."
                />
              </div>

              <div className="bg-slate-50 rounded-xl p-4 space-y-2">
                <h4 className="font-medium text-slate-900">Order Summary</h4>
                <div className="flex justify-between text-sm">
                  <span>{formData.service_name}</span>
                  <span>${(formData.subtotal - formData.addons.reduce((s, a) => s + a.price, 0)).toFixed(2)}</span>
                </div>
                {formData.addons.map((addon, i) => (
                  <div key={i} className="flex justify-between text-sm text-slate-600">
                    <span>+ {addon.name}</span>
                    <span>${addon.price.toFixed(2)}</span>
                  </div>
                ))}
                <div className="flex justify-between text-sm text-slate-600 pt-2 border-t">
                  <span>Tax (8%)</span>
                  <span>${formData.tax.toFixed(2)}</span>
                </div>
                <div className="flex justify-between font-semibold text-lg pt-2 border-t">
                  <span>Total</span>
                  <span>${formData.total.toFixed(2)}</span>
                </div>
              </div>
            </div>
          )}
        </div>

        <DialogFooter className="gap-2">
          {step > 1 && (
            <Button variant="outline" onClick={() => setStep(step - 1)}>
              Back
            </Button>
          )}
          {step < 4 ? (
            <Button onClick={() => setStep(step + 1)}>
              Continue
            </Button>
          ) : (
            <Button 
              onClick={handleSubmit} 
              disabled={createBookingMutation.isPending}
            >
              {createBookingMutation.isPending && (
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              )}
              Create Booking
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}