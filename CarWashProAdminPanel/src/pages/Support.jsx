import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { format } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import FilterBar from '@/components/Components/ui/FilterBar.jsx';
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { 
  MessageSquare, Clock, AlertCircle, CheckCircle2, Send, 
  User, Calendar, Tag, ExternalLink
} from 'lucide-react';
import { cn } from "@/lib/utils";

const priorityColors = {
  low: 'bg-slate-100 text-slate-600',
  medium: 'bg-amber-100 text-amber-700',
  high: 'bg-orange-100 text-orange-700',
  urgent: 'bg-red-100 text-red-700'
};

const categoryLabels = {
  payment: 'Payment Issue',
  booking: 'Booking Issue',
  service_quality: 'Service Quality',
  refund: 'Refund Request',
  app_issue: 'App Issue',
  other: 'Other'
};

export default function Support() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [priorityFilter, setPriorityFilter] = useState('all');
  const [activeTab, setActiveTab] = useState('all');
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [newMessage, setNewMessage] = useState('');
  const [internalNote, setInternalNote] = useState('');

  const { data: tickets = [], isLoading } = useQuery({
    queryKey: ['support-tickets'],
    queryFn: () => base44.entities.SupportTicket.list('-created_date', 200),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.SupportTicket.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['support-tickets'] });
    }
  });

  const handleSendMessage = () => {
    if (!newMessage.trim() || !selectedTicket) return;
    
    const messages = selectedTicket.messages || [];
    updateMutation.mutate({
      id: selectedTicket.id,
      data: {
        messages: [...messages, {
          sender: 'Admin',
          sender_type: 'admin',
          message: newMessage,
          timestamp: new Date().toISOString()
        }],
        status: selectedTicket.status === 'open' ? 'in_progress' : selectedTicket.status
      }
    });
    setNewMessage('');
    
    // Update local state
    setSelectedTicket({
      ...selectedTicket,
      messages: [...messages, {
        sender: 'Admin',
        sender_type: 'admin',
        message: newMessage,
        timestamp: new Date().toISOString()
      }]
    });
  };

  const handleStatusChange = (status) => {
    if (selectedTicket) {
      updateMutation.mutate({
        id: selectedTicket.id,
        data: { status }
      });
      setSelectedTicket({ ...selectedTicket, status });
    }
  };

  const handleSaveNote = () => {
    if (selectedTicket) {
      updateMutation.mutate({
        id: selectedTicket.id,
        data: { internal_notes: internalNote }
      });
    }
  };

  // Stats
  const openTickets = tickets.filter(t => t.status === 'open');
  const inProgressTickets = tickets.filter(t => t.status === 'in_progress');
  const urgentTickets = tickets.filter(t => t.priority === 'urgent' && t.status !== 'closed');

  const tabCounts = {
    all: tickets.length,
    open: openTickets.length,
    in_progress: inProgressTickets.length,
    resolved: tickets.filter(t => t.status === 'resolved').length,
    closed: tickets.filter(t => t.status === 'closed').length,
  };

  const filteredTickets = tickets.filter(t => {
    const matchesSearch = !search ||
      t.ticket_number?.toLowerCase().includes(search.toLowerCase()) ||
      t.customer_name?.toLowerCase().includes(search.toLowerCase()) ||
      t.subject?.toLowerCase().includes(search.toLowerCase());
    
    const matchesStatus = statusFilter === 'all' || t.status === statusFilter;
    const matchesPriority = priorityFilter === 'all' || t.priority === priorityFilter;
    
    const matchesTab = activeTab === 'all' ? true : t.status === activeTab;
    
    return matchesSearch && matchesStatus && matchesPriority && matchesTab;
  });

  const filters = [
    {
      placeholder: 'Status',
      value: statusFilter,
      onChange: setStatusFilter,
      options: [
        { value: 'open', label: 'Open' },
        { value: 'in_progress', label: 'In Progress' },
        { value: 'resolved', label: 'Resolved' },
        { value: 'closed', label: 'Closed' },
      ]
    },
    {
      placeholder: 'Priority',
      value: priorityFilter,
      onChange: setPriorityFilter,
      options: [
        { value: 'low', label: 'Low' },
        { value: 'medium', label: 'Medium' },
        { value: 'high', label: 'High' },
        { value: 'urgent', label: 'Urgent' },
      ]
    }
  ];

  return (
    <div>
      <PageHeader 
        title="Support Tickets"
        subtitle="Manage customer support requests"
      />

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-blue-50">
              <MessageSquare className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Open Tickets</p>
              <p className="text-2xl font-bold">{openTickets.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-purple-50">
              <Clock className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">In Progress</p>
              <p className="text-2xl font-bold">{inProgressTickets.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-red-50">
              <AlertCircle className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Urgent</p>
              <p className="text-2xl font-bold text-red-600">{urgentTickets.length}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-2xl p-6 border border-slate-100">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-xl bg-emerald-50">
              <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-sm text-slate-500">Resolved Today</p>
              <p className="text-2xl font-bold">{tabCounts.resolved}</p>
            </div>
          </div>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="mb-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="all">All ({tabCounts.all})</TabsTrigger>
          <TabsTrigger value="open" className="data-[state=active]:text-blue-600">
            Open ({tabCounts.open})
          </TabsTrigger>
          <TabsTrigger value="in_progress" className="data-[state=active]:text-purple-600">
            In Progress ({tabCounts.in_progress})
          </TabsTrigger>
          <TabsTrigger value="resolved" className="data-[state=active]:text-emerald-600">
            Resolved ({tabCounts.resolved})
          </TabsTrigger>
        </TabsList>
      </Tabs>

      <FilterBar
        searchValue={search}
        onSearchChange={setSearch}
        searchPlaceholder="Search tickets..."
        filters={filters}
        onClearFilters={() => {
          setSearch('');
          setStatusFilter('all');
          setPriorityFilter('all');
        }}
      />

      {/* Tickets List */}
      <div className="space-y-3">
        {isLoading ? (
          <div className="bg-white rounded-2xl p-8 text-center text-slate-500">
            Loading tickets...
          </div>
        ) : filteredTickets.length === 0 ? (
          <div className="bg-white rounded-2xl p-8 text-center text-slate-500">
            No tickets found
          </div>
        ) : (
          filteredTickets.map(ticket => (
            <div 
              key={ticket.id}
              className="bg-white rounded-2xl border border-slate-100 p-4 hover:border-slate-200 cursor-pointer transition-colors"
              onClick={() => {
                setSelectedTicket(ticket);
                setInternalNote(ticket.internal_notes || '');
              }}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-4">
                  <Avatar className="w-10 h-10">
                    <AvatarFallback className="bg-slate-100 text-slate-600">
                      {ticket.customer_name?.[0]}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-medium text-slate-900">#{ticket.ticket_number || ticket.id?.slice(-6)}</span>
                      <StatusBadge status={ticket.status} />
                      <span className={cn("px-2 py-0.5 rounded text-xs font-medium", priorityColors[ticket.priority])}>
                        {ticket.priority}
                      </span>
                    </div>
                    <p className="font-medium text-slate-900">{ticket.subject}</p>
                    <div className="flex items-center gap-4 mt-2 text-sm text-slate-500">
                      <span>{ticket.customer_name}</span>
                      <span className="flex items-center gap-1">
                        <Tag className="w-3 h-3" />
                        {categoryLabels[ticket.category] || ticket.category}
                      </span>
                      <span className="flex items-center gap-1">
                        <Calendar className="w-3 h-3" />
                        {ticket.created_date && format(new Date(ticket.created_date), 'MMM d, h:mm a')}
                      </span>
                    </div>
                  </div>
                </div>
                <div className="text-right text-sm text-slate-500">
                  <span>{ticket.messages?.length || 0} messages</span>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Ticket Detail Sheet */}
      <Sheet open={!!selectedTicket} onOpenChange={() => setSelectedTicket(null)}>
        <SheetContent className="w-full sm:max-w-xl overflow-y-auto">
          {selectedTicket && (
            <>
              <SheetHeader className="pb-4">
                <div className="flex items-center justify-between">
                  <SheetTitle>Ticket #{selectedTicket.ticket_number || selectedTicket.id?.slice(-6)}</SheetTitle>
                  <StatusBadge status={selectedTicket.status} />
                </div>
              </SheetHeader>

              <div className="space-y-6">
                {/* Ticket Info */}
                <div className="space-y-3">
                  <h3 className="font-medium text-slate-900">{selectedTicket.subject}</h3>
                  <div className="flex flex-wrap gap-2">
                    <span className={cn("px-2 py-1 rounded text-xs font-medium", priorityColors[selectedTicket.priority])}>
                      {selectedTicket.priority} priority
                    </span>
                    <span className="px-2 py-1 rounded text-xs bg-slate-100 text-slate-600">
                      {categoryLabels[selectedTicket.category]}
                    </span>
                  </div>
                </div>

                {/* Customer Info */}
                <div className="bg-slate-50 rounded-xl p-4">
                  <div className="flex items-center gap-3 mb-2">
                    <User className="w-4 h-4 text-slate-400" />
                    <span className="font-medium">{selectedTicket.customer_name}</span>
                  </div>
                  <p className="text-sm text-slate-500">{selectedTicket.customer_email}</p>
                  {selectedTicket.booking_id && (
                    <div className="flex items-center gap-2 mt-2 text-sm text-blue-600">
                      <ExternalLink className="w-3 h-3" />
                      <span>Related Booking: #{selectedTicket.booking_id?.slice(-6)}</span>
                    </div>
                  )}
                </div>

                {/* Status Actions */}
                <div className="flex gap-2">
                  <Select value={selectedTicket.status} onValueChange={handleStatusChange}>
                    <SelectTrigger className="flex-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="open">Open</SelectItem>
                      <SelectItem value="in_progress">In Progress</SelectItem>
                      <SelectItem value="resolved">Resolved</SelectItem>
                      <SelectItem value="closed">Closed</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Messages */}
                <div className="space-y-3">
                  <h4 className="text-sm font-semibold text-slate-500 uppercase">Conversation</h4>
                  <div className="space-y-3 max-h-[300px] overflow-y-auto">
                    {(selectedTicket.messages || []).map((msg, i) => (
                      <div 
                        key={i}
                        className={cn(
                          "p-3 rounded-xl",
                          msg.sender_type === 'admin' 
                            ? "bg-blue-50 ml-8" 
                            : "bg-slate-50 mr-8"
                        )}
                      >
                        <div className="flex items-center justify-between mb-1">
                          <span className="font-medium text-sm">{msg.sender}</span>
                          <span className="text-xs text-slate-500">
                            {msg.timestamp && format(new Date(msg.timestamp), 'MMM d, h:mm a')}
                          </span>
                        </div>
                        <p className="text-sm text-slate-600">{msg.message}</p>
                      </div>
                    ))}
                  </div>

                  {/* Reply Box */}
                  <div className="flex gap-2">
                    <Input
                      value={newMessage}
                      onChange={(e) => setNewMessage(e.target.value)}
                      placeholder="Type your reply..."
                      onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
                    />
                    <Button onClick={handleSendMessage}>
                      <Send className="w-4 h-4" />
                    </Button>
                  </div>
                </div>

                {/* Internal Notes */}
                <div className="space-y-3 pt-4 border-t">
                  <h4 className="text-sm font-semibold text-slate-500 uppercase">Internal Notes</h4>
                  <Textarea
                    value={internalNote}
                    onChange={(e) => setInternalNote(e.target.value)}
                    placeholder="Add internal notes..."
                    rows={3}
                  />
                  <Button variant="outline" size="sm" onClick={handleSaveNote}>
                    Save Notes
                  </Button>
                </div>
              </div>
            </>
          )}
        </SheetContent>
      </Sheet>
    </div>
  );
}