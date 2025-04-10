import React from 'react';
import { ServerConfig } from '../types/server';
import { useServer } from '../hooks/useServer';

interface ServerCardProps {
  server: ServerConfig;
  onDelete: (path: string) => void;
}

export const ServerCard: React.FC<ServerCardProps> = ({ server, onDelete }) => {
  const { status, loading, error, startServer, stopServer } = useServer(server.path);

  return (
    <div className="server-card">
      <h3>{server.name}</h3>
      <div className="server-info">
        <p>Version: {server.version}</p>
        <p>Port: {server.port}</p>
        <p>Memory: {server.memory}</p>
      </div>
      
      {loading ? (
        <div className="loading">Loading...</div>
      ) : error ? (
        <div className="error">{error}</div>
      ) : status ? (
        <div className="server-status">
          <p>Status: {status.running ? 'Running' : 'Stopped'}</p>
          <p>Players: {status.players}</p>
          <p>CPU: {status.cpu_usage.toFixed(1)}%</p>
          <p>Memory: {(status.memory_usage / 1024 / 1024).toFixed(1)} MB</p>
        </div>
      ) : null}

      <div className="server-actions">
        {status?.running ? (
          <button onClick={() => stopServer()} className="stop-button">
            Stop
          </button>
        ) : (
          <button onClick={() => startServer()} className="start-button">
            Start
          </button>
        )}
        <button onClick={() => onDelete(server.path)} className="delete-button">
          Delete
        </button>
      </div>
    </div>
  );
}; 