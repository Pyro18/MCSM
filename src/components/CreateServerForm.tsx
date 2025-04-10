import React, { useState } from 'react';
import { ServerConfig } from '../types/server';
import { serverService } from '../services/serverService';

interface CreateServerFormProps {
  onServerCreated: (server: ServerConfig) => void;
}

export const CreateServerForm: React.FC<CreateServerFormProps> = ({ onServerCreated }) => {
  const [formData, setFormData] = useState<ServerConfig>({
    name: '',
    version: '1.20.4',
    port: 25565,
    memory: '2G',
    path: '',
  });
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await serverService.createServer(formData);
      onServerCreated(formData);
      setFormData({
        name: '',
        version: '1.20.4',
        port: 25565,
        memory: '2G',
        path: '',
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create server');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="server-form">
      <h2>Create New Server</h2>
      
      {error && <div className="error-message">{error}</div>}

      <div className="form-group">
        <label htmlFor="server-name">Server Name:</label>
        <input
          id="server-name"
          type="text"
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="server-version">Version:</label>
        <input
          id="server-version"
          type="text"
          value={formData.version}
          onChange={(e) => setFormData({ ...formData, version: e.target.value })}
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="server-port">Port:</label>
        <input
          id="server-port"
          type="number"
          value={formData.port}
          onChange={(e) => setFormData({ ...formData, port: parseInt(e.target.value) })}
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="server-memory">Memory:</label>
        <input
          id="server-memory"
          type="text"
          value={formData.memory}
          onChange={(e) => setFormData({ ...formData, memory: e.target.value })}
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="server-path">Server Path:</label>
        <input
          id="server-path"
          type="text"
          value={formData.path}
          onChange={(e) => setFormData({ ...formData, path: e.target.value })}
          required
        />
      </div>

      <button type="submit" disabled={loading}>
        {loading ? 'Creating...' : 'Create Server'}
      </button>
    </form>
  );
}; 