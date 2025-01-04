using MCSM.Core.Models;

namespace MCSM.Desktop.Controls;

public class ConsoleControl : UserControl
{
    private RichTextBox _consoleBox;
    private readonly Queue<LogEntry> _logEntries;
    private const int MaxLogEntries = 1000;

    public ConsoleControl()
    {
        _logEntries = new Queue<LogEntry>();
        InitializeComponent();
        SetupControl();
    }

    private void InitializeComponent()
    {
        _consoleBox = new RichTextBox
        {
            Dock = DockStyle.Fill,
            ReadOnly = true,
            BackColor = Color.Black,
            ForeColor = Color.LightGray,
            Font = new Font("Consolas", 10F, FontStyle.Regular),
            Multiline = true,
            ScrollBars = RichTextBoxScrollBars.Vertical
        };

        Controls.Add(_consoleBox);
    }

    private void SetupControl()
    {
        this.Dock = DockStyle.Fill;
        this.MinimumSize = new Size(200, 100);
    }

    public void AppendLog(LogEntry logEntry)
    {
        if (InvokeRequired)
        {
            Invoke(new Action(() => AppendLog(logEntry)));
            return;
        }

        _logEntries.Enqueue(logEntry);
        while (_logEntries.Count > MaxLogEntries)
        {
            _logEntries.Dequeue();
        }

        var color = GetColorForLogLevel(logEntry.Level);
        var timestamp = logEntry.Timestamp.ToString("HH:mm:ss");
        var logText = $"[{timestamp}] {logEntry.Message}\n";

        _consoleBox.SelectionStart = _consoleBox.TextLength;
        _consoleBox.SelectionLength = 0;
        _consoleBox.SelectionColor = color;
        _consoleBox.AppendText(logText);
        _consoleBox.ScrollToCaret();
    }

    private Color GetColorForLogLevel(LogEntry.LogLevel level)
    {
        return level switch
        {
            LogEntry.LogLevel.Info => Color.LightGray,
            LogEntry.LogLevel.Warning => Color.Yellow,
            LogEntry.LogLevel.Error => Color.Red,
            LogEntry.LogLevel.Debug => Color.LightGreen,
            _ => Color.White
        };
    }

    public void Clear()
    {
        if (InvokeRequired)
        {
            Invoke(new Action(Clear));
            return;
        }

        _consoleBox.Clear();
        _logEntries.Clear();
    }
}