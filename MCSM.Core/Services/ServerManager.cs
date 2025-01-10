using System.Text.RegularExpressions;
using MCSM.Core.Utils;

namespace MCSM.Core.Services;

using MCSM.Core.Models;
using System.Diagnostics;

public class ServerManager
{
    private int _currentPlayers = 0;
    private int _maxPlayers = 20;
    private long _memoryUsage = 0;
    private bool _isInitialized = false;
    
    public int CurrentPlayers => _currentPlayers;
    public int MaxPlayers => _maxPlayers;
    public long MemoryUsage => _memoryUsage;
    
    private static readonly Regex MemoryRegex = new(@"\[(\d{2}:\d{2}:\d{2})\] \[Server thread\/INFO\]: \* (\d+) MB");
    private readonly System.Timers.Timer _memoryCheckTimer;
    
    private Process _serverProcess;
    private readonly Logger _logger;
    private readonly ConfigManager _configManager;
    private readonly PathManager _pathManager;
    private ServerConfig _currentConfig;

    public bool IsServerRunning => _serverProcess != null && !_serverProcess.HasExited;

    public ServerManager()
    {
        _logger = new Logger();
        _configManager = new ConfigManager();
        _pathManager = new PathManager();
        
        _memoryCheckTimer = new System.Timers.Timer(5000); // Ogni 5 secondi
        _memoryCheckTimer.Elapsed += async (s, e) => await CheckMemoryUsage();
    }

    public async Task StartServer(ServerConfig config)
    {
        if (IsServerRunning)
            throw new InvalidOperationException("Server is already running!");

        _currentConfig = config;
        
        // Validate and find server JAR
        if (!File.Exists(config.ServerPath))
        {
            throw new InvalidOperationException("Server JAR file not found!");
        }

        var serverDirectory = Path.GetDirectoryName(config.ServerPath);
        if (string.IsNullOrEmpty(serverDirectory) || !Directory.Exists(serverDirectory))
        {
            throw new InvalidOperationException("Invalid server directory!");
        }

        // Validate Java installation
        var fileHelper = new FileHelper();
        var javaPath = string.IsNullOrEmpty(config.JavaPath) ? fileHelper.GetJavaPath() : config.JavaPath;
        
        if (!fileHelper.IsValidJavaInstallation(javaPath))
        {
            throw new InvalidOperationException("Invalid Java installation!");
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = javaPath,
            Arguments = $"-Xmx{config.MemoryMax}M -Xms{config.MemoryMin}M -jar \"{config.ServerPath}\" nogui",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            RedirectStandardInput = true,
            CreateNoWindow = true,
            WorkingDirectory = serverDirectory
        };

        _serverProcess = new Process { StartInfo = startInfo };
        _serverProcess.OutputDataReceived += (s, e) => 
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                ProcessServerOutput(e.Data);
                _logger.Log(e.Data, LogEntry.LogLevel.Info);
            }
        };

        _serverProcess.ErrorDataReceived += (s, e) =>
        {
            if (!string.IsNullOrEmpty(e.Data))
                _logger.Log(e.Data, LogEntry.LogLevel.Error);
        };
        
        await CreateEula(serverDirectory);

        await Task.Run(() =>
        {
            _serverProcess.Start();
            _memoryCheckTimer.Start();
            _serverProcess.BeginOutputReadLine();
            _serverProcess.BeginErrorReadLine();
            
            _logger.Log("Server process started successfully", LogEntry.LogLevel.Info);
        });

        // Create or update server.properties
        await CreateServerProperties(serverDirectory);
    }
    
    private async Task CreateEula(string serverDirectory)
    {
        var eulaPath = Path.Combine(serverDirectory, "eula.txt");
        var eulaContent = "eula=true";
    
        await File.WriteAllTextAsync(eulaPath, eulaContent);
        _logger.Log("EULA automatically accepted", LogEntry.LogLevel.Info);
    }
    
    private void ProcessServerOutput(string line)
    {
        if (string.IsNullOrEmpty(line)) return;

        try 
        {
            // Inizializzazione una tantum
            if (!_isInitialized && line.Contains("Done ("))
            {
                _isInitialized = true;
                var propsPath = Path.Combine(Path.GetDirectoryName(_currentConfig.ServerPath), "server.properties");
                if (File.Exists(propsPath))
                {
                    var props = File.ReadAllLines(propsPath);
                    var maxPlayersLine = props.FirstOrDefault(l => l.StartsWith("max-players="));
                    if (maxPlayersLine != null && int.TryParse(maxPlayersLine.Split('=')[1], out int max))
                    {
                        _maxPlayers = max;
                    }
                }
            }

            // Parse memory usage (usiamo il formato del log di Minecraft)
            var memMatch = MemoryRegex.Match(line);
            if (memMatch.Success)
            {
                if (long.TryParse(memMatch.Groups[2].Value, out long memory))
                {
                    _memoryUsage = memory;
                }
            }
            
            // Parse player join/leave (manteniamo il conteggio)
            if (line.Contains("joined the game"))
            {
                _currentPlayers++;
                _logger.Log($"Player joined. Current players: {_currentPlayers}", LogEntry.LogLevel.Debug);
            }
            else if (line.Contains("left the game"))
            {
                _currentPlayers = Math.Max(0, _currentPlayers - 1);
                _logger.Log($"Player left. Current players: {_currentPlayers}", LogEntry.LogLevel.Debug);
            }
        }
        catch (Exception ex)
        {
            _logger.Log($"Error processing server output: {ex.Message}", LogEntry.LogLevel.Error);
        }
    }
    
    private async Task CheckMemoryUsage()
    {
        if (IsServerRunning && _serverProcess != null)
        {
            try
            {
                // Invia comando GC e memoria al server
                _serverProcess.StandardInput.WriteLine("gc");
                _serverProcess.StandardInput.WriteLine("mem");
            }
            catch (Exception ex)
            {
                _logger.Log($"Error checking memory: {ex.Message}", LogEntry.LogLevel.Error);
            }
        }
    }

    
    public ServerStats GetStatus()
    {
        return new ServerStats
        {
            IsRunning = IsServerRunning,
            CurrentPlayers = _currentPlayers,
            MaxPlayers = _maxPlayers,
            MemoryUsage = _memoryUsage
        };
    }
    
    private async Task CreateServerProperties(string serverDirectory)
    {
        var propertiesPath = Path.Combine(serverDirectory, "server.properties");
        var properties = new Dictionary<string, string>
        {
            {"server-port", _currentConfig.Port.ToString()},
            {"server-ip", _currentConfig.ServerIP},
            {"level-name", _currentConfig.WorldName},
            {"max-players", _currentConfig.MaxPlayers.ToString()},
            {"difficulty", _currentConfig.Difficulty},
            {"enable-command-block", _currentConfig.EnableCommandBlock.ToString().ToLower()},
            {"motd", _currentConfig.Motd},
            {"online-mode", _currentConfig.OnlineMode.ToString().ToLower()},
            {"query.port", _currentConfig.Port.ToString()}
        };

        var lines = properties.Select(p => $"{p.Key}={p.Value}");
        await File.WriteAllLinesAsync(propertiesPath, lines);
        
        _logger.Log("Server properties file created/updated", LogEntry.LogLevel.Info);
    }

    public async Task StopServer()
    {
        if (!IsServerRunning)
            return;

        await Task.Run(() =>
        {
            _serverProcess.StandardInput.WriteLine("stop");
            if (!_serverProcess.WaitForExit(10000))
            {
                _serverProcess.Kill();
                _memoryCheckTimer.Stop();
                _logger.Log("Server terminato forzatamente", LogEntry.LogLevel.Warning);
            }
            else
            {
                _logger.Log("Server arrestato correttamente", LogEntry.LogLevel.Info);
            }
        });
    }
}