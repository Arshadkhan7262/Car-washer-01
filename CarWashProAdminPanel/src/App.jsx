import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './layout.jsx'
import Content from './pages/Content.jsx'
import CMSManagement from './pages/CMSManagement.jsx'
import BankAccounts from './pages/BankAccounts.jsx'
import Notifications from './pages/Notifications.jsx'
import PublicCMSView from './pages/PublicCMSView.jsx'

function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Navigate to="/content" replace />} />
        <Route path="content" element={<Content />} />
        <Route path="cms-management" element={<CMSManagement />} />
        <Route path="bank-accounts" element={<BankAccounts />} />
        <Route path="notifications" element={<Notifications />} />
        <Route path="view/:slug" element={<PublicCMSView />} />
      </Route>
    </Routes>
  )
}

export default App
