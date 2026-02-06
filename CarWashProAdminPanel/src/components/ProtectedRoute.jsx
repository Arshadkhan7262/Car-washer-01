import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  const [forceRender, setForceRender] = React.useState(false);

  // Safety timeout - if loading takes too long, force render
  React.useEffect(() => {
    const timer = setTimeout(() => {
      if (loading) {
        setForceRender(true);
      }
    }, 3000); // 3 second timeout
    
    return () => clearTimeout(timer);
  }, [loading]);

  // If loading takes too long, proceed anyway
  if (loading && !forceRender) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

export default ProtectedRoute;

