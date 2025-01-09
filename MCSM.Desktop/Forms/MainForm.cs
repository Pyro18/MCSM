using MCSM.Core.Services;
using MCSM.Core.Models;
using MCSM.Desktop.Controls;
using MCSM.Core.Utils;

namespace MCSM.Desktop.Forms;

public partial class MainForm : Form
{
    private readonly ServerManager _serverManager;
    private readonly ConfigManager _configManager;
    private readonly Logger _logger;
    private ServerConfig _currentConfig;
    private DateTime _serverStartTime;
    private ServerStatusControl _statusControl;
    private ConsoleControl _consoleControl;
    
    public MainForm()
    {
        InitializeComponent();
        
        _serverManager = new ServerManager();
        _configManager = new ConfigManager();
        _logger = new Logger();
        _currentConfig = new ServerConfig();
        
        InitializeCustomComponents();
        SetupEventHandlers();
    }
    
    private void InitializeCustomComponents()
    {
        this.Text = "MCSM - Minecraft Server Manager";
        if (File.Exists(Path.Combine(Application.StartupPath, "assets", "icon.ico")))
        {
            this.Icon = new Icon(Path.Combine(Application.StartupPath, "assets", "icon.ico"));
        }
        
        TableLayoutPanel mainLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 2,
            RowCount = 2,
            Padding = new Padding(10)
        };

        _statusControl = new ServerStatusControl
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };
        mainLayout.Controls.Add(_statusControl, 1, 0);

        _consoleControl = new ConsoleControl
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };
        mainLayout.SetColumnSpan(_consoleControl, 2);
        mainLayout.Controls.Add(_consoleControl, 0, 1);

        var controlPanel = new Panel
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };

        var startButton = new Button
        {
            Text = "Start Server",
            Dock = DockStyle.Top,
            Height = 40,
            Margin = new Padding(5)
        };
        startButton.Click += StartServer_Click;

        var stopButton = new Button
        {
            Text = "Stop Server",
            Dock = DockStyle.Top,
            Height = 40,
            Margin = new Padding(5)
        };
        stopButton.Click += StopServer_Click;

        var configButton = new Button
        {
            Text = "Configuration",
            Dock = DockStyle.Top,
            Height = 40,
            Margin = new Padding(5)
        };
        configButton.Click += ConfigButton_Click;

        controlPanel.Controls.Add(configButton);
        controlPanel.Controls.Add(stopButton);
        controlPanel.Controls.Add(startButton);
        mainLayout.Controls.Add(controlPanel, 0, 0);

        mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 30F));
        mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 70F));
        mainLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 30F));
        mainLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 70F));

        this.Controls.Add(mainLayout);
    }

    private async void StartServer_Click(object sender, EventArgs e)
    {
        try
        {
            if (_serverManager.IsServerRunning)
            {
                MessageBox.Show("Server is already running!", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (string.IsNullOrEmpty(_currentConfig.ServerPath) || !File.Exists(_currentConfig.ServerPath))
            {
                MessageBox.Show("Please configure the server path first!", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            _serverStartTime = DateTime.Now;
            await _serverManager.StartServer(_currentConfig);
            
            // Start updating the status
            StartStatusUpdates();
            
            _logger.Log("Server started successfully", LogEntry.LogLevel.Info);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error starting server: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            _logger.Log($"Error starting server: {ex.Message}", LogEntry.LogLevel.Error);
        }
    }

    private async void StopServer_Click(object sender, EventArgs e)
    {
        try
        {
            if (!_serverManager.IsServerRunning)
            {
                MessageBox.Show("Server is not running!", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            await _serverManager.StopServer();
            _logger.Log("Server stopped successfully", LogEntry.LogLevel.Info);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error stopping server: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            _logger.Log($"Error stopping server: {ex.Message}", LogEntry.LogLevel.Error);
        }
    }

    private void ConfigButton_Click(object sender, EventArgs e)
    {
        using var configForm = new ServerConfigForm(_configManager, _currentConfig);
        if (configForm.ShowDialog() == DialogResult.OK)
        {
            SaveServerConfigurations();
        }
    }

    private void SetupEventHandlers()
    {
        this.Load += MainForm_Load;
        this.FormClosing += MainForm_FormClosing;
        
        _logger.OnLogAdded += (sender, entry) =>
        {
            if (_consoleControl != null && !IsDisposed)
            {
                _consoleControl.AppendLog(entry);
            }
        };
    }

    private void StartStatusUpdates()
    {
        var timer = new System.Windows.Forms.Timer
        {
            Interval = 1000 // Update every second
        };

        timer.Tick += (sender, e) =>
        {
            if (!_serverManager.IsServerRunning)
            {
                timer.Stop();
                _statusControl.UpdateStatus(false);
                return;
            }

            var uptime = DateTime.Now - _serverStartTime;
            // TODO: Get actual player count and memory usage
            _statusControl.UpdateStatus(
                isOnline: true,
                uptime: uptime,
                players: 0,
                maxPlayers: _currentConfig.MaxPlayers,
                memoryUsage: 0
            );
        };

        timer.Start();
    }

    private async void MainForm_Load(object sender, EventArgs e)
    {
        await LoadServerConfigurations();
    }

    private void MainForm_FormClosing(object sender, FormClosingEventArgs e)
    {
        SaveServerConfigurations();
        StopServerIfRunning();
    }

    private async Task LoadServerConfigurations()
    {
        try
        {
            _currentConfig = await _configManager.LoadServerConfigAsync();
            _logger.Log("Server configurations loaded successfully", LogEntry.LogLevel.Info);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error loading configurations: {ex.Message}",
                          "Error",
                          MessageBoxButtons.OK,
                          MessageBoxIcon.Error);
            _logger.Log($"Error loading configurations: {ex.Message}", LogEntry.LogLevel.Error);
        }
    }

    private void SaveServerConfigurations()
    {
        try
        {
            _configManager.SaveServerConfigAsync(_currentConfig).Wait();
            _logger.Log("Server configurations saved successfully", LogEntry.LogLevel.Info);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error saving configurations: {ex.Message}",
                          "Error",
                          MessageBoxButtons.OK,
                          MessageBoxIcon.Error);
            _logger.Log($"Error saving configurations: {ex.Message}", LogEntry.LogLevel.Error);
        }
    }

    private void StopServerIfRunning()
    {
        try
        {
            if (_serverManager.IsServerRunning)
            {
                _serverManager.StopServer().Wait();
                _logger.Log("Server stopped during application shutdown", LogEntry.LogLevel.Info);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error stopping server: {ex.Message}",
                          "Error",
                          MessageBoxButtons.OK,
                          MessageBoxIcon.Warning);
            _logger.Log($"Error stopping server during shutdown: {ex.Message}", LogEntry.LogLevel.Error);
        }
    }
}