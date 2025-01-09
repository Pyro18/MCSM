namespace MCSM.Core.Models;

public class ServerConfig
{
    // Server Settings
    public string ServerVersion { get; set; }
    public int MemoryMin { get; set; } = 1024;
    public int MemoryMax { get; set; } = 2048;
    public string JavaPath { get; set; }
    public int Port { get; set; } = 25565;
    public bool EnableQuery { get; set; } = true;
    public string ServerIP { get; set; } = "0.0.0.0";
    public string WorldName { get; set; } = "world";
    public int MaxPlayers { get; set; } = 20;
    public string Difficulty { get; set; } = "normal";
    public bool EnableCommandBlock { get; set; }
    public string Motd { get; set; } = "A Minecraft Server";
    public bool OnlineMode { get; set; } = true;
    public string ServerPath { get; set; }
    public List<string> EnabledPlugins { get; set; } = new();

    // Application Settings
    public bool AutoStartServer { get; set; }
    public bool CheckUpdatesOnStartup { get; set; } = true;
    public bool MinimizeToTray { get; set; } = true;
    public int BackupIntervalHours { get; set; } = 24;
    public string BackupFolderPath { get; set; } = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "MCSM",
        "backups"
    );
    public bool EnableLogging { get; set; } = true;
    public LogEntry.LogLevel MinimumLogLevel { get; set; } = LogEntry.LogLevel.Info;
    public bool DeleteOldBackups { get; set; } = true;
    public int KeepBackupsForDays { get; set; } = 7;
}