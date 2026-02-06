import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { base44 } from '@/api/base44Client';
import ReactQuill from 'react-quill';
import 'react-quill/dist/quill.snow.css';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Save, Send, Loader2, FileText, Megaphone } from 'lucide-react';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';

// Predefined CMS pages
const CMS_PAGES = [
  { slug: 'privacy-customer', title: 'Privacy Policy (Customer)', target: 'customer' },
  { slug: 'privacy-washer', title: 'Privacy Policy (Washer)', target: 'washer' },
  { slug: 'terms-customer', title: 'Terms & Conditions (Customer)', target: 'customer' },
  { slug: 'terms-washer', title: 'Terms & Conditions (Washer)', target: 'washer' },
  { slug: 'faq-general', title: 'FAQ (General)', target: 'both' },
  { slug: 'about-us', title: 'About Us', target: 'both' },
];

export default function Content() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  
  const [selectedSlug, setSelectedSlug] = useState(() => {
    return searchParams.get('page') || CMS_PAGES[0].slug;
  });
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [target, setTarget] = useState('customer');
  const [customSlug, setCustomSlug] = useState('');
  const [isCustomPage, setIsCustomPage] = useState(() => {
    const pageParam = searchParams.get('page');
    return pageParam && !CMS_PAGES.find(p => p.slug === pageParam);
  });
  const activeTab = searchParams.get('tab') || 'editor';

  // Initialize custom slug if it's a custom page
  useEffect(() => {
    const pageParam = searchParams.get('page');
    if (pageParam && !CMS_PAGES.find(p => p.slug === pageParam)) {
      setIsCustomPage(true);
      setCustomSlug(pageParam);
      setSelectedSlug('custom');
    }
  }, [searchParams]);

  // Get the actual slug to use for API calls
  const getActualSlug = () => {
    if (isCustomPage && customSlug) {
      return customSlug.toLowerCase().trim().replace(/\s+/g, '-');
    }
    return selectedSlug !== 'custom' ? selectedSlug : null;
  };

  const actualSlug = getActualSlug();

  // Fetch CMS page data
  const { data: cmsData, isLoading: isLoadingCMS } = useQuery({
    queryKey: ['cms', actualSlug],
    queryFn: () => base44.entities.CMS.get(actualSlug),
    enabled: !!actualSlug && actualSlug !== 'custom',
    onSuccess: (data) => {
      if (data) {
        setTitle(data.title || '');
        setContent(data.content || '');
        setTarget(data.target || 'customer');
      } else {
        // New page - set defaults
        const page = CMS_PAGES.find(p => p.slug === selectedSlug);
        if (page) {
          setTitle(page.title);
          setTarget(page.target);
        }
        setContent('');
      }
    },
    onError: (error) => {
      // Page doesn't exist yet - that's okay for new pages
      if (error.message.includes('404') || error.message.includes('not found')) {
        const page = CMS_PAGES.find(p => p.slug === selectedSlug);
        if (page) {
          setTitle(page.title);
          setTarget(page.target);
        }
        setContent('');
      }
    },
  });

  // Save draft mutation
  const saveDraftMutation = useMutation({
    mutationFn: async () => {
      let slug;
      if (isCustomPage) {
        slug = customSlug.toLowerCase().trim().replace(/\s+/g, '-');
        if (!slug) {
          throw new Error('Custom slug is required');
        }
        // Validate slug format
        if (!/^[a-z0-9-]+$/.test(slug)) {
          throw new Error('Slug can only contain lowercase letters, numbers, and hyphens');
        }
      } else {
        slug = selectedSlug;
      }
      
      if (!slug) {
        throw new Error('Slug is required');
      }
      if (!title.trim()) {
        throw new Error('Title is required');
      }
      if (!content.trim()) {
        throw new Error('Content is required');
      }
      
      return await base44.entities.CMS.update(slug, {
        title: title.trim(),
        content: content.trim(),
        target,
        status: 'draft',
      });
    },
    onSuccess: (data) => {
      toast.success('Draft saved successfully');
      queryClient.invalidateQueries({ queryKey: ['cms'] });
      const finalSlug = isCustomPage ? customSlug.toLowerCase().trim().replace(/\s+/g, '-') : selectedSlug;
      queryClient.invalidateQueries({ queryKey: ['cms', finalSlug] });
      // Update URL if custom page
      if (isCustomPage && finalSlug) {
        setSearchParams({ tab: activeTab, page: finalSlug });
        setIsCustomPage(false);
        setSelectedSlug(finalSlug);
      }
    },
    onError: (error) => {
      console.error('Save error:', error);
      toast.error(`Failed to save draft: ${error.message || 'Unknown error'}`);
    },
  });

  // Publish mutation
  const publishMutation = useMutation({
    mutationFn: async () => {
      let slug;
      if (isCustomPage) {
        slug = customSlug.toLowerCase().trim().replace(/\s+/g, '-');
        if (!slug) {
          throw new Error('Custom slug is required');
        }
        // Validate slug format
        if (!/^[a-z0-9-]+$/.test(slug)) {
          throw new Error('Slug can only contain lowercase letters, numbers, and hyphens');
        }
      } else {
        slug = selectedSlug;
      }
      
      if (!slug) {
        throw new Error('Slug is required');
      }
      if (!title.trim()) {
        throw new Error('Title is required');
      }
      if (!content.trim()) {
        throw new Error('Content is required');
      }
      
      // First save as draft if not already saved
      if (!cmsData) {
        await base44.entities.CMS.update(slug, {
          title: title.trim(),
          content: content.trim(),
          target,
          status: 'draft',
        });
      }
      
      // Then publish
      return await base44.entities.CMS.publish(slug);
    },
    onSuccess: (data) => {
      toast.success('Page published successfully!');
      queryClient.invalidateQueries({ queryKey: ['cms'] });
      const finalSlug = isCustomPage ? customSlug.toLowerCase().trim().replace(/\s+/g, '-') : selectedSlug;
      queryClient.invalidateQueries({ queryKey: ['cms', finalSlug] });
      // Update URL if custom page
      if (isCustomPage && finalSlug) {
        setSearchParams({ tab: activeTab, page: finalSlug });
      }
    },
    onError: (error) => {
      console.error('Publish error:', error);
      toast.error(`Failed to publish: ${error.message || 'Unknown error'}`);
    },
  });

  const handleSlugChange = (slug) => {
    if (slug === 'custom') {
      setSelectedSlug('custom');
      setIsCustomPage(true);
      setCustomSlug('');
      setTitle('');
      setContent('');
      setTarget('customer');
    } else {
      setSelectedSlug(slug);
      setIsCustomPage(false);
      setCustomSlug('');
      setSearchParams({ tab: activeTab, page: slug });
    }
  };

  const handleSaveDraft = () => {
    saveDraftMutation.mutate();
  };

  const handlePublish = () => {
    publishMutation.mutate();
  };

  const getStatusBadge = () => {
    if (!cmsData) {
      return <Badge className="bg-gray-100 text-gray-800">New</Badge>;
    }
    if (cmsData.status === 'published') {
      return <Badge className="bg-green-100 text-green-800">Published</Badge>;
    }
    return <Badge className="bg-yellow-100 text-yellow-800">Draft</Badge>;
  };

  const getTargetBadge = () => {
    const variants = {
      customer: { label: 'Customer', className: 'bg-blue-100 text-blue-800' },
      washer: { label: 'Washer', className: 'bg-green-100 text-green-800' },
      both: { label: 'Both', className: 'bg-purple-100 text-purple-800' },
    };
    const variant = variants[target] || variants.customer;
    return <Badge className={variant.className}>{variant.label}</Badge>;
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Content Management"
        description="Create and manage CMS pages for mobile apps"
        icon={Megaphone}
      />

      <Tabs value={activeTab} onValueChange={(value) => setSearchParams({ tab: value, page: selectedSlug })}>
        <TabsList>
          <TabsTrigger value="editor">Editor</TabsTrigger>
          <TabsTrigger value="pages">App Pages</TabsTrigger>
        </TabsList>

        <TabsContent value="editor" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Edit CMS Page</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Page Selection */}
              <div className="space-y-2">
                <Label>Select Page</Label>
                <Select value={selectedSlug} onValueChange={handleSlugChange}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a page" />
                  </SelectTrigger>
                  <SelectContent>
                    {CMS_PAGES.map((page) => (
                      <SelectItem key={page.slug} value={page.slug}>
                        {page.title}
                      </SelectItem>
                    ))}
                    <SelectItem value="custom">+ Create Custom Page</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Custom Slug Input */}
              {selectedSlug === 'custom' && (
                <div className="space-y-2">
                  <Label>Page Slug (URL-friendly, lowercase, no spaces)</Label>
                  <Input
                    value={customSlug}
                    onChange={(e) => {
                      setCustomSlug(e.target.value);
                      setIsCustomPage(true);
                    }}
                    placeholder="e.g., help-center, contact-us"
                  />
                  <p className="text-xs text-slate-500">
                    This will be used in the URL: /view/your-slug
                  </p>
                </div>
              )}

              {/* Title */}
              <div className="space-y-2">
                <Label>Title</Label>
                <Input
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Enter page title"
                />
              </div>

              {/* Target Audience */}
              <div className="space-y-2">
                <Label>Target Audience</Label>
                <Select value={target} onValueChange={setTarget}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="customer">Customer App</SelectItem>
                    <SelectItem value="washer">Washer App</SelectItem>
                    <SelectItem value="both">Both Apps</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Status and Target Badges */}
              <div className="flex items-center gap-4">
                <div>
                  <span className="text-sm text-slate-600 mr-2">Status:</span>
                  {getStatusBadge()}
                </div>
                <div>
                  <span className="text-sm text-slate-600 mr-2">Target:</span>
                  {getTargetBadge()}
                </div>
                {cmsData?.published_at && (
                  <div className="text-sm text-slate-600">
                    Published: {new Date(cmsData.published_at).toLocaleDateString()}
                  </div>
                )}
              </div>

              {/* Content Editor */}
              <div className="space-y-2">
                <Label>Content</Label>
                <div className="border rounded-lg">
                  <ReactQuill
                    theme="snow"
                    value={content}
                    onChange={setContent}
                    placeholder="Enter page content..."
                    modules={{
                      toolbar: [
                        [{ 'header': [1, 2, 3, false] }],
                        ['bold', 'italic', 'underline', 'strike'],
                        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
                        ['link', 'image'],
                        ['clean']
                      ],
                    }}
                  />
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-4 pt-4">
                <Button
                  onClick={handleSaveDraft}
                  disabled={saveDraftMutation.isPending || publishMutation.isPending}
                  variant="outline"
                >
                  {saveDraftMutation.isPending ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Saving...
                    </>
                  ) : (
                    <>
                      <Save className="w-4 h-4 mr-2" />
                      Save Draft
                    </>
                  )}
                </Button>
                <Button
                  onClick={handlePublish}
                  disabled={saveDraftMutation.isPending || publishMutation.isPending}
                  className="bg-emerald-600 hover:bg-emerald-700"
                >
                  {publishMutation.isPending ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Publishing...
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4 mr-2" />
                      Publish
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="pages">
          <div onClick={() => navigate('/cms-management')}>
            <Card className="cursor-pointer hover:bg-slate-50">
              <CardContent className="p-6">
                <div className="flex items-center gap-4">
                  <FileText className="w-8 h-8 text-blue-600" />
                  <div>
                    <h3 className="font-semibold">Manage All CMS Pages</h3>
                    <p className="text-sm text-slate-600">
                      View, edit, and manage all CMS pages in one place
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
