import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import FilterBar from '@/components/Components/ui/FilterBar.jsx';
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Star, Flag, MessageCircle, MoreHorizontal, AlertTriangle } from 'lucide-react';
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
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

const StarRating = ({ rating, size = 'default' }) => {
  const stars = [];
  for (let i = 1; i <= 5; i++) {
    stars.push(
      <Star 
        key={i}
        className={cn(
          size === 'small' ? 'w-3 h-3' : 'w-4 h-4',
          i <= rating ? 'text-amber-400 fill-amber-400' : 'text-slate-200'
        )}
      />
    );
  }
  return <div className="flex items-center gap-0.5">{stars}</div>;
};

export default function Reviews() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [ratingFilter, setRatingFilter] = useState('all');
  const [activeTab, setActiveTab] = useState('all');
  const [respondModal, setRespondModal] = useState(null);
  const [flagModal, setFlagModal] = useState(null);
  const [response, setResponse] = useState('');
  const [flagReason, setFlagReason] = useState('');

  const { data: reviews = [], isLoading } = useQuery({
    queryKey: ['reviews'],
    queryFn: () => base44.entities.Review.list('-created_date', 200),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.Review.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['reviews'] });
      setRespondModal(null);
      setFlagModal(null);
      setResponse('');
      setFlagReason('');
    }
  });

  const handleRespond = () => {
    if (respondModal) {
      updateMutation.mutate({
        id: respondModal.id,
        data: { admin_response: response }
      });
    }
  };

  const handleFlag = () => {
    if (flagModal) {
      updateMutation.mutate({
        id: flagModal.id,
        data: { is_flagged: true, flag_reason: flagReason }
      });
    }
  };

  const handleUnflag = (review) => {
    updateMutation.mutate({
      id: review.id,
      data: { is_flagged: false, flag_reason: '' }
    });
  };

  // Stats
  const avgRating = reviews.length > 0 
    ? (reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length).toFixed(1)
    : '0.0';
  const lowRatings = reviews.filter(r => r.rating <= 2);
  const flaggedReviews = reviews.filter(r => r.is_flagged);

  const filteredReviews = reviews.filter(r => {
    const matchesSearch = !search ||
      r.customer_name?.toLowerCase().includes(search.toLowerCase()) ||
      r.washer_name?.toLowerCase().includes(search.toLowerCase()) ||
      r.comment?.toLowerCase().includes(search.toLowerCase());
    
    const matchesRating = ratingFilter === 'all' || r.rating === parseInt(ratingFilter);
    
    const matchesTab = activeTab === 'all' ? true :
      activeTab === 'low' ? r.rating <= 2 :
      activeTab === 'flagged' ? r.is_flagged : true;
    
    return matchesSearch && matchesRating && matchesTab;
  });

  const filters = [
    {
      placeholder: 'Rating',
      value: ratingFilter,
      onChange: setRatingFilter,
      options: [
        { value: '5', label: '5 Stars' },
        { value: '4', label: '4 Stars' },
        { value: '3', label: '3 Stars' },
        { value: '2', label: '2 Stars' },
        { value: '1', label: '1 Star' },
      ]
    }
  ];

  return (
    <div>
      <PageHeader 
        title="Reviews & Ratings"
        subtitle="Monitor customer feedback"
      />

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-amber-50">
              <Star className="w-5 h-5 text-amber-500 fill-amber-500" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Average Rating</p>
              <p className="text-2xl font-bold">{avgRating}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <p className="text-sm text-slate-500">Total Reviews</p>
          <p className="text-2xl font-bold">{reviews.length}</p>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <p className="text-sm text-slate-500">Low Ratings (1-2 ⭐)</p>
          <p className="text-2xl font-bold text-red-500">{lowRatings.length}</p>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <p className="text-sm text-slate-500">Flagged</p>
          <p className="text-2xl font-bold text-amber-500">{flaggedReviews.length}</p>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="mb-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="all">All Reviews</TabsTrigger>
          <TabsTrigger value="low" className="data-[state=active]:text-red-600">
            Low Ratings ({lowRatings.length})
          </TabsTrigger>
          <TabsTrigger value="flagged" className="data-[state=active]:text-amber-600">
            Flagged ({flaggedReviews.length})
          </TabsTrigger>
        </TabsList>
      </Tabs>

      <FilterBar
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search reviews..."
        filters={filters}
        onClearFilters={() => {
          setSearch('');
          setRatingFilter('all');
        }}
      />

      {/* Reviews List */}
      <div className="space-y-4">
        {isLoading ? (
          <div className="bg-white rounded-2xl p-8 text-center text-slate-500">
            Loading reviews...
          </div>
        ) : filteredReviews.length === 0 ? (
          <div className="bg-white rounded-2xl p-8 text-center text-slate-500">
            No reviews found
          </div>
        ) : (
          filteredReviews.map(review => (
            <div 
              key={review.id} 
              className={cn(
                "bg-white rounded-2xl border p-6",
                review.is_flagged ? "border-amber-200 bg-amber-50/30" : "border-slate-100"
              )}
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-4">
                  <Avatar className="w-12 h-12">
                    <AvatarFallback className="bg-blue-100 text-blue-600">
                      {review.customer_name?.[0]}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-slate-900">{review.customer_name}</p>
                      {review.is_flagged && (
                        <span className="flex items-center gap-1 text-xs text-amber-600 bg-amber-100 px-2 py-0.5 rounded-full">
                          <AlertTriangle className="w-3 h-3" />
                          Flagged
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-slate-500">
                      Booking #{review.booking_id?.slice(-6)} • {review.service_name}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <StarRating rating={review.rating} />
                    <p className="text-xs text-slate-500 mt-1">
                      {review.created_date && format(new Date(review.created_date), 'MMM d, yyyy')}
                    </p>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon">
                        <MoreHorizontal className="w-4 h-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onClick={() => {
                        setRespondModal(review);
                        setResponse(review.admin_response || '');
                      }}>
                        <MessageCircle className="w-4 h-4 mr-2" />
                        {review.admin_response ? 'Edit Response' : 'Respond'}
                      </DropdownMenuItem>
                      {review.is_flagged ? (
                        <DropdownMenuItem onClick={() => handleUnflag(review)}>
                          <Flag className="w-4 h-4 mr-2" />
                          Unflag
                        </DropdownMenuItem>
                      ) : (
                        <DropdownMenuItem onClick={() => setFlagModal(review)} className="text-amber-600">
                          <Flag className="w-4 h-4 mr-2" />
                          Flag Review
                        </DropdownMenuItem>
                      )}
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>

              <p className="text-slate-600 mb-4">{review.comment || 'No comment provided'}</p>

              <div className="flex items-center gap-4 text-sm text-slate-500">
                <span>Washer: {review.washer_name}</span>
              </div>

              {review.admin_response && (
                <div className="mt-4 p-4 bg-slate-50 rounded-xl">
                  <p className="text-xs font-semibold text-slate-500 uppercase mb-2">Admin Response</p>
                  <p className="text-sm text-slate-600">{review.admin_response}</p>
                </div>
              )}

              {review.is_flagged && review.flag_reason && (
                <div className="mt-4 p-4 bg-amber-50 rounded-xl border border-amber-100">
                  <p className="text-xs font-semibold text-amber-700 uppercase mb-2">Flag Reason</p>
                  <p className="text-sm text-amber-800">{review.flag_reason}</p>
                </div>
              )}
            </div>
          ))
        )}
      </div>

      {/* Respond Modal */}
      <Dialog open={!!respondModal} onOpenChange={() => setRespondModal(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Respond to Review</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="bg-slate-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <span className="font-medium">{respondModal?.customer_name}</span>
                <StarRating rating={respondModal?.rating} size="small" />
              </div>
              <p className="text-sm text-slate-600">{respondModal?.comment}</p>
            </div>
            <div className="space-y-2">
              <Label>Your Response</Label>
              <Textarea
                value={response}
                onChange={(e) => setResponse(e.target.value)}
                placeholder="Thank you for your feedback..."
                rows={4}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setRespondModal(null)}>Cancel</Button>
            <Button onClick={handleRespond}>Save Response</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Flag Modal */}
      <Dialog open={!!flagModal} onOpenChange={() => setFlagModal(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Flag Review</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Reason for Flagging</Label>
              <Textarea
                value={flagReason}
                onChange={(e) => setFlagReason(e.target.value)}
                placeholder="Enter reason..."
                rows={3}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setFlagModal(null)}>Cancel</Button>
            <Button onClick={handleFlag} className="bg-amber-600 hover:bg-amber-700">
              Flag Review
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}