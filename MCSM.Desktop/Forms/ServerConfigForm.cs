using MCSM.Core.Models;
using MCSM.Core.Services;
using MCSM.Core.Utils;


namespace MCSM.Desktop.Forms;

public partial class ServerConfigForm : Form
{
    private readonly ConfigManager _configManager;
    private readonly UpdateManager _updateManager;
    private ServerConfig _currentConfig;
    private bool _isDownloading = false;
    private readonly Logger _logger;

    private TableLayoutPanel _mainLayout;
    private ComboBox _serverTypeBox;
    private ComboBox _serverVersionBox;
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

    public ServerConfigForm(ConfigManager configManager, ServerConfig currentConfig)
    {
        if (configManager == null)
            throw new ArgumentNullException(nameof(configManager));
            
        _configManager = configManager;
        _currentConfig = currentConfig ?? new ServerConfig();
        _updateManager = new UpdateManager();
        _logger = new Logger();

        CreateControls();
        InitializeComponent();
        LoadConfig();
        _ = LoadVersionsAsync();
    }

    private void CreateControls()
    {
        _mainLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(10),
            RowCount = 15,
            ColumnCount = 3
        };

        _serverTypeBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList,
            Width = 300
        };
        _serverTypeBox.Items.AddRange(new[] { "PaperMC", "Vanilla" });
        _serverTypeBox.SelectedIndex = 0;
        _serverTypeBox.SelectedIndexChanged += ServerType_Changed;

        _serverVersionBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList,
            Width = 300
        };

        _serverPathBox = new TextBox { Width = 250 };
        _downloadButton = new Button { Text = "Download", Width = 80 };
        _downloadButton.Click += DownloadServer_Click;

        _javaPathBox = new TextBox { Width = 300 };

        _memoryMinBox = new NumericUpDown
        {
            Minimum = 512,
            Maximum = 32768,
            Value = 1024,
            Increment = 512
        };

        _memoryMaxBox = new NumericUpDown
        {
            Minimum = 512,
            Maximum = 32768,
            Value = 2048,
            Increment = 512
        };

        _portBox = new NumericUpDown
        {
            Minimum = 1025,
            Maximum = 65535,
            Value = 25565
        };

        _serverIpBox = new TextBox { Text = "0.0.0.0" };
        _worldNameBox = new TextBox { Text = "world" };

        _maxPlayersBox = new NumericUpDown
        {
            Minimum = 1,
            Maximum = 100,
            Value = 20
        };

        _difficultyBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        _difficultyBox.Items.AddRange(new[] { "peaceful", "easy", "normal", "hard" });
        _difficultyBox.SelectedIndex = 2;

        _commandBlockBox = new CheckBox { Text = "Enable Command Blocks" };
        _motdBox = new TextBox { Text = "A Minecraft Server" };
        _onlineModeBox = new CheckBox { Text = "Online Mode (Premium)" };
        _onlineModeBox.Checked = true;

        _saveButton = new Button
        {
            Text = "Save",
            DialogResult = DialogResult.OK,
            Width = 80
        };
        _saveButton.Click += SaveButton_Click;
    }
    
    private void InitializeComponent()
    {
        this.Size = new Size(600, 550);
        this.Text = "Server Configuration";
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.MinimizeBox = false;
        this.StartPosition = FormStartPosition.CenterParent;

        int currentRow = 0;

        // Server Type Selection
        _mainLayout.Controls.Add(new Label { Text = "Server Type:" }, 0, currentRow);
        _mainLayout.Controls.Add(_serverTypeBox, 1, currentRow++);

        // Version Selection
        _mainLayout.Controls.Add(new Label { Text = "Version:" }, 0, currentRow);
        _mainLayout.Controls.Add(_serverVersionBox, 1, currentRow++);

        // Server Path
        _mainLayout.Controls.Add(new Label { Text = "Server Path:" }, 0, currentRow);
        var pathPanel = new FlowLayoutPanel 
        { 
            Dock = DockStyle.Fill,
            AutoSize = true
        };
        var browseServerButton = new Button { Text = "Browse", Width = 60 };
        browseServerButton.Click += BrowseServerPath_Click;

        pathPanel.Controls.AddRange(new Control[] { _serverPathBox, browseServerButton, _downloadButton });
        _mainLayout.Controls.Add(pathPanel, 1, currentRow++);
        _mainLayout.SetColumnSpan(pathPanel, 2);

        // Java Path
        _mainLayout.Controls.Add(new Label { Text = "Java Path:" }, 0, currentRow);
        var javaPathPanel = new FlowLayoutPanel 
        { 
            Dock = DockStyle.Fill,
            AutoSize = true
        };
        var browseJavaButton = new Button { Text = "Browse", Width = 80 };
        browseJavaButton.Click += BrowseJavaPath_Click;
        var detectJavaButton = new Button { Text = "Detect", Width = 80 };
        detectJavaButton.Click += DetectJavaPath_Click;
        javaPathPanel.Controls.AddRange(new Control[] { _javaPathBox, browseJavaButton, detectJavaButton });
        _mainLayout.Controls.Add(javaPathPanel, 1, currentRow++);
        _mainLayout.SetColumnSpan(javaPathPanel, 2);

        // Memory Settings
        _mainLayout.Controls.Add(new Label { Text = "Min Memory (MB):" }, 0, currentRow);
        _mainLayout.Controls.Add(_memoryMinBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "Max Memory (MB):" }, 0, currentRow);
        _mainLayout.Controls.Add(_memoryMaxBox, 1, currentRow++);

        // Network Settings
        _mainLayout.Controls.Add(new Label { Text = "Port:" }, 0, currentRow);
        _mainLayout.Controls.Add(_portBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "Server IP:" }, 0, currentRow);
        _mainLayout.Controls.Add(_serverIpBox, 1, currentRow++);

        // World Settings
        _mainLayout.Controls.Add(new Label { Text = "World Name:" }, 0, currentRow);
        _mainLayout.Controls.Add(_worldNameBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "Max Players:" }, 0, currentRow);
        _mainLayout.Controls.Add(_maxPlayersBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "Difficulty:" }, 0, currentRow);
        _mainLayout.Controls.Add(_difficultyBox, 1, currentRow++);

        // Game Settings
        _mainLayout.Controls.Add(_commandBlockBox, 1, currentRow++);

        _mainLayout.Controls.Add(new Label { Text = "MOTD:" }, 0, currentRow);
        _mainLayout.Controls.Add(_motdBox, 1, currentRow++);

        _mainLayout.Controls.Add(_onlineModeBox, 1, currentRow++);

        // Buttons
        var buttonPanel = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.RightToLeft,
            Dock = DockStyle.Bottom,
            Height = 40,
            Padding = new Padding(5)
        };

        var cancelButton = new Button
        {
            Text = "Cancel",
            DialogResult = DialogResult.Cancel,
            Width = 80
        };

        buttonPanel.Controls.AddRange(new Control[] { cancelButton, _saveButton });

        // Add final layouts
        this.Controls.AddRange(new Control[] { _mainLayout, buttonPanel });

        // Set column styles
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
    }
    
    private void BrowseServerPath_Click(object sender, EventArgs e)
    {
        using var dialog = new FolderBrowserDialog
        {
            Description = "Select Server Installation Directory",
            UseDescriptionForTitle = true,
            InitialDirectory = _serverPathBox.Text
        };

        if (dialog.ShowDialog() == DialogResult.OK)
        {
            _serverPathBox.Text = dialog.SelectedPath;
        }
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
            
            using var loadingForm = new LoadingForm("Testing connection...");
            if (this.IsHandleCreated && !this.IsDisposed)
            {
                loadingForm.Show(this);
            }
            
            loadingForm.Text = "Loading versions...";
            
            var versions = await Task.Run(async () => 
                await _updateManager.GetAvailableVersions(isPaperMC));
            
            loadingForm.Close();
            
            _serverVersionBox.Items.Clear();
            
            if (versions == null || versions.Count == 0)
            {
                throw new Exception("No versions available");
            }

            foreach (var version in versions)
            {
                if (!string.IsNullOrEmpty(version))
                {
                    _serverVersionBox.Items.Add(version);
                }
            }

            // Select current version if exists, otherwise select latest
            if (_currentConfig != null && !string.IsNullOrEmpty(_currentConfig.ServerVersion) && 
                _serverVersionBox.Items.Contains(_currentConfig.ServerVersion))
            {
                _serverVersionBox.SelectedItem = _currentConfig.ServerVersion;
            }
            else if (_serverVersionBox.Items.Count > 0)
            {
                _serverVersionBox.SelectedIndex = 0;
            }

            _logger.Log("Versions loaded successfully", LogEntry.LogLevel.Info);
        }
        catch (HttpRequestException ex)
        {
            _logger.Log($"Network error: {ex.Message}", LogEntry.LogLevel.Error);
            ShowErrorWithRetry(
                "Network Error",
                $"Failed to retrieve versions. Please check your internet connection.\nError: {ex.Message}",
                ex);
        }
        catch (Exception ex)
        {
            _logger.Log($"Error loading versions: {ex.Message}", LogEntry.LogLevel.Error);
            ShowErrorWithRetry(
                "Error",
                $"An unexpected error occurred while loading versions.\nError: {ex.Message}",
                ex);
        }
        finally
        {
            _serverVersionBox.Enabled = true;
            _downloadButton.Enabled = true;
            
            // Se non ci sono versioni dopo il tentativo di caricamento, aggiungi un messaggio di errore
            if (_serverVersionBox.Items.Count == 0)
            {
                _serverVersionBox.Items.Add("No versions available");
                _serverVersionBox.SelectedIndex = 0;
                _downloadButton.Enabled = false;
            }
        }
    }
    
    private void ShowErrorWithRetry(string title, string message, Exception ex)
    {
        _logger.Log($"{message} Details: {ex}", LogEntry.LogLevel.Error);

        if (this.IsHandleCreated && !this.IsDisposed)
        {
            var result = MessageBox.Show(
                $"{message}\n\nWould you like to retry?",
                title,
                MessageBoxButtons.RetryCancel,
                MessageBoxIcon.Error);
        
            if (result == DialogResult.Retry)
            {
                _ = LoadVersionsAsync();
            }
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
            "server"
        );
        
        Directory.CreateDirectory(defaultPath);

        return defaultPath;
    }


    private void LoadConfig()
    {
        if (_currentConfig == null) return;

        var serverDir = _currentConfig.ServerPath;
        if (!string.IsNullOrEmpty(serverDir))
        {
            try
            {
                if (Path.GetExtension(serverDir).Equals(".jar", StringComparison.OrdinalIgnoreCase))
                {
                    _serverPathBox.Text = serverDir;
                }
                else 
                {
                    if (Directory.Exists(serverDir))
                    {
                        var jarFiles = Directory.GetFiles(serverDir, "*.jar")
                            .Where(f => f.Contains("paper") || f.Contains("minecraft_server"));
                        
                        var serverJar = jarFiles.OrderByDescending(f => File.GetLastWriteTime(f))
                            .FirstOrDefault();
                        
                        _serverPathBox.Text = serverJar ?? serverDir;
                    }
                    else
                    {
                        _serverPathBox.Text = serverDir;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.Log($"Error loading server path: {ex.Message}", LogEntry.LogLevel.Error);
                _serverPathBox.Text = serverDir;
            }
        }
        else
        {
            _serverPathBox.Text = GetDefaultServerPath();
        }
        
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
            var serverPath = _serverPathBox.Text;
            var serverDirectory = serverPath;
            
            if (Path.GetExtension(serverPath).Equals(".jar", StringComparison.OrdinalIgnoreCase))
            {
                serverDirectory = Path.GetDirectoryName(serverPath);
            }
            
            var jarPath = Directory.GetFiles(serverDirectory, "*.jar")
                .FirstOrDefault(f => f.Contains("paper") || f.Contains("minecraft_server"));
                                 
            if (string.IsNullOrEmpty(jarPath))
            {
                MessageBox.Show("The selected directory does not contain a valid server JAR file", 
                    "Error", 
                    MessageBoxButtons.OK, 
                    MessageBoxIcon.Error);
                return;
            }

            _currentConfig.ServerPath = jarPath;

            //-- Save the configuration --//
            _saveButton.Enabled = false;
            _currentConfig.ServerVersion = _serverVersionBox.SelectedItem?.ToString();
            _currentConfig.ServerPath = serverPath; // Salviamo il path della directory
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
        
            // Create a temporary ServerInfo for the download
            var serverInfo = new ServerInfo
            {
                Name = Path.GetFileName(Path.GetDirectoryName(_currentConfig.ServerPath)),
                Version = selectedVersion,
                IsPaperMC = _serverTypeBox.SelectedItem?.ToString() == "PaperMC",
                Config = _currentConfig
            };

            var jarPath = await _updateManager.DownloadServerJar(serverInfo);
            _serverPathBox.Text = jarPath;
        
            MessageBox.Show("Server downloaded successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error downloading server: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            _logger.Log($"Error downloading server: {ex.Message}", LogEntry.LogLevel.Error);
        }
        finally
        {
            _isDownloading = false;
            _downloadButton.Enabled = true;
            _downloadButton.Text = "Download";
        }
    }
}