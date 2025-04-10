import { useState, useEffect } from 'react';
import { ServerConfig, ServerStatus } from '../types/server';
import { serverService } from '../services/serverService';

export function useServer(serverPath: string) {
  const [status, setStatus] = useState<ServerStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refreshStatus = async () => {
    try {
      setLoading(true);
      const newStatus = await serverService.getServerStatus(serverPath);
      setStatus(newStatus);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refreshStatus();
    const interval = setInterval(refreshStatus, 5000); // Aggiorna ogni 5 secondi
    return () => clearInterval(interval);
  }, [serverPath]);

  const startServer = async () => {
    try {
      setLoading(true);
      await serverService.startServer(serverPath);
      await refreshStatus();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to start server');
    } finally {
      setLoading(false);
    }
  };

  const stopServer = async () => {
    try {
      setLoading(true);
      await serverService.stopServer(serverPath);
      await refreshStatus();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to stop server');
    } finally {
      setLoading(false);
    }
  };

  return {
    status,
    loading,
    error,
    startServer,
    stopServer,
    refreshStatus
  };
} 