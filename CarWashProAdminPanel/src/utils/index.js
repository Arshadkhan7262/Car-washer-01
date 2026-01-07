export function createPageUrl(pageName) {
  const pageMap = {
    'Dashboard': '/dashboard',
    'Bookings': '/bookings',
    'Customers': '/customers',
    'Washers': '/washers',
    'Services': '/services',
    'Vehicles': '/vehicles',
    'Coupons': '/coupons',
    'Schedule': '/schedule',
    'Payments': '/payments',
    'Reviews': '/reviews',
    'Support': '/support',
    'Content': '/content',
    'Settings': '/settings',
    'Reports': '/reports',
  }
  return pageMap[pageName] || '/dashboard'
}

