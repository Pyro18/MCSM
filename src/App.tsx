import { useState, useEffect } from 'react';
import { ServerConfig } from './types/server';
import { serverService } from './services/serverService';
import { ServerCard } from './components/ServerCard';
import { CreateServerForm } from './components/CreateServerForm';
import { JavaInfo } from './components/JavaInfo';
import './App.css';

function App() {
  const [servers, setServers] = useState<ServerConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadServers();
  }, []);

  const loadServers = async () => {
    try {
      setLoading(true);
      const serverList = await serverService.getServerList();
      setServers(serverList);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load servers');
    } finally {
      setLoading(false);
    }
  };

  const handleServerCreated = (server: ServerConfig) => {
    setServers([...servers, server]);
  };

  const handleDeleteServer = async (path: string) => {
    try {
      await serverService.deleteServer(path);
      setServers(servers.filter(server => server.path !== path));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete server');
    }
  };

  return (
    <div className="container">
      <h1>Minecraft Server Manager</h1>
      
      {error && <div className="error-message">{error}</div>}

      <JavaInfo />

      <CreateServerForm onServerCreated={handleServerCreated} />

      <div className="server-list">
        <h2>Your Servers</h2>
        {loading ? (
          <div className="loading">Loading servers...</div>
        ) : servers.length === 0 ? (
          <div className="no-servers">No servers found. Create one to get started!</div>
        ) : (
          servers.map((server) => (
            <ServerCard
              key={server.path}
              server={server}
              onDelete={handleDeleteServer}
            />
          ))
        )}
      </div>
    </div>
  );
}

export default App;
