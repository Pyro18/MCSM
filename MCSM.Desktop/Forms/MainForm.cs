using MCSM.Core.Services;
using MCSM.Core.Models;
using MCSM.Desktop.Controls;
using MCSM.Core.Utils;

namespace MCSM.Desktop.Forms;

public partial class MainForm : Form
{
    private readonly ServerListManager _serverListManager;
    private readonly ConfigManager _configManager;
    private readonly Logger _logger;
    private ServerInfo _currentServer;
    private ServerListControl _serverListControl;
    private ServerStatusControl _statusControl;
    private ConsoleControl _consoleControl;
    private System.Windows.Forms.Timer _statusUpdateTimer;
    private NotifyIcon _trayIcon;
    
    public MainForm()
    {
        InitializeComponent();
        
        _serverListManager = new ServerListManager();
        _configManager = new ConfigManager();
        _logger = new Logger();
        
        InitializeCustomComponents();
        InitializeTrayIcon();
        SetupEventHandlers();
        SetupStatusTimer();
    }
    
    private void InitializeCustomComponents()
    {
        this.Text = "MCSM - Minecraft Server Manager";
        if (File.Exists(Path.Combine(Application.StartupPath, "assets", "icon.ico")))
        {
            this.Icon = new Icon(Path.Combine(Application.StartupPath, "assets", "icon.ico"));
        }
        
        // Main layout
        TableLayoutPanel mainLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 2,
            RowCount = 2,
            Padding = new Padding(10)
        };
        
        // Server list panel (left side)
        var leftPanel = new Panel
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };
        
        var addServerButton = new Button
        {
            Text = "Add Server",
            Dock = DockStyle.Top,
            Height = 30,
            Margin = new Padding(5)
        };
        addServerButton.Click += AddServer_Click;
        
        _serverListControl = new ServerListControl(_serverListManager)
        {
            Dock = DockStyle.Fill
        };
        
        leftPanel.Controls.Add(_serverListControl);
        leftPanel.Controls.Add(addServerButton);
        
        // Status and control panel (top right)
        var rightTopPanel = new Panel
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };
        
        _statusControl = new ServerStatusControl
        {
            Dock = DockStyle.Fill
        };
        
        var buttonPanel = new FlowLayoutPanel
        {
            Dock = DockStyle.Bottom,
            Height = 40,
            FlowDirection = FlowDirection.LeftToRight,
            Padding = new Padding(5)
        };
        
        var startButton = new Button
        {
            Text = "Start Server",
            Width = 100,
            Height = 30
        };
        startButton.Click += async (s, e) => await StartCurrentServer();
        
        var stopButton = new Button
        {
            Text = "Stop Server",
            Width = 100,
            Height = 30
        };
        stopButton.Click += async (s, e) => await StopCurrentServer();
        
        var configButton = new Button
        {
            Text = "Settings",
            Width = 100,
            Height = 30
        };
        configButton.Click += ConfigButton_Click;
        
        buttonPanel.Controls.AddRange(new Control[] { startButton, stopButton, configButton });
        
        rightTopPanel.Controls.Add(_statusControl);
        rightTopPanel.Controls.Add(buttonPanel);
        
        // Console panel (bottom right)
        _consoleControl = new ConsoleControl
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };
        
        // Add all panels to main layout
        mainLayout.Controls.Add(leftPanel, 0, 0);
        mainLayout.SetRowSpan(leftPanel, 2);
        mainLayout.Controls.Add(rightTopPanel, 1, 0);
        mainLayout.Controls.Add(_consoleControl, 1, 1);
        
        // Configure layout
        mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 30F));
        mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 70F));
        mainLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 30F));
        mainLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 70F));
        
        this.Controls.Add(mainLayout);
    }
    
    private void InitializeTrayIcon()
    {
        _trayIcon = new NotifyIcon
        {
            Icon = this.Icon,
            Text = "MCSM - Minecraft Server Manager",
            Visible = false
        };
        
        var trayMenu = new ContextMenuStrip();
        trayMenu.Items.Add("Show", null, (s, e) => 
        {
            this.Show();
            this.WindowState = FormWindowState.Normal;
            _trayIcon.Visible = false;
        });
        
        trayMenu.Items.Add("Exit", null, (s, e) => 
        {
            _trayIcon.Visible = false;
            Application.Exit();
        });
        
        _trayIcon.ContextMenuStrip = trayMenu;
        
        _trayIcon.DoubleClick += (s, e) => 
        {
            this.Show();
            this.WindowState = FormWindowState.Normal;
            _trayIcon.Visible = false;
        };
    }
    
    private void SetupStatusTimer()
    {
        _statusUpdateTimer = new System.Windows.Forms.Timer
        {
            Interval = 1000 // Update every second
        };
        
        _statusUpdateTimer.Tick += (s, e) => UpdateStatusDisplay();
        _statusUpdateTimer.Start();
    }
    
    private void SetupEventHandlers()
    {
        _serverListControl.OnServerSelected += ServerListControl_OnServerSelected;
        
        _logger.OnLogAdded += (sender, entry) =>
        {
            if (_consoleControl != null && !IsDisposed)
            {
                _consoleControl.AppendLog(entry);
            }
        };
        
        this.Resize += MainForm_Resize;
    }
    
    private void MainForm_Resize(object sender, EventArgs e)
    {
        if (WindowState == FormWindowState.Minimized)
        {
            var config = _configManager.LoadServerConfigAsync().Result;
            if (config.MinimizeToTray)
            {
                this.Hide();
                _trayIcon.Visible = true;
            }
        }
    }
    
    private void ServerListControl_OnServerSelected(object sender, ServerInfo server)
    {
        _currentServer = server;
        UpdateStatusDisplay();
        
        // Clear and load server logs
        _consoleControl.Clear();
        LoadServerLogs();
    }
    
    private async void LoadServerLogs()
    {
        if (_currentServer == null) return;
        
        try
        {
            var logs = await _logger.GetRecentLogs();
            foreach (var log in logs)
            {
                _consoleControl.AppendLog(log);
            }
        }
        catch (Exception ex)
        {
            _logger.Log($"Error loading server logs: {ex.Message}", LogEntry.LogLevel.Error);
        }
    }
    
    private void UpdateStatusDisplay()
    {
        if (_currentServer != null && _serverListManager != null)
        {
            var serverManager = _serverListManager.GetServerManager(_currentServer.Id);
            if (serverManager != null)
            {
                var status = serverManager.GetStatus();
                TimeSpan uptime = status.IsRunning ? DateTime.Now - _currentServer.LastStarted : TimeSpan.Zero;
            
                _statusControl.UpdateStatus(
                    isOnline: status.IsRunning,
                    uptime: uptime,
                    players: status.CurrentPlayers,
                    maxPlayers: status.MaxPlayers,
                    memoryUsage: status.MemoryUsage
                );
            }
        }
    }
    
    private async Task StartCurrentServer()
    {
        if (_currentServer == null)
        {
            MessageBox.Show("Please select a server first", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        
        try
        {
            await _serverListManager.StartServer(_currentServer.Id);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error starting server: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
    
    private async Task StopCurrentServer()
    {
        if (_currentServer == null)
        {
            MessageBox.Show("Please select a server first", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        
        try
        {
            await _serverListManager.StopServer(_currentServer.Id);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error stopping server: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
    
    private void AddServer_Click(object sender, EventArgs e)
    {
        using var addServerForm = new AddServerForm(_serverListManager);
        addServerForm.ShowDialog(this);
    }
    
    private void ConfigButton_Click(object sender, EventArgs e)
    {
        if (_currentServer == null)
        {
            MessageBox.Show("Please select a server first", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        
        using var configForm = new ServerConfigForm(_configManager, _currentServer.Config);
        if (configForm.ShowDialog(this) == DialogResult.OK)
        {
            _serverListManager.UpdateServerConfig(_currentServer.Id, _currentServer.Config);
        }
    }
    
    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (e.CloseReason == CloseReason.UserClosing)
        {
            var runningServers = _serverListManager.GetServers()
                .Where(s => s.Status == ServerStatus.Running)
                .ToList();
                
            if (runningServers.Any())
            {
                var result = MessageBox.Show(
                    "There are servers still running. Do you want to stop them before closing?",
                    "Servers Running",
                    MessageBoxButtons.YesNoCancel,
                    MessageBoxIcon.Warning);
                    
                switch (result)
                {
                    case DialogResult.Yes:
                        StopAllServers();
                        break;
                    case DialogResult.Cancel:
                        e.Cancel = true;
                        return;
                }
            }
        }
        
        _statusUpdateTimer?.Stop();
        _statusUpdateTimer?.Dispose();
        _trayIcon?.Dispose();
        
        base.OnFormClosing(e);
    }
    
    
    
    private async void StopAllServers()
    {
        var runningServers = _serverListManager.GetServers()
            .Where(s => s.Status == ServerStatus.Running)
            .ToList();
            
        foreach (var server in runningServers)
        {
            try
            {
                await _serverListManager.StopServer(server.Id);
                _logger.Log($"Server '{server.Name}' stopped during application shutdown", LogEntry.LogLevel.Info);
            }
            catch (Exception ex)
            {
                _logger.Log($"Error stopping server '{server.Name}' during shutdown: {ex.Message}", LogEntry.LogLevel.Error);
            }
        }
    }
}