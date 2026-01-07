import React, { useState } from 'react';
import { format } from 'date-fns';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import StatusBadge from '@/components/Components/ui/StatusBadge.jsx';
import BookingStatusStepper from './BookingStatusStepper.jsx';
import AssignWasherModal from './AssignWasherModal.jsx';
import StatusUpdateDialog from './StatusUpdateDialog.jsx';
import {
  User,
  Phone,
  Mail,
  Car,
  MapPin,
  Calendar,
  Clock,
  DollarSign,
  FileText,
  UserPlus,
  CheckCircle2,
  XCircle,
  RefreshCw,
  Send,
  Image
} from 'lucide-react';

export default function BookingDetailDrawer({ 
  booking, 
  open, 
  onClose, 
  onStatusChange,
  onAssignWasher 
}) {
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [showStatusDialog, setShowStatusDialog] = useState(false);

  const handleStatusUpdate = (newStatus, note) => {
    onStatusChange(String(booking._id || booking.id), newStatus, note);
  };

  if (!booking) return null;

  const statusActions = [
    { status: 'accepted', label: 'Accept Booking', icon: CheckCircle2, color: 'text-emerald-600' },
    { status: 'on_the_way', label: 'Mark On The Way', icon: RefreshCw, color: 'text-blue-600' },
    { status: 'in_progress', label: 'Start Service', icon: RefreshCw, color: 'text-purple-600' },
    { status: 'completed', label: 'Mark Completed', icon: CheckCircle2, color: 'text-emerald-600' },
    { status: 'cancelled', label: 'Cancel Booking', icon: XCircle, color: 'text-red-600' },
  ].filter(a => a.status !== booking.status);

  return (
    <>
      <Sheet open={open} onOpenChange={onClose}>
        <SheetContent className="w-full sm:max-w-xl overflow-y-auto p-4 sm:p-6">
          <SheetHeader className="pb-4">
            <div className="flex items-center justify-between">
              <SheetTitle className="text-xl">
                Booking #{booking.booking_id || booking.id?.slice(-6)}
              </SheetTitle>
              <div className="flex items-center gap-2">
                <StatusBadge status={booking.status} />
                <StatusBadge status={booking.payment_status} />
              </div>
            </div>
          </SheetHeader>

          <div className="space-y-6">
            {/* Status Stepper */}
            <div className="bg-slate-50 rounded-xl p-4">
              <BookingStatusStepper 
                currentStatus={booking.status} 
                timeline={booking.timeline}
              />
            </div>

            {/* Customer Info */}
            <div>
              <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">
                Customer
              </h3>
              <div className="bg-white border border-slate-100 rounded-xl p-4">
                <div className="flex items-center gap-3 mb-3">
                  <Avatar className="w-10 h-10">
                    <AvatarFallback className="bg-blue-100 text-blue-600">
                      {booking.customer_name?.[0]}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-medium text-slate-900">{booking.customer_name}</p>
                    <p className="text-sm text-slate-500">{booking.customer_email}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 text-sm text-slate-600">
                  <Phone className="w-4 h-4" />
                  <span>{booking.customer_phone}</span>
                </div>
              </div>
            </div>

            {/* Vehicle Info */}
            <div>
              <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">
                Vehicle
              </h3>
              <div className="bg-white border border-slate-100 rounded-xl p-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-slate-100 rounded-lg flex items-center justify-center">
                    <Car className="w-5 h-5 text-slate-600" />
                  </div>
                  <div>
                    <p className="font-medium text-slate-900">
                      {booking.vehicle_make} {booking.vehicle_model}
                    </p>
                    <p className="text-sm text-slate-500">
                      {booking.vehicle_type?.toUpperCase()} • {booking.vehicle_color} • {booking.vehicle_plate}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Service Details */}
            <div>
              <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">
                Service
              </h3>
              <div className="bg-white border border-slate-100 rounded-xl p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="font-medium text-slate-900">{booking.service_name}</span>
                  <span className="font-medium">${booking.subtotal?.toFixed(2)}</span>
                </div>
                {booking.addons?.length > 0 && (
                  <div className="space-y-2 pt-2 border-t border-slate-100">
                    {booking.addons.map((addon, i) => (
                      <div key={i} className="flex items-center justify-between text-sm">
                        <span className="text-slate-600">+ {addon.name}</span>
                        <span>${addon.price?.toFixed(2)}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Schedule & Location */}
            <div>
              <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">
                Schedule & Location
              </h3>
              <div className="bg-white border border-slate-100 rounded-xl p-4 space-y-3">
                <div className="flex items-center gap-3 text-sm">
                  <Calendar className="w-4 h-4 text-slate-400" />
                  <span>{booking.booking_date && format(new Date(booking.booking_date), 'MMMM d, yyyy')}</span>
                </div>
                <div className="flex items-center gap-3 text-sm">
                  <Clock className="w-4 h-4 text-slate-400" />
                  <span>{booking.time_slot}</span>
                </div>
                <div className="flex items-start gap-3 text-sm">
                  <MapPin className="w-4 h-4 text-slate-400 mt-0.5" />
                  <div>
                    <p className="capitalize">{booking.location_type} Service</p>
                    <p className="text-slate-500">{booking.address || booking.branch_name}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Payment Breakdown */}
            <div>
              <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">
                Payment
              </h3>
              <div className="bg-white border border-slate-100 rounded-xl p-4 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-600">Subtotal</span>
                  <span>${booking.subtotal?.toFixed(2) || '0.00'}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-600">Tax</span>
                  <span>${booking.tax?.toFixed(2) || '0.00'}</span>
                </div>
                {booking.discount > 0 && (
                  <div className="flex justify-between text-sm text-emerald-600">
                    <span>Discount {booking.coupon_code && `(${booking.coupon_code})`}</span>
                    <span>-${booking.discount?.toFixed(2)}</span>
                  </div>
                )}
                <Separator />
                <div className="flex justify-between font-semibold">
                  <span>Total</span>
                  <span>${booking.total?.toFixed(2) || '0.00'}</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-slate-500 pt-2">
                  <span className="capitalize">{booking.payment_method?.replace(/_/g, ' ')}</span>
                </div>
              </div>
            </div>

            {/* Customer Notes */}
            {booking.customer_notes && (
              <div>
                <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">
                  Customer Notes
                </h3>
                <div className="bg-amber-50 border border-amber-100 rounded-xl p-4">
                  <p className="text-sm text-amber-800">{booking.customer_notes}</p>
                </div>
              </div>
            )}

            {/* Assigned Washer */}
            <div>
              <h3 className="text-sm font-semibold text-slate-500 uppercase tracking-wider mb-3">
                Assigned Washer
              </h3>
              {booking.washer_name ? (
                <div className="bg-white border border-slate-100 rounded-xl p-4 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Avatar className="w-10 h-10">
                      <AvatarFallback className="bg-purple-100 text-purple-600">
                        {booking.washer_name?.[0]}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <p className="font-medium text-slate-900">{booking.washer_name}</p>
                      <p className="text-sm text-slate-500">Washer</p>
                    </div>
                  </div>
                  <Button variant="outline" size="sm" onClick={() => setShowAssignModal(true)}>
                    Change
                  </Button>
                </div>
              ) : (
                <Button 
                  variant="outline" 
                  className="w-full" 
                  onClick={() => setShowAssignModal(true)}
                >
                  <UserPlus className="w-4 h-4 mr-2" />
                  Assign Washer
                </Button>
              )}
            </div>

            {/* Actions */}
            <div className="space-y-3 pt-4 border-t border-slate-100">
              <Button 
                className="w-full"
                onClick={() => setShowStatusDialog(true)}
              >
                Update Status
              </Button>
              
              <div className="grid grid-cols-2 gap-3">
                <Button variant="outline">
                  <Send className="w-4 h-4 mr-2" />
                  Notify Customer
                </Button>
                <Button variant="outline">
                  <RefreshCw className="w-4 h-4 mr-2" />
                  Reschedule
                </Button>
              </div>
            </div>
          </div>
        </SheetContent>
      </Sheet>

      <AssignWasherModal
        open={showAssignModal}
        onClose={() => setShowAssignModal(false)}
        currentWasherId={booking.washer_id}
        onAssign={(washer) => onAssignWasher(String(booking._id || booking.id), washer)}
      />

      <StatusUpdateDialog
        open={showStatusDialog}
        onClose={() => setShowStatusDialog(false)}
        currentStatus={booking.status}
        onStatusUpdate={handleStatusUpdate}
      />
    </>
  );
}