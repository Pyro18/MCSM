namespace MCSM.Core.Utils;

using MCSM.Core.Models;

public class Logger
{
    private readonly string _logPath;
    private static readonly object _lock = new();

    public event EventHandler<LogEntry> OnLogAdded;

    public Logger()
    {
        _logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs");
        
        if (!Directory.Exists(_logPath))
            Directory.CreateDirectory(_logPath);
    }

    public void Log(string message, LogEntry.LogLevel level = LogEntry.LogLevel.Info)
    {
        var entry = new LogEntry
        {
            Timestamp = DateTime.Now,
            Message = message,
            Level = level,
            Source = "MCSM"
        };

        WriteToFile(entry);
        OnLogAdded?.Invoke(this, entry);
    }

    private void WriteToFile(LogEntry entry)
    {
        var logFile = Path.Combine(_logPath, $"mcsm_{DateTime.Now:yyyy-MM-dd}.log");
        var logMessage = $"[{entry.Timestamp:yyyy-MM-dd HH:mm:ss}] [{entry.Level}] {entry.Message}";

        lock (_lock)
        {
            File.AppendAllLines(logFile, new[] { logMessage });
        }
    }

    public async Task<List<LogEntry>> GetRecentLogs(int count = 100)
    {
        var logFile = Path.Combine(_logPath, $"mcsm_{DateTime.Now:yyyy-MM-dd}.log");
        if (!File.Exists(logFile))
            return new List<LogEntry>();

        var lines = await File.ReadAllLinesAsync(logFile);
        return lines.TakeLast(count)
                   .Select(ParseLogLine)
                   .Where(entry => entry != null)
                   .ToList();
    }

    private LogEntry ParseLogLine(string line)
    {
        try
        {
            // Format: [2024-01-04 12:34:56] [Info] Message
            var parts = line.Split(new[] { "][", "] " }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length < 3) return null;

            return new LogEntry
            {
                Timestamp = DateTime.Parse(parts[0].Trim('[')),
                Level = Enum.Parse<LogEntry.LogLevel>(parts[1].Trim('[', ']')),
                Message = parts[2],
                Source = "MCSM"
            };
        }
        catch
        {
            return null;
        }
    }
}