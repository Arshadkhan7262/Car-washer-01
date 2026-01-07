import React, { createContext, useContext, useState, useEffect } from 'react';
import { toast } from 'sonner';

const AuthContext = createContext(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [refreshToken, setRefreshToken] = useState(null);
  const [loading, setLoading] = useState(true);

  // Load auth state from localStorage on mount
  useEffect(() => {
    const storedToken = localStorage.getItem('admin_token');
    const storedRefreshToken = localStorage.getItem('admin_refresh_token');
    const storedUser = localStorage.getItem('admin_user');

    if (storedToken && storedUser) {
      setToken(storedToken);
      setRefreshToken(storedRefreshToken);
      setUser(JSON.parse(storedUser));
    }
    setLoading(false);
  }, []);

  // Login function
  const login = async (email, password) => {
    try {
      const response = await fetch('http://127.0.0.1:3000/api/v1/admin/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();

      if (!response.ok || !data.success) {
        throw new Error(data.message || 'Login failed');
      }

      // Save tokens and user data
      const { token: newToken, refreshToken: newRefreshToken, admin } = data.data;
      
      setToken(newToken);
      setRefreshToken(newRefreshToken);
      setUser(admin);

      // Store in localStorage
      localStorage.setItem('admin_token', newToken);
      localStorage.setItem('admin_refresh_token', newRefreshToken);
      localStorage.setItem('admin_user', JSON.stringify(admin));

      toast.success('Login successful!');
      return { success: true };
    } catch (error) {
      toast.error(error.message || 'Login failed. Please check your credentials.');
      return { success: false, error: error.message };
    }
  };

  // Logout function
  const logout = async () => {
    try {
      // Call logout API if token exists
      if (token) {
        await fetch('http://127.0.0.1:3000/api/v1/admin/auth/logout', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
          },
        }).catch(() => {
          // Ignore errors on logout
        });
      }
    } catch (error) {
      // Ignore errors
    } finally {
      // Clear state and localStorage
      setToken(null);
      setRefreshToken(null);
      setUser(null);
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_refresh_token');
      localStorage.removeItem('admin_user');
      toast.success('Logged out successfully');
    }
  };

  // Refresh access token
  const refreshAccessToken = async () => {
    if (!refreshToken) {
      return false;
    }

    try {
      const response = await fetch('http://127.0.0.1:3000/api/v1/admin/auth/refresh', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ refreshToken }),
      });

      const data = await response.json();

      if (!response.ok || !data.success) {
        throw new Error(data.message || 'Token refresh failed');
      }

      const { token: newToken, admin } = data.data;
      setToken(newToken);
      setUser(admin);
      localStorage.setItem('admin_token', newToken);
      localStorage.setItem('admin_user', JSON.stringify(admin));

      return true;
    } catch (error) {
      // Refresh failed, logout user
      logout();
      return false;
    }
  };

  // Get current user
  const getMe = async () => {
    if (!token) {
      return null;
    }

    try {
      const response = await fetch('http://127.0.0.1:3000/api/v1/admin/auth/me', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      const data = await response.json();

      if (!response.ok || !data.success) {
        // If 401, try to refresh token
        if (response.status === 401) {
          const refreshed = await refreshAccessToken();
          if (refreshed) {
            return getMe(); // Retry with new token
          }
        }
        throw new Error(data.message || 'Failed to get user');
      }

      setUser(data.data.admin);
      localStorage.setItem('admin_user', JSON.stringify(data.data.admin));
      return data.data.admin;
    } catch (error) {
      console.error('Get me error:', error);
      return null;
    }
  };

  const value = {
    user,
    token,
    refreshToken,
    loading,
    login,
    logout,
    refreshAccessToken,
    getMe,
    isAuthenticated: !!token && !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

