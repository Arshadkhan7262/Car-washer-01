import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import { Copy, Pencil, Trash2, ExternalLink, Loader2 } from 'lucide-react';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

function CMSManagement() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [deleteSlug, setDeleteSlug] = useState(null);
  const [publicBaseUrl, setPublicBaseUrl] = useState(() => {
    // Get base URL from environment or use current origin
    return import.meta.env.VITE_PUBLIC_BASE_URL || window.location.origin;
  });

  // Fetch all CMS pages
  const { data: cmsPages = [], isLoading, error } = useQuery({
    queryKey: ['cms', 'all'],
    queryFn: () => base44.entities.CMS.list(),
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: async (slug) => {
      return await base44.entities.CMS.delete(slug);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cms'] });
      toast.success('CMS page deleted successfully');
      setDeleteSlug(null);
    },
    onError: (error) => {
      console.error('Delete error:', error);
      toast.error(`Failed to delete: ${error.message || 'Unknown error'}`);
    },
  });

  const handleCopyLink = (slug) => {
    const publicUrl = `${publicBaseUrl}/view/${slug}`;
    navigator.clipboard.writeText(publicUrl).then(() => {
      toast.success('Link copied to clipboard!');
    }).catch(() => {
      toast.error('Failed to copy link');
    });
  };

  const handleEdit = (slug) => {
    // Navigate to Content page editor with the slug selected
    navigate(`/content?tab=editor&page=${slug}`);
  };

  const handleDelete = (slug) => {
    setDeleteSlug(slug);
  };

  const confirmDelete = () => {
    if (deleteSlug) {
      deleteMutation.mutate(deleteSlug);
    }
  };

  const getTargetBadge = (target) => {
    const variants = {
      customer: { label: 'Customer', className: 'bg-blue-100 text-blue-800' },
      washer: { label: 'Washer', className: 'bg-green-100 text-green-800' },
      both: { label: 'Both', className: 'bg-purple-100 text-purple-800' },
    };
    const variant = variants[target] || variants.customer;
    return <Badge className={variant.className}>{variant.label}</Badge>;
  };

  const getStatusBadge = (status) => {
    if (status === 'published') {
      return <Badge className="bg-green-100 text-green-800">Published</Badge>;
    }
    return <Badge className="bg-gray-100 text-gray-800">Draft</Badge>;
  };

  if (isLoading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
          <span className="ml-2 text-slate-600">Loading CMS pages...</span>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <CardContent className="py-12">
          <div className="text-center text-red-600">
            Error loading CMS pages: {error.message}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>CMS Pages Management</CardTitle>
          <p className="text-sm text-slate-600 mt-2">
            Manage all CMS pages. Copy public links to share with mobile apps.
          </p>
        </CardHeader>
        <CardContent>
          {cmsPages.length === 0 ? (
            <div className="text-center py-12 text-slate-500">
              No CMS pages found. Create pages using the editor tab.
            </div>
          ) : (
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Title</TableHead>
                    <TableHead>Slug</TableHead>
                    <TableHead>Target</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Public URL</TableHead>
                    <TableHead>Last Updated</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {cmsPages.map((page) => {
                    const publicUrl = `${publicBaseUrl}/view/${page.slug}`;
                    return (
                      <TableRow key={page.slug}>
                        <TableCell className="font-medium">{page.title}</TableCell>
                        <TableCell>
                          <code className="text-xs bg-slate-100 px-2 py-1 rounded">
                            {page.slug}
                          </code>
                        </TableCell>
                        <TableCell>{getTargetBadge(page.target)}</TableCell>
                        <TableCell>{getStatusBadge(page.status)}</TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <a
                              href={publicUrl}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-blue-600 hover:underline text-sm flex items-center gap-1"
                            >
                              <ExternalLink className="w-4 h-4" />
                              View
                            </a>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleCopyLink(page.slug)}
                              className="h-8 w-8 p-0"
                            >
                              <Copy className="w-4 h-4" />
                            </Button>
                          </div>
                        </TableCell>
                        <TableCell className="text-sm text-slate-600">
                          {page.updated_date
                            ? format(new Date(page.updated_date), 'MMM dd, yyyy')
                            : 'Never'}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex items-center justify-end gap-2">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleEdit(page.slug)}
                              className="h-8 w-8 p-0"
                            >
                              <Pencil className="w-4 h-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleDelete(page.slug)}
                              className="h-8 w-8 p-0 text-red-600 hover:text-red-700"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={!!deleteSlug} onOpenChange={() => setDeleteSlug(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the CMS page
              "{cmsPages.find(p => p.slug === deleteSlug)?.title || deleteSlug}".
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmDelete}
              className="bg-red-600 hover:bg-red-700"
              disabled={deleteMutation.isPending}
            >
              {deleteMutation.isPending ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Deleting...
                </>
              ) : (
                'Delete'
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}

export default CMSManagement;
