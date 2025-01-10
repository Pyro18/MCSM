using System.Text.Json;
using MCSM.Core.Models;
using MCSM.Core.Utils;

namespace MCSM.Core.Services;

public class ServerListManager
{
    private readonly PathManager _pathManager;
    private readonly Logger _logger;
    private readonly UpdateManager _updateManager;
    private readonly string _serversListPath;
    private List<ServerInfo> _servers;
    private readonly Dictionary<string, ServerManager> _serverManagers;
    private readonly FileHelper _fileHelper;
    
    public event EventHandler<ServerInfo> OnServerAdded;
    public event EventHandler<ServerInfo> OnServerRemoved;
    public event EventHandler<ServerInfo> OnServerStatusChanged;
    
    public ServerListManager()
    {
        _pathManager = new PathManager();
        _logger = new Logger();
        _updateManager = new UpdateManager();
        _fileHelper = new FileHelper();
        _serversListPath = _pathManager.GetConfigFilePath("servers.json");
        _servers = new List<ServerInfo>();
        _serverManagers = new Dictionary<string, ServerManager>();
        
        LoadServers();
    }
    
    private void LoadServers()
    {
        try
        {
            if (File.Exists(_serversListPath))
            {
                var json = File.ReadAllText(_serversListPath);
                _servers = JsonSerializer.Deserialize<List<ServerInfo>>(json) ?? new List<ServerInfo>();
                
                // Initialize server managers for each server
                foreach (var server in _servers)
                {
                    _serverManagers[server.Id] = new ServerManager();
                }
            }
        }
        catch (Exception ex)
        {
            _logger.Log($"Error loading servers list: {ex.Message}", LogEntry.LogLevel.Error);
            _servers = new List<ServerInfo>();
        }
    }
    
    private async Task SaveServers()
    {
        try
        {
            var json = JsonSerializer.Serialize(_servers, new JsonSerializerOptions { WriteIndented = true });
            await _fileHelper.WriteAllTextSafeAsync(_serversListPath, json);
        }
        catch (Exception ex)
        {
            _logger.Log($"Error saving servers list: {ex.Message}", LogEntry.LogLevel.Error);
        }
    }
    
    public List<ServerInfo> GetServers()
    {
        return _servers.ToList();
    }
    
    public async Task<ServerInfo> CreateServer(string name, string version, bool isPaperMC)
    {
        // Validate server name
        if (_servers.Any(s => s.Name.Equals(name, StringComparison.OrdinalIgnoreCase)))
        {
            throw new Exception($"A server with name '{name}' already exists");
        }
    
        var server = new ServerInfo
        {
            Name = name,
            Version = version,
            IsPaperMC = isPaperMC,
            Config = new ServerConfig
            {
                ServerVersion = version
            }
        };
    
        // Download server jar
        try
        {
            var jarPath = await _updateManager.DownloadServerJar(server);
            server.Config.ServerPath = jarPath;
            
            // set default config
            server.Config.JavaPath = new FileHelper().GetJavaPath();
        
            // Set default configuration
            server.Config.JavaPath = new FileHelper().GetJavaPath();
            server.Config.WorldName = "world";
            server.Config.Port = 25565;
            server.Config.MemoryMin = 1024;
            server.Config.MemoryMax = 2048;
            server.Config.ServerIP = "0.0.0.0";
            server.Config.MaxPlayers = 20;
            server.Config.Difficulty = "normal";
            server.Config.Motd = $"A Minecraft Server - {name}";
            server.Config.OnlineMode = true;
        
            _servers.Add(server);
            _serverManagers[server.Id] = new ServerManager();
        
            await SaveServers();
            OnServerAdded?.Invoke(this, server);
        
            return server;
        }
        catch
        {
            // Cleanup if download fails
            var serverDir = _pathManager.GetServerDirectory(name);
            if (Directory.Exists(serverDir))
            {
                try { Directory.Delete(serverDir, true); } 
                catch { /* ignore cleanup errors */ }
            }
            throw;
        }
    }
    
    public async Task DeleteServer(string serverId)
    {
        var server = _servers.FirstOrDefault(s => s.Id == serverId);
        if (server == null) return;
    
        // Stop server if running
        if (server.Status == ServerStatus.Running)
        {
            await StopServer(serverId);
        }
    
        // Delete server files
        try
        {
            var serverDir = _pathManager.GetServerDirectory(server.Name);
            if (Directory.Exists(serverDir))
            {
                Directory.Delete(serverDir, true);
                _logger.Log($"Deleted server directory: {serverDir}", LogEntry.LogLevel.Info);
            }
        
            // Delete backups if they exist
            var backupDir = _pathManager.GetBackupPath(server.Name);
            if (Directory.Exists(backupDir))
            {
                Directory.Delete(backupDir, true);
                _logger.Log($"Deleted backup directory: {backupDir}", LogEntry.LogLevel.Info);
            }
        }
        catch (Exception ex)
        {
            _logger.Log($"Error deleting server files: {ex.Message}", LogEntry.LogLevel.Error);
        }
    
        // Remove from list
        _servers.Remove(server);
        if (_serverManagers.ContainsKey(serverId))
        {
            _serverManagers.Remove(serverId);
        }
    
        await SaveServers();
        OnServerRemoved?.Invoke(this, server);
    }
    
    public async Task StartServer(string serverId)
    {
        var server = _servers.FirstOrDefault(s => s.Id == serverId);
        if (server == null) return;
        
        try
        {
            server.Status = ServerStatus.Starting;
            OnServerStatusChanged?.Invoke(this, server);
            
            if (_serverManagers.TryGetValue(serverId, out var manager))
            {
                await manager.StartServer(server.Config);
                server.Status = ServerStatus.Running;
                server.LastStarted = DateTime.Now;
            }
        }
        catch (Exception ex)
        {
            server.Status = ServerStatus.Crashed;
            _logger.Log($"Error starting server {server.Name}: {ex.Message}", LogEntry.LogLevel.Error);
        }
        finally
        {
            OnServerStatusChanged?.Invoke(this, server);
            await SaveServers();
        }
    }
    
    public async Task StopServer(string serverId)
    {
        var server = _servers.FirstOrDefault(s => s.Id == serverId);
        if (server == null) return;
        
        try
        {
            server.Status = ServerStatus.Stopping;
            OnServerStatusChanged?.Invoke(this, server);
            
            if (_serverManagers.TryGetValue(serverId, out var manager))
            {
                await manager.StopServer();
                server.Status = ServerStatus.Stopped;
            }
        }
        catch (Exception ex)
        {
            server.Status = ServerStatus.Crashed;
            _logger.Log($"Error stopping server {server.Name}: {ex.Message}", LogEntry.LogLevel.Error);
        }
        finally
        {
            OnServerStatusChanged?.Invoke(this, server);
            await SaveServers();
        }
    }
    
    public async Task UpdateServerConfig(string serverId, ServerConfig config)
    {
        var server = _servers.FirstOrDefault(s => s.Id == serverId);
        if (server == null) return;
        
        server.Config = config;
        await SaveServers();
    }
    
    public ServerInfo GetServer(string serverId)
    {
        return _servers.FirstOrDefault(s => s.Id == serverId);
    }
    
    public bool IsServerRunning(string serverId)
    {
        return _serverManagers.TryGetValue(serverId, out var manager) && manager.IsServerRunning;
    }
    
    public ServerManager GetServerManager(string serverId)
    {
        _serverManagers.TryGetValue(serverId, out var manager);
        return manager;
    }
}