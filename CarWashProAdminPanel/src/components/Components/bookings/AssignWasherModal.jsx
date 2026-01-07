import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
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
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Search, Star, CheckCircle2 } from 'lucide-react';
import { cn } from "@/lib/utils";
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';

export default function AssignWasherModal({ open, onClose, onAssign, currentWasherId }) {
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState(currentWasherId);

  const { data: washers = [], isLoading } = useQuery({
    queryKey: ['washers-active'],
    queryFn: () => base44.entities.Washer.filter({ status: 'active' }),
  });

  const filteredWashers = washers.filter(w => 
    w.name?.toLowerCase().includes(search.toLowerCase()) ||
    w.phone?.includes(search)
  );

  const handleAssign = async () => {
    const washer = washers.find(w => w._id === selected || w.id === selected);
    if (washer) {
      // Pass washer data to parent
      onAssign({
        id: washer._id || washer.id,
        name: washer.name
      });
      onClose();
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Assign Washer</DialogTitle>
        </DialogHeader>

        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <Input
            placeholder="Search washers..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-10"
          />
        </div>

        <div className="max-h-[400px] overflow-y-auto space-y-2">
          {filteredWashers.map(washer => {
            const washerId = washer._id || washer.id;
            return (
            <button
              key={washerId}
              onClick={() => setSelected(washerId)}
              className={cn(
                "w-full flex items-center gap-3 p-3 rounded-xl border transition-all text-left",
                selected === washerId 
                  ? "border-blue-500 bg-blue-50" 
                  : "border-slate-100 hover:border-slate-200 hover:bg-slate-50"
              )}
            >
              <Avatar className="w-10 h-10">
                <AvatarImage src={washer.avatar} />
                <AvatarFallback className="bg-slate-100 text-slate-600">
                  {washer.name?.[0]}
                </AvatarFallback>
              </Avatar>
              
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-medium text-slate-900">{washer.name}</span>
                  <StatusBadge status={washer.online_status ? 'online' : 'offline'} showDot />
                </div>
                <div className="flex items-center gap-3 text-sm text-slate-500 mt-0.5">
                  <span className="flex items-center gap-1">
                    <Star className="w-3 h-3 text-amber-400 fill-amber-400" />
                    {washer.rating?.toFixed(1) || '0.0'}
                  </span>
                  <span>{washer.jobs_completed || 0} jobs</span>
                  <span>{washer.branch_name}</span>
                </div>
              </div>

              {selected === washerId && (
                <CheckCircle2 className="w-5 h-5 text-blue-500" />
              )}
            </button>
            );
          })}

          {filteredWashers.length === 0 && (
            <p className="text-center text-slate-500 py-8">No washers found</p>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleAssign} disabled={!selected}>
            Assign Washer
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}