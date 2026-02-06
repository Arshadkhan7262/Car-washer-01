const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:3000/api/v1';

const fetchWithAuth = async (url, options = {}) => {
  const token = localStorage.getItem('admin_token');
  
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers,
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({ message: 'Request failed' }));
    throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
  }

  return response;
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

    this.entities = {
      CMS: {
        list: async () => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/cms`)
          const data = await response.json()
          return data.success ? data.data : []
        },
        get: async (slug) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/cms/${slug}`)
          const data = await response.json()
          return data.success ? data.data : null
        },
        update: async (slug, payload) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/cms/${slug}`, {
            method: 'PUT',
            body: JSON.stringify(payload),
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to update CMS page')
          }
          return result
        },
        publish: async (slug) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/cms/${slug}/publish`, {
            method: 'POST',
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to publish CMS page')
          }
          return result
        },
        delete: async (slug) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/cms/${slug}`, {
            method: 'DELETE',
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to delete CMS page')
          }
          return result
        },
      },
      BankAccount: {
        list: async (filters = {}) => {
          const query = new URLSearchParams(filters).toString()
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bank-accounts?${query}`)
          const data = await response.json()
          return data.success ? data.data : []
        },
        get: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bank-accounts/${id}`)
          const data = await response.json()
          return data.success ? data.data : null
        },
        verify: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bank-accounts/${id}/verify`, {
            method: 'PUT',
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to verify bank account')
          }
          return result
        },
        reject: async (id, reason = '') => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/bank-accounts/${id}/reject`, {
            method: 'PUT',
            body: JSON.stringify({ reason }),
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to reject bank account')
          }
          return result
        },
      },
      Withdrawal: {
        list: async (filters = {}) => {
          const query = new URLSearchParams(filters).toString()
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/withdrawal/all?${query}`)
          const data = await response.json()
          return data.data?.withdrawals || data.data || []
        },
        get: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/withdrawal/${id}`)
          const data = await response.json()
          return data.data
        },
        approve: async (id, note = null) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/withdrawal/${id}/approve`, {
            method: 'PUT',
            body: JSON.stringify({ note }),
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to approve withdrawal')
          }
          return result
        },
        process: async (id) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/withdrawal/${id}/process`, {
            method: 'PUT',
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to process withdrawal')
          }
          return result
        },
        reject: async (id, reason) => {
          const response = await fetchWithAuth(`${API_BASE_URL}/admin/withdrawal/${id}/reject`, {
            method: 'PUT',
            body: JSON.stringify({ reason }),
          })
          const result = await response.json()
          if (!response.ok || !result.success) {
            throw new Error(result.message || result.error?.message || 'Failed to reject withdrawal')
          }
          return result
        },
      },
    }
  }
}

export const base44 = new Base44Client();
export default base44;
