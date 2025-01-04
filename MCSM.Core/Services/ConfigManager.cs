namespace MCSM.Core.Services;

using MCSM.Core.Models;
using MCSM.Core.Utils;
using System.Text.Json;

public class ConfigManager
{
    private readonly string _configPath;
    private readonly FileHelper _fileHelper;
    private readonly Logger _logger;

    public ConfigManager()
    {
        _configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "config");
        _fileHelper = new FileHelper();
        _logger = new Logger();
        
        if (!Directory.Exists(_configPath))
            Directory.CreateDirectory(_configPath);
    }

    public async Task SaveServerConfigAsync(ServerConfig config)
    {
        var path = Path.Combine(_configPath, "server-config.json");
        var json = JsonSerializer.Serialize(config, new JsonSerializerOptions { WriteIndented = true });
        await File.WriteAllTextAsync(path, json);
        _logger.Log($"Configurazione server salvata in: {path}", LogEntry.LogLevel.Info);
    }

    public async Task<ServerConfig> LoadServerConfigAsync()
    {
        var path = Path.Combine(_configPath, "server-config.json");
        if (!File.Exists(path))
            return new ServerConfig();

        var json = await File.ReadAllTextAsync(path);
        return JsonSerializer.Deserialize<ServerConfig>(json);
    }
}