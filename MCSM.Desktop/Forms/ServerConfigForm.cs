using MCSM.Core.Models;
using MCSM.Core.Services;
using MCSM.Core.Utils;


namespace MCSM.Desktop.Forms;

public partial class ServerConfigForm : Form
{
    private readonly ConfigManager _configManager;
    private readonly UpdateManager _updateManager;
    private ServerConfig _currentConfig;
    private TableLayoutPanel _mainLayout;
    private ComboBox _serverVersionBox;
    private ComboBox _serverTypeBox;
    private TextBox _serverPathBox;
    private Button _downloadButton;
    private Button _saveButton;
    private NumericUpDown _memoryMinBox;
    private NumericUpDown _memoryMaxBox;
    private TextBox _javaPathBox;
    private NumericUpDown _portBox;
    private TextBox _serverIpBox;
    private TextBox _worldNameBox;
    private NumericUpDown _maxPlayersBox;
    private ComboBox _difficultyBox;
    private CheckBox _commandBlockBox;
    private TextBox _motdBox;
    private CheckBox _onlineModeBox;
    private bool _isDownloading = false;
    private Logger _logger = new Logger();

    public ServerConfigForm(ConfigManager configManager, ServerConfig currentConfig)
    {
        _configManager = configManager;
        _updateManager = new UpdateManager();
        _currentConfig = currentConfig;
        InitializeComponent();
        LoadVersionsAsync();
        LoadConfig();
    }

    private void InitializeComponent()
    {
        this.Size = new Size(600, 550);
        this.Text = "Server Configuration";
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.MinimizeBox = false;
        this.StartPosition = FormStartPosition.CenterParent;

        _mainLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(10),
            RowCount = 15,
            ColumnCount = 3
        };

        int currentRow = 0;

        // Server Type Selection
        _mainLayout.Controls.Add(new Label { Text = "Server Type:" }, 0, currentRow);
        _serverTypeBox = new ComboBox 
        { 
            DropDownStyle = ComboBoxStyle.DropDownList,
            Width = 300
        };
        _serverTypeBox.Items.AddRange(new[] { "PaperMC", "Vanilla" });
        _serverTypeBox.SelectedIndex = 0;
        _serverTypeBox.SelectedIndexChanged += ServerType_Changed;
        _mainLayout.Controls.Add(_serverTypeBox, 1, currentRow++);

        // Version Selection
        _mainLayout.Controls.Add(new Label { Text = "Version:" }, 0, currentRow);
        _serverVersionBox = new ComboBox 
        { 
            DropDownStyle = ComboBoxStyle.DropDownList,
            Width = 300
        };
        _mainLayout.Controls.Add(_serverVersionBox, 1, currentRow++);

        // Server Path with Download button
        _mainLayout.Controls.Add(new Label { Text = "Server Path:" }, 0, currentRow);
        var pathPanel = new FlowLayoutPanel 
        { 
            Dock = DockStyle.Fill,
            AutoSize = true
        };
        _serverPathBox = new TextBox { Width = 300 };
        _downloadButton = new Button { Text = "Download", Width = 80 };
        _downloadButton.Click += DownloadServer_Click;
        pathPanel.Controls.AddRange(new Control[] { _serverPathBox, _downloadButton });
        _mainLayout.Controls.Add(pathPanel, 1, currentRow++);
        _mainLayout.SetColumnSpan(pathPanel, 2);

        // Java Path with Browse button
        _mainLayout.Controls.Add(new Label { Text = "Java Path:" }, 0, currentRow);
        var javaPathPanel = new FlowLayoutPanel 
        { 
            Dock = DockStyle.Fill,
            AutoSize = true
        };
        _javaPathBox = new TextBox { Width = 300 };
        var browseJavaButton = new Button { Text = "Browse", Width = 80 };
        browseJavaButton.Click += BrowseJavaPath_Click;
        var detectJavaButton = new Button { Text = "Detect", Width = 80 };
        detectJavaButton.Click += DetectJavaPath_Click;
        javaPathPanel.Controls.AddRange(new Control[] { _javaPathBox, browseJavaButton, detectJavaButton });
        _mainLayout.Controls.Add(javaPathPanel, 1, currentRow++);
        _mainLayout.SetColumnSpan(javaPathPanel, 2);

        // Memory Settings
        _mainLayout.Controls.Add(new Label { Text = "Min Memory (MB):" }, 0, currentRow);
        _memoryMinBox = new NumericUpDown 
        { 
            Minimum = 512,
            Maximum = 32768,
            Value = 1024,
            Increment = 512
        };
        _mainLayout.Controls.Add(_memoryMinBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "Max Memory (MB):" }, 0, currentRow);
        _memoryMaxBox = new NumericUpDown
        {
            Minimum = 512,
            Maximum = 32768,
            Value = 2048,
            Increment = 512
        };
        _mainLayout.Controls.Add(_memoryMaxBox, 1, currentRow++);

        // Network Settings
        _mainLayout.Controls.Add(new Label { Text = "Port:" }, 0, currentRow);
        _portBox = new NumericUpDown
        {
            Minimum = 1025,
            Maximum = 65535,
            Value = 25565
        };
        _mainLayout.Controls.Add(_portBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "Server IP:" }, 0, currentRow);
        _serverIpBox = new TextBox { Text = "0.0.0.0" };
        _mainLayout.Controls.Add(_serverIpBox, 1, currentRow++);

        // World Settings
        _mainLayout.Controls.Add(new Label { Text = "World Name:" }, 0, currentRow);
        _worldNameBox = new TextBox { Text = "world" };
        _mainLayout.Controls.Add(_worldNameBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "Max Players:" }, 0, currentRow);
        _maxPlayersBox = new NumericUpDown
        {
            Minimum = 1,
            Maximum = 100,
            Value = 20
        };
        _mainLayout.Controls.Add(_maxPlayersBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "Difficulty:" }, 0, currentRow);
        _difficultyBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        _difficultyBox.Items.AddRange(new[] { "peaceful", "easy", "normal", "hard" });
        _difficultyBox.SelectedIndex = 2; // normal
        _mainLayout.Controls.Add(_difficultyBox, 1, currentRow++);

        // Game Settings
        _commandBlockBox = new CheckBox { Text = "Enable Command Blocks" };
        _mainLayout.Controls.Add(_commandBlockBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "MOTD:" }, 0, currentRow);
        _motdBox = new TextBox { Text = "A Minecraft Server" };
        _mainLayout.Controls.Add(_motdBox, 1, currentRow++);

        _onlineModeBox = new CheckBox { Text = "Online Mode (Premium)" };
        _onlineModeBox.Checked = true;
        _mainLayout.Controls.Add(_onlineModeBox, 1, currentRow++);

        // Buttons
        var buttonPanel = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.RightToLeft,
            Dock = DockStyle.Bottom,
            Height = 40,
            Padding = new Padding(5)
        };

        _saveButton = new Button
        {
            Text = "Save",
            DialogResult = DialogResult.OK
        };
        _saveButton.Click += SaveButton_Click;

        var cancelButton = new Button
        {
            Text = "Cancel",
            DialogResult = DialogResult.Cancel
        };

        buttonPanel.Controls.AddRange(new Control[] { _saveButton, cancelButton });

        this.Controls.AddRange(new Control[] { _mainLayout, buttonPanel });

        // Set column styles
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
    }

    private async Task LoadVersionsAsync()
    {
        try
        {
            _serverVersionBox.Items.Clear();
            _serverVersionBox.Items.Add("Loading...");
            _serverVersionBox.SelectedIndex = 0;
            _serverVersionBox.Enabled = false;
            _downloadButton.Enabled = false;

            bool isPaperMC = _serverTypeBox.SelectedItem?.ToString() == "PaperMC";
        
            using var loadingForm = new LoadingForm("Loading versions...");
            loadingForm.Show(this);
        
            var versions = await Task.Run(async () => 
                await _updateManager.GetAvailableVersions(isPaperMC));
        
            loadingForm.Close();
        
            _serverVersionBox.Items.Clear();
        
            if (versions.Count == 0)
            {
                throw new Exception("No versions available");
            }

            _serverVersionBox.Items.AddRange(versions.ToArray());
        
            // Select current version if exists, otherwise select latest
            var currentVersion = versions.FirstOrDefault(v => v == _currentConfig.ServerVersion) ?? versions[0];
            _serverVersionBox.SelectedItem = currentVersion;
        }
        catch (HttpRequestException ex)
        {
            ShowErrorWithRetry(
                "Network Error",
                "Failed to retrieve versions. Please check your internet connection and try again.",
                ex);
        }
        catch (Exception ex)
        {
            ShowErrorWithRetry(
                "Error",
                "An unexpected error occurred while loading versions.",
                ex);
        }
        finally
        {
            _serverVersionBox.Enabled = true;
            _downloadButton.Enabled = true;
        }
    }
    
    private void ShowErrorWithRetry(string title, string message, Exception ex)
    {
        _logger.Log($"{message} Details: {ex}", LogEntry.LogLevel.Error);
    
        var result = MessageBox.Show(
            $"{message}\n\nWould you like to retry?",
            title,
            MessageBoxButtons.RetryCancel,
            MessageBoxIcon.Error);
        
        if (result == DialogResult.Retry)
        {
            LoadVersionsAsync().ConfigureAwait(false);
        }
    } 
    
    private void ServerType_Changed(object sender, EventArgs e)
    {
        _ = LoadVersionsAsync();
    }

    private void BrowseJavaPath_Click(object sender, EventArgs e)
    {
        using var dialog = new OpenFileDialog
        {
            Filter = "Java executable (java.exe)|java.exe|All files (*.*)|*.*",
            FilterIndex = 1,
            Title = "Select Java Executable"
        };

        if (dialog.ShowDialog() == DialogResult.OK)
        {
            _javaPathBox.Text = dialog.FileName;
        }
    }

    private void DetectJavaPath_Click(object sender, EventArgs e)
    {
        var javaHome = Environment.GetEnvironmentVariable("JAVA_HOME");
        if (!string.IsNullOrEmpty(javaHome))
        {
            var javaPath = Path.Combine(javaHome, "bin", "java.exe");
            if (File.Exists(javaPath))
            {
                _javaPathBox.Text = javaPath;
                return;
            }
        }
        
        var programFiles = new[] 
        { 
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86)
        };

        foreach (var programFile in programFiles)
        {
            var javaFolder = Path.Combine(programFile, "Java");
            if (Directory.Exists(javaFolder))
            {
                var javaVersions = Directory.GetDirectories(javaFolder)
                    .Where(d => d.Contains("jdk") || d.Contains("jre"))
                    .OrderByDescending(d => d);

                foreach (var version in javaVersions)
                {
                    var javaPath = Path.Combine(version, "bin", "java.exe");
                    if (File.Exists(javaPath))
                    {
                        _javaPathBox.Text = javaPath;
                        return;
                    }
                }
            }
        }

        MessageBox.Show("Could not detect Java installation. Please install Java or select the path manually.",
                       "Java Not Found",
                       MessageBoxButtons.OK,
                       MessageBoxIcon.Warning);
    }

    private string GetDefaultServerPath()
    {
        var defaultPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "MCSM",
            "servers",
            "default"
        );

        // Ensure the directory exists
        Directory.CreateDirectory(Path.GetDirectoryName(defaultPath)!);

        return defaultPath;
    }

    private void LoadConfig()
    {
        if (_currentConfig == null) return;

        _serverPathBox.Text = _currentConfig.ServerPath ?? GetDefaultServerPath();
        _memoryMinBox.Value = _currentConfig.MemoryMin;
        _memoryMaxBox.Value = _currentConfig.MemoryMax;
        _javaPathBox.Text = _currentConfig.JavaPath ?? "java";
        _portBox.Value = _currentConfig.Port;
        _serverIpBox.Text = _currentConfig.ServerIP;
        _worldNameBox.Text = _currentConfig.WorldName;
        _maxPlayersBox.Value = _currentConfig.MaxPlayers;
        _difficultyBox.SelectedItem = _currentConfig.Difficulty;
        _commandBlockBox.Checked = _currentConfig.EnableCommandBlock;
        _motdBox.Text = _currentConfig.Motd;
        _onlineModeBox.Checked = _currentConfig.OnlineMode;
    }

    private async void SaveButton_Click(object sender, EventArgs e)
    {
        try
        {
            if (string.IsNullOrEmpty(_serverPathBox.Text) || !File.Exists(_serverPathBox.Text))
            {
                MessageBox.Show("Please download or select a valid server JAR file first", 
                    "Error", 
                    MessageBoxButtons.OK, 
                    MessageBoxIcon.Error);
                return;
            }

            _saveButton.Enabled = false;
        
            _currentConfig.ServerVersion = _serverVersionBox.SelectedItem?.ToString();
            _currentConfig.ServerPath = _serverPathBox.Text;
            _currentConfig.MemoryMin = (int)_memoryMinBox.Value;
            _currentConfig.MemoryMax = (int)_memoryMaxBox.Value;
            _currentConfig.JavaPath = _javaPathBox.Text;
            _currentConfig.Port = (int)_portBox.Value;
            _currentConfig.ServerIP = _serverIpBox.Text;
            _currentConfig.WorldName = _worldNameBox.Text;
            _currentConfig.MaxPlayers = (int)_maxPlayersBox.Value;
            _currentConfig.Difficulty = _difficultyBox.SelectedItem.ToString();
            _currentConfig.EnableCommandBlock = _commandBlockBox.Checked;
            _currentConfig.Motd = _motdBox.Text;
            _currentConfig.OnlineMode = _onlineModeBox.Checked;

            await _configManager.SaveServerConfigAsync(_currentConfig);
            DialogResult = DialogResult.OK;
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error saving configuration: {ex.Message}", 
                "Error", 
                MessageBoxButtons.OK, 
                MessageBoxIcon.Error);
        }
        finally
        {
            _saveButton.Enabled = true;
        }
    }

    private async void DownloadServer_Click(object sender, EventArgs e)
    {
        if (_isDownloading)
        {
            MessageBox.Show("Download already in progress", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        try
        {
            _isDownloading = true;
            _downloadButton.Enabled = false;
            _downloadButton.Text = "Downloading...";

            var selectedVersion = _serverVersionBox.SelectedItem?.ToString();
            if (string.IsNullOrEmpty(selectedVersion))
            {
                MessageBox.Show("Please select a version first", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            var serverPath = await _updateManager.DownloadServerJar(selectedVersion);
            _serverPathBox.Text = serverPath;
            MessageBox.Show("Server downloaded successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error downloading server: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally
        {
            _isDownloading = false;
            _downloadButton.Enabled = true;
            _downloadButton.Text = "Download";
        }
    }
}