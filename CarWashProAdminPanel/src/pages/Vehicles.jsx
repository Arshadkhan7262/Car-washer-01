import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
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
  Plus, Pencil, Trash2, Car, CheckCircle2, XCircle
} from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { toast } from 'sonner';

export default function Vehicles() {
  const queryClient = useQueryClient();
  const [showModal, setShowModal] = useState(false);
  const [editingVehicleType, setEditingVehicleType] = useState(null);

  const [form, setForm] = useState({
    name: '',
    display_name: ''
  });
  const [selectedImage, setSelectedImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);

  const { data: vehicleTypes = [], isLoading } = useQuery({
    queryKey: ['vehicleTypes'],
    queryFn: () => base44.entities.VehicleType.list('display_order', 50),
  });

  const mutation = useMutation({
    mutationFn: async (formData) => {
      const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:3000/api/v1';
      const token = localStorage.getItem('admin_token');
      
      const url = editingVehicleType 
        ? `${API_BASE_URL}/admin/vehicle-types/${editingVehicleType._id}`
        : `${API_BASE_URL}/admin/vehicle-types`;
      
      const response = await fetch(url, {
        method: editingVehicleType ? 'PUT' : 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      });
      
      return response.json();
    },
    onSuccess: (response) => {
      if (response.success) {
        queryClient.invalidateQueries({ queryKey: ['vehicleTypes'] });
        closeModal();
        toast.success(editingVehicleType ? 'Vehicle type updated successfully' : 'Vehicle type created successfully');
      } else {
        toast.error(response.message || 'Failed to save vehicle type');
      }
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to save vehicle type');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => base44.entities.VehicleType.delete(id),
    onSuccess: (response) => {
      if (response.success) {
        queryClient.invalidateQueries({ queryKey: ['vehicleTypes'] });
        toast.success('Vehicle type deleted successfully');
      } else {
        toast.error(response.message || 'Failed to delete vehicle type');
      }
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to delete vehicle type');
    }
  });

  const openModal = (vehicleType = null) => {
    if (vehicleType) {
      setEditingVehicleType(vehicleType);
      setForm({
        name: vehicleType.name || '',
        display_name: vehicleType.display_name || ''
      });
      setImagePreview(vehicleType.image_url || null);
      setSelectedImage(null);
    } else {
      setEditingVehicleType(null);
      setForm({
        name: '',
        display_name: ''
      });
      setImagePreview(null);
      setSelectedImage(null);
    }
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingVehicleType(null);
    setImagePreview(null);
    setSelectedImage(null);
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedImage(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!form.name || !form.display_name) {
      toast.error('Name and Display Name are required');
      return;
    }
    
    if (!editingVehicleType && !selectedImage) {
      toast.error('Image is required');
      return;
    }

    const formData = new FormData();
    formData.append('name', form.name);
    formData.append('display_name', form.display_name);
    
    if (selectedImage) {
      formData.append('image', selectedImage);
    }

    mutation.mutate(formData);
  };

  const handleDelete = (id) => {
    if (window.confirm('Are you sure you want to delete this vehicle type?')) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <div>
      <PageHeader 
        title="Vehicle Types"
        subtitle="Manage vehicle types available for customers"
      />

      <div className="flex justify-end mb-6">
        <Button onClick={() => openModal()}>
          <Plus className="w-4 h-4 mr-2" />
          Add Vehicle Type
        </Button>
      </div>

      {isLoading ? (
        <div className="text-center py-8">Loading...</div>
      ) : vehicleTypes.length === 0 ? (
        <Card>
          <CardContent className="py-8 text-center text-gray-500">
            No vehicle types found. Create your first vehicle type.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          {vehicleTypes.map(vehicleType => (
            <Card key={vehicleType._id} className={!vehicleType.is_active ? 'opacity-60' : ''}>
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-2">
                    <Car className="w-5 h-5 text-gray-500" />
                    <CardTitle className="text-lg">{vehicleType.display_name}</CardTitle>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="sm">
                        <Pencil className="w-4 h-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onClick={() => openModal(vehicleType)}>
                        <Pencil className="w-4 h-4 mr-2" />
                        Edit
                      </DropdownMenuItem>
                      <DropdownMenuItem 
                        onClick={() => handleDelete(vehicleType._id)}
                        className="text-red-600"
                      >
                        <Trash2 className="w-4 h-4 mr-2" />
                        Delete
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </CardHeader>
              <CardContent>
                {vehicleType.image_url && (
                  <div className="mb-4">
                    <img 
                      src={vehicleType.image_url} 
                      alt={vehicleType.display_name}
                      className="w-full h-32 object-cover rounded-lg"
                    />
                  </div>
                )}
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500">Name:</span>
                    <span className="text-sm font-medium">{vehicleType.display_name}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500">Status:</span>
                    <Badge variant={vehicleType.is_active ? "default" : "secondary"}>
                      {vehicleType.is_active ? (
                        <>
                          <CheckCircle2 className="w-3 h-3 mr-1" />
                          Active
                        </>
                      ) : (
                        <>
                          <XCircle className="w-3 h-3 mr-1" />
                          Inactive
                        </>
                      )}
                    </Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Create/Edit Modal */}
      <Dialog open={showModal} onOpenChange={setShowModal}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {editingVehicleType ? 'Edit Vehicle Type' : 'Add Vehicle Type'}
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} encType="multipart/form-data">
            <div className="space-y-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Name *</Label>
                  <Input
                    id="name"
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value.toLowerCase() })}
                    placeholder="e.g., sedan"
                    required
                  />
                  <p className="text-xs text-gray-500">Lowercase identifier (e.g., sedan, suv)</p>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="display_name">Display Name *</Label>
                  <Input
                    id="display_name"
                    value={form.display_name}
                    onChange={(e) => setForm({ ...form, display_name: e.target.value })}
                    placeholder="e.g., Sedan"
                    required
                  />
                  <p className="text-xs text-gray-500">Name shown to customers</p>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="image">Vehicle Image *</Label>
                <Input
                  id="image"
                  type="file"
                  accept="image/*"
                  onChange={handleImageChange}
                  required={!editingVehicleType}
                />
                <p className="text-xs text-gray-500">Upload vehicle type image (JPEG, PNG, GIF, WebP - Max 5MB)</p>
                
                {imagePreview && (
                  <div className="mt-4">
                    <img 
                      src={imagePreview} 
                      alt="Preview" 
                      className="w-32 h-32 object-cover rounded-lg border border-gray-300"
                    />
                  </div>
                )}
              </div>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={closeModal}>
                Cancel
              </Button>
              <Button type="submit" disabled={mutation.isPending}>
                {mutation.isPending ? 'Saving...' : editingVehicleType ? 'Update' : 'Create'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}

