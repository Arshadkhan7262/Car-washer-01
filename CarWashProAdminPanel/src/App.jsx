import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './layout.jsx'
import Login from './pages/Login.jsx'
import ProtectedRoute from './components/ProtectedRoute.jsx'
import Dashboard from './pages/Dashboard.jsx'
import Bookings from './pages/Booking.jsx'
import Customers from './pages/Customers.jsx'
import Washers from './pages/Washers.jsx'
import Services from './pages/Services.jsx'
import Vehicles from './pages/Vehicles.jsx'
import Coupons from './pages/Coupens.jsx'
import Schedule from './pages/Schdule.jsx'
import Payments from './pages/Payments.jsx'
import Reviews from './pages/Reviews.jsx'
import Support from './pages/Support.jsx'
import Content from './pages/Content.jsx'
import Settings from './pages/Settings.jsx'
import Reports from './pages/Reports.jsx'

function App() {
  return (
    <Routes>
      {/* Public route */}
      <Route path="/login" element={<Login />} />
      
      {/* Protected routes */}
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="bookings" element={<Bookings />} />
        <Route path="customers" element={<Customers />} />
        <Route path="washers" element={<Washers />} />
        <Route path="services" element={<Services />} />
        <Route path="vehicles" element={<Vehicles />} />
        <Route path="coupons" element={<Coupons />} />
        <Route path="schedule" element={<Schedule />} />
        <Route path="payments" element={<Payments />} />
        <Route path="reviews" element={<Reviews />} />
        <Route path="support" element={<Support />} />
        <Route path="content" element={<Content />} />
        <Route path="settings" element={<Settings />} />
        <Route path="reports" element={<Reports />} />
      </Route>
      
      {/* Catch all - redirect to login */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  )
}

export default App

