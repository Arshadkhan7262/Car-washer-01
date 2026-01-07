import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { base44 } from '@/api/base44Client';
import { format, addDays, startOfWeek, eachDayOfInterval } from 'date-fns';
import PageHeader from '@/components/Components/ui/PageHeader.jsx';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  Calendar, Clock, Settings, ChevronLeft, ChevronRight, 
  Users, MapPin, Save
} from 'lucide-react';
import { cn } from "@/lib/utils";

const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
const dayLabels = {
  monday: 'Monday',
  tuesday: 'Tuesday',
  wednesday: 'Wednesday',
  thursday: 'Thursday',
  friday: 'Friday',
  saturday: 'Saturday',
  sunday: 'Sunday'
};

export default function Schedule() {
  const queryClient = useQueryClient();
  const [selectedBranch, setSelectedBranch] = useState(null);
  const [weekStart, setWeekStart] = useState(startOfWeek(new Date(), { weekStartsOn: 1 }));

  const { data: branches = [], isLoading } = useQuery({
    queryKey: ['branches'],
    queryFn: () => base44.entities.Branch.list(),
  });

  const { data: bookings = [] } = useQuery({
    queryKey: ['bookings'],
    queryFn: () => base44.entities.Booking.list('-booking_date', 500),
  });

  const updateBranchMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.Branch.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['branches'] });
    }
  });

  const createBranchMutation = useMutation({
    mutationFn: (data) => base44.entities.Branch.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['branches'] });
    }
  });

  const activeBranch = selectedBranch ? branches.find(b => b.id === selectedBranch) : branches[0];
  
  const [workingHours, setWorkingHours] = useState(() => {
    const defaultHours = {};
    days.forEach(day => {
      defaultHours[day] = { open: '08:00', close: '18:00', closed: false };
    });
    return defaultHours;
  });

  React.useEffect(() => {
    if (activeBranch?.working_hours) {
      setWorkingHours(activeBranch.working_hours);
    }
  }, [activeBranch]);

  const handleSaveHours = () => {
    if (activeBranch) {
      updateBranchMutation.mutate({
        id: activeBranch.id,
        data: { working_hours: workingHours }
      });
    }
  };

  const weekDays = eachDayOfInterval({
    start: weekStart,
    end: addDays(weekStart, 6)
  });

  const getBookingsForDay = (date) => {
    const dateStr = format(date, 'yyyy-MM-dd');
    return bookings.filter(b => b.booking_date === dateStr);
  };

  const timeSlots = [];
  for (let i = 8; i <= 18; i++) {
    timeSlots.push(`${i.toString().padStart(2, '0')}:00`);
  }

  return (
    <div>
      <PageHeader 
        title="Schedule & Time Slots"
        subtitle="Manage working hours and booking capacity"
      />

      <Tabs defaultValue="calendar" className="space-y-6">
        <TabsList className="bg-white border">
          <TabsTrigger value="calendar">
            <Calendar className="w-4 h-4 mr-2" />
            Calendar View
          </TabsTrigger>
          <TabsTrigger value="hours">
            <Clock className="w-4 h-4 mr-2" />
            Working Hours
          </TabsTrigger>
          <TabsTrigger value="settings">
            <Settings className="w-4 h-4 mr-2" />
            Settings
          </TabsTrigger>
        </TabsList>

        <TabsContent value="calendar">
          {/* Branch Selector */}
          {branches.length > 0 && (
            <div className="flex items-center gap-4 mb-6">
              <Label>Branch:</Label>
              <Select 
                value={selectedBranch || branches[0]?.id}
                onValueChange={setSelectedBranch}
              >
                <SelectTrigger className="w-[200px]">
                  <SelectValue placeholder="Select branch" />
                </SelectTrigger>
                <SelectContent>
                  {branches.map(branch => (
                    <SelectItem key={branch.id} value={branch.id}>{branch.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Week Navigation */}
          <div className="flex items-center justify-between mb-6">
            <Button 
              variant="outline" 
              size="icon"
              onClick={() => setWeekStart(addDays(weekStart, -7))}
            >
              <ChevronLeft className="w-4 h-4" />
            </Button>
            <h3 className="font-semibold">
              {format(weekStart, 'MMM d')} - {format(addDays(weekStart, 6), 'MMM d, yyyy')}
            </h3>
            <Button 
              variant="outline" 
              size="icon"
              onClick={() => setWeekStart(addDays(weekStart, 7))}
            >
              <ChevronRight className="w-4 h-4" />
            </Button>
          </div>

          {/* Calendar Grid */}
          <div className="bg-white rounded-2xl border border-slate-100 overflow-hidden">
            {/* Header */}
            <div className="grid grid-cols-8 border-b">
              <div className="p-3 text-sm font-medium text-slate-500 border-r">Time</div>
              {weekDays.map(day => (
                <div 
                  key={day.toISOString()}
                  className={cn(
                    "p-3 text-center border-r last:border-r-0",
                    format(day, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd') && "bg-blue-50"
                  )}
                >
                  <p className="text-xs text-slate-500">{format(day, 'EEE')}</p>
                  <p className="font-semibold">{format(day, 'd')}</p>
                  <p className="text-xs text-slate-400 mt-1">
                    {getBookingsForDay(day).length} bookings
                  </p>
                </div>
              ))}
            </div>

            {/* Time Slots */}
            <div className="max-h-[500px] overflow-y-auto">
              {timeSlots.map(time => (
                <div key={time} className="grid grid-cols-8 border-b last:border-b-0">
                  <div className="p-2 text-xs text-slate-500 border-r bg-slate-50">
                    {time}
                  </div>
                  {weekDays.map(day => {
                    const dayBookings = getBookingsForDay(day).filter(
                      b => b.time_slot?.startsWith(time.replace(':00', ''))
                    );
                    return (
                      <div 
                        key={day.toISOString()}
                        className={cn(
                          "p-1 border-r last:border-r-0 min-h-[50px]",
                          format(day, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd') && "bg-blue-50/30"
                        )}
                      >
                        {dayBookings.map(booking => (
                          <div 
                            key={booking.id}
                            className="text-xs p-1 rounded bg-blue-100 text-blue-700 mb-1 truncate"
                            title={`${booking.customer_name} - ${booking.service_name}`}
                          >
                            {booking.customer_name?.split(' ')[0]}
                          </div>
                        ))}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        </TabsContent>

        <TabsContent value="hours">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="w-5 h-5" />
                Working Hours
                {branches.length > 0 && (
                  <Select 
                    value={selectedBranch || branches[0]?.id}
                    onValueChange={setSelectedBranch}
                  >
                    <SelectTrigger className="w-[200px] ml-4">
                      <SelectValue placeholder="Select branch" />
                    </SelectTrigger>
                    <SelectContent>
                      {branches.map(branch => (
                        <SelectItem key={branch.id} value={branch.id}>{branch.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {days.map(day => (
                  <div key={day} className="flex items-center gap-4 p-4 bg-slate-50 rounded-lg">
                    <div className="w-28 font-medium">{dayLabels[day]}</div>
                    <Switch
                      checked={!workingHours[day]?.closed}
                      onCheckedChange={(v) => setWorkingHours({
                        ...workingHours,
                        [day]: { ...workingHours[day], closed: !v }
                      })}
                    />
                    {!workingHours[day]?.closed ? (
                      <>
                        <Input
                          type="time"
                          value={workingHours[day]?.open || '08:00'}
                          onChange={(e) => setWorkingHours({
                            ...workingHours,
                            [day]: { ...workingHours[day], open: e.target.value }
                          })}
                          className="w-32"
                        />
                        <span>to</span>
                        <Input
                          type="time"
                          value={workingHours[day]?.close || '18:00'}
                          onChange={(e) => setWorkingHours({
                            ...workingHours,
                            [day]: { ...workingHours[day], close: e.target.value }
                          })}
                          className="w-32"
                        />
                      </>
                    ) : (
                      <span className="text-slate-500">Closed</span>
                    )}
                  </div>
                ))}
              </div>
              <Button className="mt-6" onClick={handleSaveHours}>
                <Save className="w-4 h-4 mr-2" />
                Save Working Hours
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="settings">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Slot Settings</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label>Slot Duration (minutes)</Label>
                  <Select defaultValue="60">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="30">30 minutes</SelectItem>
                      <SelectItem value="60">60 minutes</SelectItem>
                      <SelectItem value="90">90 minutes</SelectItem>
                      <SelectItem value="120">120 minutes</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Max Bookings per Slot</Label>
                  <Input type="number" defaultValue={2} />
                </div>
                <div className="space-y-2">
                  <Label>Buffer Between Bookings (minutes)</Label>
                  <Input type="number" defaultValue={15} />
                </div>
                <Button>Save Settings</Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Blocked Dates</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-sm text-slate-500">
                  Add dates when the business is closed (holidays, maintenance, etc.)
                </p>
                <div className="flex gap-2">
                  <Input type="date" className="flex-1" />
                  <Button>Add</Button>
                </div>
                <div className="text-sm text-slate-500 text-center py-4">
                  No blocked dates configured
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}