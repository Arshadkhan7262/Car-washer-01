import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import { toast } from 'sonner';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
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
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Plus, MoreHorizontal, Pencil, Trash2, Image, Megaphone, Send } from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export default function Content() {
  const queryClient = useQueryClient();
  const [showBannerModal, setShowBannerModal] = useState(false);
  const [editingBanner, setEditingBanner] = useState(null);
  const [selectedImage, setSelectedImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [bannerForm, setBannerForm] = useState({
    title: '', subtitle: '', image_url: '', action_type: 'none',
    action_value: '', display_order: 0, start_date: '', end_date: '', is_active: true
  });

  // Notification form state
  const [notificationForm, setNotificationForm] = useState({
    target_audience: 'all',
    title: '',
    message: ''
  });

  const { data: banners = [], isLoading } = useQuery({
    queryKey: ['banners'],
    queryFn: () => base44.entities.Banner.list('display_order'),
  });

  const bannerMutation = useMutation({
    mutationFn: (formData) => editingBanner 
      ? base44.entities.Banner.update(editingBanner.id, formData)
      : base44.entities.Banner.create(formData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['banners'] });
      closeBannerModal();
      toast.success(editingBanner ? 'Banner updated successfully' : 'Banner created successfully');
    },
    onError: (error) => {
      toast.error(`Failed to ${editingBanner ? 'update' : 'create'} banner: ${error.message || 'Unknown error'}`);
    }
  });

  const deleteBannerMutation = useMutation({
    mutationFn: (id) => base44.entities.Banner.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['banners'] });
      toast.success('Banner deleted successfully');
    },
    onError: (error) => {
      toast.error(`Failed to delete banner: ${error.message || 'Unknown error'}`);
    }
  });

  const handleDeleteBanner = (banner) => {
    if (window.confirm(`Are you sure you want to delete "${banner.title}"?`)) {
      deleteBannerMutation.mutate(banner.id);
    }
  };

  const sendNotificationMutation = useMutation({
    mutationFn: (data) => base44.notifications.send(data),
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      setNotificationForm({ target_audience: 'all', title: '', message: '' });
      const d = result.data;
      if (d?.totalSent !== undefined && d?.totalUsers !== undefined) {
        toast.success(
          `Push notification sent via Firebase. ${d.totalSent} device(s) across ${d.totalUsers} user(s)` +
          (d.totalFailed > 0 ? `, ${d.totalFailed} failed.` : '.')
        );
      } else {
        toast.success(result.message || 'Push notification sent successfully.');
      }
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to send push notification');
    }
  });

  const openBannerModal = (banner = null) => {
    if (banner) {
      setEditingBanner(banner);
      setBannerForm({
        title: banner.title || '',
        subtitle: banner.subtitle || '',
        image_url: banner.image_url || '',
        action_type: banner.action_type || 'none',
        action_value: banner.action_value || '',
        display_order: banner.display_order || 0,
        start_date: banner.start_date ? banner.start_date.split('T')[0] : '',
        end_date: banner.end_date ? banner.end_date.split('T')[0] : '',
        is_active: banner.is_active !== false
      });
      setImagePreview(banner.image_url || null);
      setSelectedImage(null);
    } else {
      setEditingBanner(null);
      setBannerForm({
        title: '', subtitle: '', image_url: '', action_type: 'none',
        action_value: '', display_order: 0, start_date: '', end_date: '', is_active: true
      });
      setImagePreview(null);
      setSelectedImage(null);
    }
    setShowBannerModal(true);
  };

  const closeBannerModal = () => {
    setShowBannerModal(false);
    setEditingBanner(null);
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
      // Clear image_url when file is selected
      setBannerForm({ ...bannerForm, image_url: '' });
    }
  };

  const handleBannerSubmit = (e) => {
    e.preventDefault();
    
    if (!bannerForm.title) {
      toast.error('Title is required');
      return;
    }

    if (!selectedImage && !bannerForm.image_url) {
      toast.error('Either upload an image or provide an image URL');
      return;
    }

    const formData = new FormData();
    formData.append('title', bannerForm.title);
    if (bannerForm.subtitle) formData.append('subtitle', bannerForm.subtitle);
    if (bannerForm.image_url && !selectedImage) formData.append('image_url', bannerForm.image_url);
    formData.append('action_type', bannerForm.action_type);
    if (bannerForm.action_value) formData.append('action_value', bannerForm.action_value);
    formData.append('display_order', bannerForm.display_order.toString());
    if (bannerForm.start_date) formData.append('start_date', bannerForm.start_date);
    if (bannerForm.end_date) formData.append('end_date', bannerForm.end_date);
    formData.append('is_active', bannerForm.is_active.toString());
    
    if (selectedImage) {
      formData.append('image', selectedImage);
    }

    bannerMutation.mutate(formData);
  };

  return (
    <div>
      <PageHeader 
        title="Content & Promotions"
        subtitle="Manage app content and marketing"
      />

      <Tabs defaultValue="banners" className="space-y-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="banners">Banners</TabsTrigger>
          <TabsTrigger value="notifications">Push Notifications</TabsTrigger>
          <TabsTrigger value="pages">App Pages</TabsTrigger>
        </TabsList>

        <TabsContent value="banners">
          <div className="flex justify-end mb-6">
            <Button onClick={() => openBannerModal()}>
              <Plus className="w-4 h-4 mr-2" />
              Add Banner
            </Button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {banners.map(banner => (
              <Card key={banner.id} className={!banner.is_active ? 'opacity-60' : ''}>
                <div className="aspect-[16/9] relative overflow-hidden rounded-t-xl bg-slate-100">
                  {banner.image_url ? (
                    <img 
                      src={banner.image_url} 
                      alt={banner.title}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center">
                      <Image className="w-12 h-12 text-slate-300" />
                    </div>
                  )}
                  {!banner.is_active && (
                    <div className="absolute top-2 left-2 px-2 py-1 bg-slate-900/70 text-white text-xs rounded">
                      Inactive
                    </div>
                  )}
                </div>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-medium text-slate-900">{banner.title}</h3>
                      {banner.subtitle && (
                        <p className="text-sm text-slate-500 mt-1">{banner.subtitle}</p>
                      )}
                    </div>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon">
                          <MoreHorizontal className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => openBannerModal(banner)}>
                          <Pencil className="w-4 h-4 mr-2" />
                          Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem 
                          onClick={() => handleDeleteBanner(banner)}
                          className="text-red-600"
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                  {(banner.start_date || banner.end_date) && (
                    <div className="mt-3 text-xs text-slate-500">
                      {banner.start_date && `From ${format(new Date(banner.start_date), 'MMM d')}`}
                      {banner.start_date && banner.end_date && ' - '}
                      {banner.end_date && `To ${format(new Date(banner.end_date), 'MMM d')}`}
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="notifications">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Megaphone className="w-5 h-5" />
                Send Push Notification
              </CardTitle>
              <p className="text-sm text-muted-foreground mt-1">
                Notifications are sent via Firebase Cloud Messaging (FCM) to the selected audience. Only users who have the app and have granted notification permission will receive them.
              </p>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label>Target Audience</Label>
                <Select 
                  value={notificationForm.target_audience}
                  onValueChange={(value) => setNotificationForm({ ...notificationForm, target_audience: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Users (all customers with FCM token)</SelectItem>
                    <SelectItem value="active">Active Customers (logged in last 30 days)</SelectItem>
                    <SelectItem value="inactive">Inactive Customers (30+ days)</SelectItem>
                    <SelectItem value="new">New Customers (last 7 days)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Title</Label>
                <Input 
                  placeholder="Special Offer!" 
                  value={notificationForm.title}
                  onChange={(e) => setNotificationForm({ ...notificationForm, title: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label>Message</Label>
                <Textarea 
                  placeholder="Get 20% off your next wash..." 
                  rows={3}
                  value={notificationForm.message}
                  onChange={(e) => setNotificationForm({ ...notificationForm, message: e.target.value })}
                />
              </div>
              <Button 
                className="w-full"
                onClick={() => {
                  if (!notificationForm.title || !notificationForm.message) {
                    toast.error('Please fill in both title and message');
                    return;
                  }
                  sendNotificationMutation.mutate({
                    target_audience: notificationForm.target_audience,
                    title: notificationForm.title,
                    message: notificationForm.message
                  });
                }}
                disabled={sendNotificationMutation.isPending}
              >
                <Send className="w-4 h-4 mr-2" />
                {sendNotificationMutation.isPending ? 'Sending...' : 'Send Notification'}
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="pages">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Terms & Conditions</CardTitle>
              </CardHeader>
              <CardContent>
                <Textarea 
                  placeholder="Enter terms and conditions..."
                  rows={10}
                />
                <Button className="mt-4">Save</Button>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>Privacy Policy</CardTitle>
              </CardHeader>
              <CardContent>
                <Textarea 
                  placeholder="Enter privacy policy..."
                  rows={10}
                />
                <Button className="mt-4">Save</Button>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>About Us</CardTitle>
              </CardHeader>
              <CardContent>
                <Textarea 
                  placeholder="Enter about us content..."
                  rows={10}
                />
                <Button className="mt-4">Save</Button>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>FAQ</CardTitle>
              </CardHeader>
              <CardContent>
                <Textarea 
                  placeholder="Enter FAQ content..."
                  rows={10}
                />
                <Button className="mt-4">Save</Button>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>

      {/* Banner Modal */}
      <Dialog open={showBannerModal} onOpenChange={closeBannerModal}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingBanner ? 'Edit Banner' : 'Add New Banner'}</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleBannerSubmit}>
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>Title *</Label>
                <Input
                  value={bannerForm.title}
                  onChange={(e) => setBannerForm({ ...bannerForm, title: e.target.value })}
                  placeholder="Summer Sale"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label>Subtitle</Label>
                <Input
                  value={bannerForm.subtitle}
                  onChange={(e) => setBannerForm({ ...bannerForm, subtitle: e.target.value })}
                  placeholder="Up to 30% off"
                />
              </div>
              <div className="space-y-2">
                <Label>Upload Image (Optional)</Label>
                <Input
                  type="file"
                  accept="image/*"
                  onChange={handleImageChange}
                />
                <p className="text-xs text-slate-500">Upload image from your system (JPEG, PNG, GIF, WebP - Max 5MB)</p>
              </div>
              <div className="space-y-2">
                <Label>OR Image URL (Optional)</Label>
                <Input
                  value={bannerForm.image_url}
                  onChange={(e) => {
                    setBannerForm({ ...bannerForm, image_url: e.target.value });
                    if (e.target.value) {
                      setImagePreview(e.target.value);
                      setSelectedImage(null);
                    }
                  }}
                  placeholder="https://..."
                  disabled={!!selectedImage}
                />
                <p className="text-xs text-slate-500">Provide image URL if not uploading a file</p>
              </div>
              {imagePreview && (
                <div className="mt-4">
                  <Label>Preview</Label>
                  <img 
                    src={imagePreview} 
                    alt="Banner preview" 
                    className="w-full h-48 object-cover rounded-lg border border-slate-300 mt-2"
                  />
                </div>
              )}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Action Type</Label>
                <Select
                  value={bannerForm.action_type}
                  onValueChange={(v) => setBannerForm({ ...bannerForm, action_type: v })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="none">None</SelectItem>
                    <SelectItem value="service">Service</SelectItem>
                    <SelectItem value="coupon">Coupon</SelectItem>
                    <SelectItem value="url">External URL</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Display Order</Label>
                <Input
                  type="number"
                  value={bannerForm.display_order}
                  onChange={(e) => setBannerForm({ ...bannerForm, display_order: parseInt(e.target.value) })}
                />
              </div>
            </div>
            {bannerForm.action_type !== 'none' && (
              <div className="space-y-2">
                <Label>Action Value</Label>
                <Input
                  value={bannerForm.action_value}
                  onChange={(e) => setBannerForm({ ...bannerForm, action_value: e.target.value })}
                  placeholder={bannerForm.action_type === 'url' ? 'https://...' : 'ID or code'}
                />
              </div>
            )}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Start Date</Label>
                <Input
                  type="date"
                  value={bannerForm.start_date}
                  onChange={(e) => setBannerForm({ ...bannerForm, start_date: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label>End Date</Label>
                <Input
                  type="date"
                  value={bannerForm.end_date}
                  onChange={(e) => setBannerForm({ ...bannerForm, end_date: e.target.value })}
                />
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Switch
                checked={bannerForm.is_active}
                onCheckedChange={(v) => setBannerForm({ ...bannerForm, is_active: v })}
              />
              <Label>Active</Label>
            </div>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={closeBannerModal}>Cancel</Button>
              <Button type="submit" disabled={bannerMutation.isPending}>
                {bannerMutation.isPending ? 'Saving...' : editingBanner ? 'Save Changes' : 'Add Banner'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}