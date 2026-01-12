import React, { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { CheckCircle2, XCircle, RefreshCw, Send } from 'lucide-react';

const statusOptions = [
  { value: 'accepted', label: 'Accept Booking', icon: CheckCircle2, color: 'text-emerald-600' },
  { value: 'on_the_way', label: 'On The Way', icon: Send, color: 'text-blue-600' },
  { value: 'arrived', label: 'Arrived', icon: CheckCircle2, color: 'text-blue-600' },
  { value: 'in_progress', label: 'In Progress', icon: RefreshCw, color: 'text-purple-600' },
  { value: 'completed', label: 'Completed', icon: CheckCircle2, color: 'text-emerald-600' },
  { value: 'cancelled', label: 'Cancelled', icon: XCircle, color: 'text-red-600' },
];

export default function StatusUpdateDialog({ 
  open, 
  onClose, 
  currentStatus, 
  onStatusUpdate 
}) {
  const [selectedStatus, setSelectedStatus] = useState('');
  const [note, setNote] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async () => {
    if (!selectedStatus) {
      return;
    }

    setIsSubmitting(true);
    try {
      await onStatusUpdate(selectedStatus, note);
      setSelectedStatus('');
      setNote('');
      onClose();
    } catch (error) {
      console.error('Error updating status:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const availableStatuses = statusOptions.filter(
    opt => opt.value !== currentStatus
  );

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Update Booking Status</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="current-status">Current Status</Label>
            <div className="flex items-center gap-2 p-3 bg-slate-50 rounded-lg">
              <span className="font-medium capitalize">
                {currentStatus?.replace(/_/g, ' ') || 'N/A'}
              </span>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="new-status">New Status *</Label>
            <Select value={selectedStatus} onValueChange={setSelectedStatus}>
              <SelectTrigger id="new-status" className="w-full h-11">
                <SelectValue placeholder="Select new status">
                  {selectedStatus && (() => {
                    const selectedOption = statusOptions.find(opt => opt.value === selectedStatus);
                    if (selectedOption) {
                      const Icon = selectedOption.icon;
                      return (
                        <div className="flex items-center gap-2">
                          <Icon className={`w-4 h-4 ${selectedOption.color}`} />
                          <span>{selectedOption.label}</span>
                        </div>
                      );
                    }
                    return null;
                  })()}
                </SelectValue>
              </SelectTrigger>
              <SelectContent className="w-[var(--radix-select-trigger-width)] max-h-[300px]">
                {availableStatuses.length === 0 ? (
                  <div className="px-3 py-2 text-sm text-slate-500 text-center">
                    No other statuses available
                  </div>
                ) : (
                  availableStatuses.map((option) => {
                    const Icon = option.icon;
                    return (
                      <SelectItem 
                        key={option.value} 
                        value={option.value}
                        className="cursor-pointer py-2.5 px-3"
                      >
                        <div className="flex items-center gap-3">
                          <Icon className={`w-5 h-5 ${option.color} flex-shrink-0`} />
                          <span className="font-medium">{option.label}</span>
                        </div>
                      </SelectItem>
                    );
                  })
                )}
              </SelectContent>
            </Select>
            {selectedStatus && (
              <p className="text-xs text-slate-500 mt-1">
                Selected: {statusOptions.find(opt => opt.value === selectedStatus)?.label}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="note">Note (Optional)</Label>
            <Textarea
              id="note"
              placeholder="Add a note about this status change..."
              value={note}
              onChange={(e) => setNote(e.target.value)}
              rows={3}
            />
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button 
            onClick={handleSubmit} 
            disabled={!selectedStatus || isSubmitting}
          >
            {isSubmitting ? 'Updating...' : 'Update Status'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

