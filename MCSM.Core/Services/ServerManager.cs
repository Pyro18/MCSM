using MCSM.Core.Utils;

namespace MCSM.Core.Services;

using MCSM.Core.Models;
using System.Diagnostics;

public class ServerManager
{
    private Process _serverProcess;
    private readonly Logger _logger;
    private readonly ConfigManager _configManager;
    private ServerConfig _currentConfig;

    public bool IsServerRunning => _serverProcess != null && !_serverProcess.HasExited;

    public ServerManager()
    {
        _logger = new Logger();
        _configManager = new ConfigManager();
    }

    public async Task StartServer(ServerConfig config)
    {
        if (IsServerRunning)
            throw new InvalidOperationException("Il server è già in esecuzione!");

        _currentConfig = config;
        var startInfo = new ProcessStartInfo
        {
            FileName = config.JavaPath ?? "java",
            Arguments = $"-Xmx{config.MemoryMax}M -Xms{config.MemoryMin}M -jar \"{config.ServerPath}\" nogui",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            RedirectStandardInput = true,
            CreateNoWindow = true
        };

        _serverProcess = new Process { StartInfo = startInfo };
        _serverProcess.OutputDataReceived += (s, e) => 
        {
            if (!string.IsNullOrEmpty(e.Data))
                _logger.Log(e.Data, LogEntry.LogLevel.Info);
        };

        _serverProcess.ErrorDataReceived += (s, e) =>
        {
            if (!string.IsNullOrEmpty(e.Data))
                _logger.Log(e.Data, LogEntry.LogLevel.Error);
        };

        await Task.Run(() =>
        {
            _serverProcess.Start();
            _serverProcess.BeginOutputReadLine();
            _serverProcess.BeginErrorReadLine();
        });
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
                _logger.Log("Server terminato forzatamente", LogEntry.LogLevel.Warning);
            }
            else
            {
                _logger.Log("Server arrestato correttamente", LogEntry.LogLevel.Info);
            }
        });
    }
}