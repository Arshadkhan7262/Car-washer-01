# Job Tracking Flow Analysis

## Overview
This document analyzes the job accept/reject and tracking flows across all three applications and verifies API integration status.

---

## 1. Car Wash App (Washer) - Job Management Flow

### UI Flow Analysis

#### **Job List Screen (`jobs_screen.dart`)**
- **Tabs**: New Job, Active, Done
- **Job Cards**: Display jobs filtered by status
- **Actions Available**:
  - **New Job**: "Decline" and "Accept Job" buttons
  - **Active Job**: "View Detail" link

#### **Job Card (`job_card.dart`)**
- Shows customer name, vehicle type/model, service name, date/time, address, price
- **Status Badge**: "Confirm" (new) or "Arrived" (active)
- **Actions**:
  - Line 127-129: "Decline" button (TODO - not implemented)
  - Line 131-139: "Accept Job" button (TODO - not implemented)

#### **Job Detail Screen (`jod_detail_screen.dart`)**
- **Status Tracker**: 5 steps (Assigned → On the way → Arrived → Washing → Completed)
- **Actions**:
  - "Start Washing" button (when status = arrived)
  - "Complete Job" button (when status = washing)
  - "Open in Maps" button

#### **Job Detail Controller (`job_detail_controler.dart`)**
- Currently uses **mock data** (hardcoded `JobDetailModel`)
- `updateStep()` method only updates local state, **doesn't call API**

### Backend APIs Created ✅

1. **GET `/api/v1/washer/jobs`** - Get all jobs with status filter
2. **GET `/api/v1/washer/jobs/:id`** - Get job details
3. **POST `/api/v1/washer/jobs/:id/accept`** - Accept job (pending → accepted)
4. **POST `/api/v1/washer/jobs/:id/reject`** - Reject job (pending → cancelled)
5. **PUT `/api/v1/washer/jobs/:id/status`** - Update job status (on_the_way, arrived, in_progress)
6. **POST `/api/v1/washer/jobs/:id/complete`** - Complete job (in_progress → completed)

### Service Layer (`jobs_service.dart`) ✅

All API methods are implemented:
- `getWasherJobs()` ✅
- `getJobById()` ✅
- `acceptJob()` ✅
- `updateJobStatus()` ✅
- `completeJob()` ✅
- **Missing**: `rejectJob()` ❌

### Integration Status

| Feature | Backend API | Service Layer | Controller | UI Integration |
|---------|-------------|---------------|------------|----------------|
| Fetch Jobs | ✅ | ✅ | ❌ | ❌ (Using mock data) |
| Accept Job | ✅ | ✅ | ❌ | ❌ (TODO in UI) |
| Reject Job | ✅ | ❌ | ❌ | ❌ (TODO in UI) |
| Update Status | ✅ | ✅ | ❌ | ❌ (Local state only) |
| Complete Job | ✅ | ✅ | ❌ | ❌ (Local state only) |

### Issues Found

1. **JobController** (`jobs_controller.dart`):
   - Uses hardcoded mock data (`allJobs` list)
   - Doesn't fetch from API
   - Doesn't call `JobsService`

2. **JobCard** (`job_card.dart`):
   - Accept/Decline buttons have TODO comments
   - No API calls implemented

3. **JobDetailController** (`job_detail_controler.dart`):
   - Uses mock data
   - `updateStep()` doesn't call API
   - No integration with `JobsService`

4. **Missing Service Method**:
   - `rejectJob()` method not implemented in `JobsService`

---

## 2. Wash Away App (Customer) - Booking Tracking Flow

### UI Flow Analysis

#### **Track Order Screen (`track_order_screen.dart`)**
- **Status Timeline**: 6 steps
  1. Confirmed
  2. Washer Assigned
  3. On the Way
  4. Arrived
  5. Washing
  6. Completed
- **Current Status**: Hardcoded to `OrderStatus.confirmed`
- **Booking ID**: Hardcoded to `#699C09AC`
- **No API Integration**: Screen uses static data

### Backend APIs Created ✅

1. **GET `/api/v1/customer/bookings/:id/track`** - Get booking tracking details
   - Returns: `booking_id`, `status`, `booking_status`, `washer_name`, `timeline`, etc.
   - Maps backend status to customer UI status:
     - `pending` → `confirmed`
     - `accepted` → `washerAssigned`
     - `on_the_way` → `onTheWay`
     - `arrived` → `arrived`
     - `in_progress` → `washing`
     - `completed` → `completed`

2. **GET `/api/v1/customer/bookings`** - Get customer bookings (with status filter)

3. **GET `/api/v1/customer/bookings/:id`** - Get booking by ID

### Service Layer (`booking_service.dart`) ✅

- `createBooking()` ✅
- `getCustomerBookings()` ✅
- **Missing**: `trackBooking()` ❌
- **Missing**: `getCustomerBookingById()` ❌

### Integration Status

| Feature | Backend API | Service Layer | UI Integration |
|---------|-------------|---------------|----------------|
| Track Booking | ✅ | ❌ | ❌ (Hardcoded data) |
| Get Bookings | ✅ | ✅ | ❌ (Not used in track screen) |
| Get Booking by ID | ✅ | ❌ | ❌ |

### Issues Found

1. **TrackOrderScreen** (`track_order_screen.dart`):
   - Uses hardcoded `OrderStatus.confirmed`
   - Hardcoded booking ID `#699C09AC`
   - No API calls to fetch tracking data
   - No service integration

2. **Missing Service Methods**:
   - `trackBooking()` not implemented
   - `getCustomerBookingById()` not implemented

---

## 3. Admin Panel - Booking Management Flow

### UI Flow Analysis

#### **Booking Page (`Booking.jsx`)**
- **Tabs**: All, Pending, Active, Completed, Cancelled
- **Actions**:
  - Assign Washer (via `AssignWasherModal`)
  - Update Status (via dropdown)
  - View Details (via `BookingDetailDrawer`)

#### **Assign Washer Modal (`AssignWasherModal.jsx`)**
- Searches active washers
- Selects washer and calls `onAssign` callback
- Calls `base44.entities.Booking.assignWasher()`

#### **Booking Detail Drawer (`BookingDetailDrawer.jsx`)**
- Shows booking details
- Status stepper component
- Assign washer button
- Update status dropdown

### Backend APIs Created ✅

1. **GET `/api/v1/admin/bookings`** - Get all bookings with filters
2. **GET `/api/v1/admin/bookings/:id`** - Get booking details
3. **PUT `/api/v1/admin/bookings/:id/assign-washer`** - Assign washer to booking
   - Sets booking status to `pending` (for washer acceptance)
   - Updates `washer_id` and `washer_name`
   - Adds timeline entry

### API Client (`base44Client.js`) ✅

- `Booking.list()` ✅
- `Booking.get()` ✅
- `Booking.update()` ✅
- `Booking.assignWasher()` ✅

### Integration Status

| Feature | Backend API | API Client | UI Integration |
|---------|-------------|------------|----------------|
| List Bookings | ✅ | ✅ | ✅ |
| Get Booking | ✅ | ✅ | ✅ |
| Assign Washer | ✅ | ✅ | ✅ |
| Update Status | ✅ | ✅ | ✅ |

### Status ✅

**Admin panel is fully integrated!**

---

## Summary of Missing Integrations

### Car Wash App (Washer)

1. **JobController** needs to:
   - Fetch jobs from API using `JobsService.getWasherJobs()`
   - Map backend status to UI status:
     - `pending` → `JobStatus.newJob`
     - `accepted/on_the_way/arrived/in_progress` → `JobStatus.active`
     - `completed` → `JobStatus.done`
   - Update `allJobs` observable with API data

2. **JobCard** needs to:
   - Call `JobsService.acceptJob()` when "Accept Job" clicked
   - Call `JobsService.rejectJob()` when "Decline" clicked (needs to be added to service)

3. **JobDetailController** needs to:
   - Fetch job details using `JobsService.getJobById()`
   - Call `JobsService.updateJobStatus()` when status changes
   - Call `JobsService.completeJob()` when job completed

4. **JobsService** needs:
   - `rejectJob()` method implementation

### Wash Away App (Customer)

1. **TrackOrderScreen** needs to:
   - Accept booking ID as parameter
   - Fetch tracking data using `BookingService.trackBooking()` (needs to be added)
   - Map backend status to `OrderStatus` enum
   - Display real timeline data

2. **BookingService** needs:
   - `trackBooking(String bookingId)` method
   - `getCustomerBookingById(String bookingId)` method

---

## Status Mapping Reference

### Backend → Washer UI
- `pending` → `JobStatus.newJob`
- `accepted` → `JobStatus.active`
- `on_the_way` → `JobStatus.active`
- `arrived` → `JobStatus.active`
- `in_progress` → `JobStatus.active`
- `completed` → `JobStatus.done`
- `cancelled` → (filtered out or separate tab)

### Backend → Customer UI
- `pending` → `OrderStatus.confirmed`
- `accepted` → `OrderStatus.washerAssigned`
- `on_the_way` → `OrderStatus.onTheWay`
- `arrived` → `OrderStatus.arrived`
- `in_progress` → `OrderStatus.washing`
- `completed` → `OrderStatus.completed`

### Backend → Admin UI
- Uses backend status directly (`pending`, `accepted`, `on_the_way`, `arrived`, `in_progress`, `completed`, `cancelled`)

---

## Next Steps

1. **Implement missing service methods**:
   - `JobsService.rejectJob()`
   - `BookingService.trackBooking()`
   - `BookingService.getCustomerBookingById()`

2. **Integrate Car Wash App**:
   - Update `JobController` to fetch from API
   - Connect `JobCard` buttons to API calls
   - Connect `JobDetailController` to API calls

3. **Integrate Wash Away App**:
   - Update `TrackOrderScreen` to fetch from API
   - Pass booking ID to track screen
   - Display real tracking data

4. **Test end-to-end flow**:
   - Admin assigns washer → Washer sees job in "New Job" tab
   - Washer accepts → Job moves to "Active" tab
   - Washer updates status → Customer sees updated status
   - Washer completes → Job moves to "Done" tab, Customer sees completed

