namespace MCSM.Core.Services;

using MCSM.Core.Models;
using MCSM.Core.Utils;
using System.Text.Json;
using System;

public class ConfigManager
{
    private readonly string _configPath;
    private readonly FileHelper _fileHelper;
    private readonly Logger _logger;
    private readonly SemaphoreSlim _saveLock = new SemaphoreSlim(1, 1);

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
        await _saveLock.WaitAsync();
        try
        {
            var path = Path.Combine(_configPath, "server-config.json");
            var json = JsonSerializer.Serialize(config, new JsonSerializerOptions { WriteIndented = true });
            await _fileHelper.WriteAllTextSafeAsync(path, json);
            _logger.Log($"Server configuration saved to: {path}", LogEntry.LogLevel.Info);
        }
        finally
        {
            _saveLock.Release();
        }
    }

    public async Task<ServerConfig> LoadServerConfigAsync()
    {
        var path = Path.Combine(_configPath, "server-config.json");
        if (!File.Exists(path))
            return new ServerConfig();

        try
        {
            var json = await _fileHelper.ReadAllTextSafeAsync(path);
            return JsonSerializer.Deserialize<ServerConfig>(json) ?? new ServerConfig();
        }
        catch (Exception ex)
        {
            _logger.Log($"Error loading server config: {ex.Message}", LogEntry.LogLevel.Error);
            return new ServerConfig();
        }
    }
}