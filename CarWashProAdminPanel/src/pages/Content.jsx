import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
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
    mutationFn: (data) => editingBanner 
      ? base44.entities.Banner.update(editingBanner.id, data)
      : base44.entities.Banner.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['banners'] });
      closeBannerModal();
    }
  });

  const deleteBannerMutation = useMutation({
    mutationFn: (id) => base44.entities.Banner.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['banners'] })
  });

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
        start_date: banner.start_date || '',
        end_date: banner.end_date || '',
        is_active: banner.is_active !== false
      });
    } else {
      setEditingBanner(null);
      setBannerForm({
        title: '', subtitle: '', image_url: '', action_type: 'none',
        action_value: '', display_order: 0, start_date: '', end_date: '', is_active: true
      });
    }
    setShowBannerModal(true);
  };

  const closeBannerModal = () => {
    setShowBannerModal(false);
    setEditingBanner(null);
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
                          onClick={() => deleteBannerMutation.mutate(banner.id)}
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
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingBanner ? 'Edit Banner' : 'Add New Banner'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Title</Label>
              <Input
                value={bannerForm.title}
                onChange={(e) => setBannerForm({ ...bannerForm, title: e.target.value })}
                placeholder="Summer Sale"
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
              <Label>Image URL</Label>
              <Input
                value={bannerForm.image_url}
                onChange={(e) => setBannerForm({ ...bannerForm, image_url: e.target.value })}
                placeholder="https://..."
              />
            </div>
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
            <Button variant="outline" onClick={closeBannerModal}>Cancel</Button>
            <Button onClick={() => bannerMutation.mutate(bannerForm)}>
              {editingBanner ? 'Save Changes' : 'Add Banner'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}