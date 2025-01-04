using MCSM.Core.Models;
using MCSM.Core.Utils;

namespace MCSM.Core.Services;

public class UpdateManager
{
    private readonly Logger _logger;
    private readonly string _versionsPath;

    public UpdateManager()
    {
        _logger = new Logger();
        _versionsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "versions");
        
        if (!Directory.Exists(_versionsPath))
            Directory.CreateDirectory(_versionsPath);
    }

    public async Task<List<string>> GetAvailableVersions()
    {
        // TODO: Implementare la logica per ottenere le versioni disponibili da Mojang API
        return new List<string> { "1.20.4", "1.20.2", "1.19.4" };
    }

    public async Task<string> DownloadServerJar(string version)
    {
        var jarPath = Path.Combine(_versionsPath, $"minecraft_server.{version}.jar");
        
        if (File.Exists(jarPath))
        {
            _logger.Log($"Versione {version} già scaricata", LogEntry.LogLevel.Info);
            return jarPath;
        }

        // TODO: Implement the logic to download the server jar from Mojang servers or other sources like PaperMC
        _logger.Log($"Download versione {version} completato", LogEntry.LogLevel.Info);
        return jarPath;
    }
}