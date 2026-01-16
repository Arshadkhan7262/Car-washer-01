// API client with authentication support
// Only use localhost for API calls
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:3000/api/v1'

// Helper function to get auth headers
const getAuthHeaders = () => {
  const token = localStorage.getItem('admin_token')
  const headers = {
    'Content-Type': 'application/json',
  }
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }
  return headers
}

// Helper function to make authenticated requests
const fetchWithAuth = async (url, options = {}) => {
  const headers = {
    ...getAuthHeaders(),
    ...(options.headers || {}),
  }

  const response = await fetch(url, {
    ...options,
    headers,
  })

  // Handle 401 - Unauthorized
  if (response.status === 401) {
    // Try to refresh token
    const refreshToken = localStorage.getItem('admin_refresh_token')
    if (refreshToken) {
      try {
        const refreshResponse = await fetch(`${API_BASE_URL}/admin/auth/refresh`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refreshToken }),
        })

        const refreshData = await refreshResponse.json()
        if (refreshData.success && refreshData.data.token) {
          localStorage.setItem('admin_token', refreshData.data.token)
          localStorage.setItem('admin_user', JSON.stringify(refreshData.data.admin))
          
          // Retry original request with new token
          headers['Authorization'] = `Bearer ${refreshData.data.token}`
          return fetch(url, {
            ...options,
            headers,
          })
        }
      } catch (error) {
        console.error('Token refresh failed:', error)
      }
    }

    // If refresh fails, redirect to login
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_refresh_token')
    localStorage.removeItem('admin_user')
    window.location.href = '/login'
  }

  return response
}

class Base44Client {
  constructor() {
    this.auth = {
      me: async () => {
        const response = await fetchWithAuth(`${API_BASE_URL}/admin/auth/me`)
        const data = await response.json()
        return data.success ? data.data.admin : null
      },
      login: async (email, password) => {
        const response = await fetch(`${API_BASE_URL}/admin/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password }),
        })
        return response.json()
      },
    }

    this.dashboard = {
      getKPIs: async () => {
        const response = await fetchWithAuth(`${API_BASE_URL}/admin/dashboard/kpis`)
        const data = await response.json()
        return data.success ? data.data : null
      },
      getStats: async (period = 'week') => {
        const response = await fetchWithAuth(`${API_BASE_URL}/admin/dashboard/stats?period=${period}`)
        const data = await response.json()
        return data.success ? data.data : null
      },
      getActivity: async (limit = 10) => {
        const response = await fetchWithAuth(`${API_BASE_URL}/admin/dashboard/activity?limit=${limit}`)
        const data = await response.json()
        return data.success ? data.data : []
      },
    }

    this.entities = {
      Booking: {
        list: async (sort = '-created_date', limit = 100) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bookings?sort=${sort}&limit=${limit}`)
          const data = await response.json()
          return data.data?.bookings || []
        },
        filter: async (filters) => {
          const query = new URLSearchParams(filters).toString()
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bookings?${query}`)
          const data = await response.json()
          return data.data?.bookings || []
        },
        get: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bookings/${id}`)
          const data = await response.json()
          return data.data
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bookings`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bookings/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to update booking')
          }
          return result
        },
        assignWasher: async (id, washerId, washerName) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bookings/${id}/assign-washer`, {
            method: 'PUT',
            body: JSON.stringify({ washer_id: washerId, washer_name: washerName }),
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to assign washer')
          }
          return result
        },
        delete: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bookings/${id}`, {
            method: 'DELETE',
          })
          return response.json()
        },
      },
      Customer: {
        list: async (sort = '-created_date', limit = 50) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/customers?sort=${sort}&limit=${limit}`)
          const data = await response.json()
          return data.data?.customers || []
        },
        get: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/customers/${id}`)
          const data = await response.json()
          return data.data
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/customers/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          return response.json()
        },
      },
      Washer: {
        list: async (sort = '-created_date', limit = 50) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/washers?sort=${sort}&limit=${limit}`)
          const data = await response.json()
          return data.data?.washers || []
        },
        filter: async (filters) => {
          const query = new URLSearchParams(filters).toString()
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/washers?${query}`)
          const data = await response.json()
          return data.data?.washers || []
        },
        get: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/washers/${id}`)
          const data = await response.json()
          return data.data
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/washers`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/washers/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        delete: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/washers/${id}`, {
            method: 'DELETE',
          })
          return response.json()
        },
      },
      Service: {
        list: async (sort = 'display_order', limit = 50) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/services?sort=${sort}&limit=${limit}`)
          const data = await response.json()
          return data.data || []
        },
        get: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/services/${id}`)
          const data = await response.json()
          return data.data
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/services`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/services/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        delete: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/services/${id}`, {
            method: 'DELETE',
          })
          return response.json()
        },
      },
      Addon: {
        list: async () => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/addons`)
          const data = await response.json()
          return data.data || []
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/addons`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/addons/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        delete: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/addons/${id}`, {
            method: 'DELETE',
          })
          return response.json()
        },
      },
      Coupon: {
        list: async (sort = '-created_date') => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/coupons?sort=${sort}`)
          const data = await response.json()
          return data.data || []
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/coupons`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to create coupon')
          }
          return result
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/coupons/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to update coupon')
          }
          return result
        },
        delete: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/coupons/${id}`, {
            method: 'DELETE',
          })
          return response.json()
        },
      },
      Banner: {
        list: async (sort = 'display_order') => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/settings/banners?sort=${sort}`)
          const data = await response.json()
          return data.data || []
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/settings/banners`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/settings/banners/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        delete: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/settings/banners/${id}`, {
            method: 'DELETE',
          })
          return response.json()
        },
      },
      Branch: {
        list: async () => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/branches`)
          const data = await response.json()
          return data.data || []
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/branches`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/branches/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        delete: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/branches/${id}`, {
            method: 'DELETE',
          })
          return response.json()
        },
      },
      BusinessSettings: {
        list: async () => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/settings/business`)
          const data = await response.json()
          return data.data ? [data.data] : []
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/settings/business`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/settings/business`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          return response.json()
        },
      },
      AdminUser: {
        list: async () => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/settings/admin-users`)
          const data = await response.json()
          return data.data || []
        },
      },
      VehicleType: {
        list: async (sort = 'display_order', limit = 50) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/vehicle-types?sort=${sort}&limit=${limit}`)
          const data = await response.json()
          return data.data || []
        },
        get: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/vehicle-types/${id}`)
          const data = await response.json()
          return data.data
        },
        create: async (data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/vehicle-types`, {
            method: 'POST',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        update: async (id, data) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/vehicle-types/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
          })
          return response.json()
        },
        delete: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/vehicle-types/${id}`, {
            method: 'DELETE',
          })
          return response.json()
        },
      },
    }
  }
}

export const base44 = new Base44Client()

