using MCSM.Core.Models;
using MCSM.Core.Utils;

namespace MCSM.Core.Services;

public class PathManager
{
    private readonly Logger _logger;
    
    public string BaseDirectory { get; }
    public string ServersDirectory { get; }
    public string BackupsDirectory { get; }
    public string ConfigDirectory { get; }
    public string LogsDirectory { get; }
    
    public PathManager()
    {
        _logger = new Logger();
        
        // Set up base directory in AppData
        BaseDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "MCSM"
        );
        
        // Define subdirectories
        ServersDirectory = Path.Combine(BaseDirectory, "servers");
        BackupsDirectory = Path.Combine(BaseDirectory, "backups");
        ConfigDirectory = Path.Combine(BaseDirectory, "config");
        LogsDirectory = Path.Combine(BaseDirectory, "logs");
        
        // Create all directories
        CreateDirectories();
    }
    
    private void CreateDirectories()
    {
        var directories = new[]
        {
            BaseDirectory,
            ServersDirectory,
            BackupsDirectory,
            ConfigDirectory,
            LogsDirectory
        };
        
        foreach (var dir in directories)
        {
            if (!Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
                _logger.Log($"Created directory: {dir}", LogEntry.LogLevel.Info);
            }
        }
    }
    
    public string GetServerDirectory(string serverName)
    {
        // Replace invalid characters in server name
        var safeName = string.Join("_", serverName.Split(Path.GetInvalidFileNameChars()));
        var serverDir = Path.Combine(ServersDirectory, safeName);
        
        if (!Directory.Exists(serverDir))
        {
            Directory.CreateDirectory(serverDir);
            _logger.Log($"Created server directory: {serverDir}", LogEntry.LogLevel.Info);
        }
        
        return serverDir;
    }
    
    public string GetServerJarPath(string serverName, string version, bool isPaperMC, int? buildNumber = null)
    {
        var serverDir = GetServerDirectory(serverName);
        string fileName;
        
        if (isPaperMC && buildNumber.HasValue)
        {
            fileName = $"paper-{version}-{buildNumber}.jar";
        }
        else if (isPaperMC)
        {
            fileName = $"paper-{version}.jar";
        }
        else
        {
            fileName = $"minecraft_server.{version}.jar";
        }
        
        return Path.Combine(serverDir, fileName);
    }
    
    public string GetConfigFilePath(string fileName)
    {
        return Path.Combine(ConfigDirectory, fileName);
    }
    
    public string GetBackupPath(string serverName)
    {
        var safeName = string.Join("_", serverName.Split(Path.GetInvalidFileNameChars()));
        var backupDir = Path.Combine(BackupsDirectory, safeName);
        
        if (!Directory.Exists(backupDir))
        {
            Directory.CreateDirectory(backupDir);
        }
        
        return backupDir;
    }
    
    public bool IsValidServerDirectory(string path)
    {
        if (string.IsNullOrEmpty(path) || !Directory.Exists(path))
            return false;
            
        // Check if directory contains a server jar file
        return Directory.GetFiles(path, "*.jar")
                       .Any(f => f.Contains("paper") || f.Contains("minecraft_server"));
    }
    
    public string FindServerJar(string serverDir)
    {
        if (!Directory.Exists(serverDir))
            return null;
            
        var jarFiles = Directory.GetFiles(serverDir, "*.jar");
        return jarFiles.FirstOrDefault(f => f.Contains("paper") || f.Contains("minecraft_server"));
    }
    
    public bool IsServerInstalled(string serverName)
    {
        var serverDir = GetServerDirectory(serverName);
        return Directory.Exists(serverDir) && Directory.GetFiles(serverDir, "*.jar").Any();
    }
    
    public int? GetBuildNumberFromJar(string jarPath)
    {
        try
        {
            var fileName = Path.GetFileNameWithoutExtension(jarPath);
            var parts = fileName.Split('-');
            if (parts.Length >= 3 && int.TryParse(parts[^1], out int buildNumber))
            {
                return buildNumber;
            }
        }
        catch
        {
            // ignore parsing errors
        }
        return null;
    }
}