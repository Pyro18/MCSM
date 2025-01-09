using MCSM.Core.Models;
using MCSM.Core.Services;

namespace MCSM.Desktop.Forms;

public partial class ServerConfigForm : Form
{
    private readonly ConfigManager _configManager;
    private ServerConfig _currentConfig;
    
    private TableLayoutPanel _mainLayout;
    private TextBox _serverPathBox;
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
        _configManager = configManager;
        _currentConfig = currentConfig;
        InitializeComponent();
        LoadConfig();
    }

    private void InitializeComponent()
    {
        this.Size = new Size(600, 500);
        this.Text = "Server Configuration";
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.MinimizeBox = false;
        this.StartPosition = FormStartPosition.CenterParent;

        _mainLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(10),
            RowCount = 13,
            ColumnCount = 3
        };

        // Server Path with Browse button
        _mainLayout.Controls.Add(new Label { Text = "Server Path:" }, 0, 0);
        var pathPanel = new FlowLayoutPanel 
        { 
            Dock = DockStyle.Fill,
            AutoSize = true
        };
        _serverPathBox = new TextBox { Width = 300 };
        var browseButton = new Button { Text = "Browse", Width = 80 };
        browseButton.Click += BrowseServerPath_Click;
        var defaultPathButton = new Button { Text = "Default", Width = 80 };
        defaultPathButton.Click += DefaultServerPath_Click;
        pathPanel.Controls.AddRange(new Control[] { _serverPathBox, browseButton, defaultPathButton });
        _mainLayout.Controls.Add(pathPanel, 1, 0);
        _mainLayout.SetColumnSpan(pathPanel, 2);

        // Java Path with Browse button
        _mainLayout.Controls.Add(new Label { Text = "Java Path:" }, 0, 1);
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
        _mainLayout.Controls.Add(javaPathPanel, 1, 1);
        _mainLayout.SetColumnSpan(javaPathPanel, 2);

        // Memory Settings
        _mainLayout.Controls.Add(new Label { Text = "Min Memory (MB):" }, 0, 2);
        _memoryMinBox = new NumericUpDown 
        { 
            Minimum = 512,
            Maximum = 32768,
            Value = 1024,
            Increment = 512
        };
        _mainLayout.Controls.Add(_memoryMinBox, 1, 2);

        _mainLayout.Controls.Add(new Label { Text = "Max Memory (MB):" }, 0, 3);
        _memoryMaxBox = new NumericUpDown
        {
            Minimum = 512,
            Maximum = 32768,
            Value = 2048,
            Increment = 512
        };
        _mainLayout.Controls.Add(_memoryMaxBox, 1, 3);

        // Network Settings
        _mainLayout.Controls.Add(new Label { Text = "Port:" }, 0, 4);
        _portBox = new NumericUpDown
        {
            Minimum = 1025,
            Maximum = 65535,
            Value = 25565
        };
        _mainLayout.Controls.Add(_portBox, 1, 4);

        _mainLayout.Controls.Add(new Label { Text = "Server IP:" }, 0, 5);
        _serverIpBox = new TextBox { Text = "0.0.0.0" };
        _mainLayout.Controls.Add(_serverIpBox, 1, 5);

        // World Settings
        _mainLayout.Controls.Add(new Label { Text = "World Name:" }, 0, 6);
        _worldNameBox = new TextBox { Text = "world" };
        _mainLayout.Controls.Add(_worldNameBox, 1, 6);

        _mainLayout.Controls.Add(new Label { Text = "Max Players:" }, 0, 7);
        _maxPlayersBox = new NumericUpDown
        {
            Minimum = 1,
            Maximum = 100,
            Value = 20
        };
        _mainLayout.Controls.Add(_maxPlayersBox, 1, 7);

        _mainLayout.Controls.Add(new Label { Text = "Difficulty:" }, 0, 8);
        _difficultyBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        _difficultyBox.Items.AddRange(new[] { "peaceful", "easy", "normal", "hard" });
        _difficultyBox.SelectedIndex = 2; // normal
        _mainLayout.Controls.Add(_difficultyBox, 1, 8);

        // Game Settings
        _commandBlockBox = new CheckBox { Text = "Enable Command Blocks" };
        _mainLayout.Controls.Add(_commandBlockBox, 1, 9);

        _mainLayout.Controls.Add(new Label { Text = "MOTD:" }, 0, 10);
        _motdBox = new TextBox { Text = "A Minecraft Server" };
        _mainLayout.Controls.Add(_motdBox, 1, 10);

        _onlineModeBox = new CheckBox { Text = "Online Mode (Premium)" };
        _onlineModeBox.Checked = true;
        _mainLayout.Controls.Add(_onlineModeBox, 1, 11);

        // Buttons
        var buttonPanel = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.RightToLeft,
            Dock = DockStyle.Bottom,
            Height = 40,
            Padding = new Padding(5)
        };

        var saveButton = new Button
        {
            Text = "Save",
            DialogResult = DialogResult.OK
        };
        saveButton.Click += SaveButton_Click;

        var cancelButton = new Button
        {
            Text = "Cancel",
            DialogResult = DialogResult.Cancel
        };

        buttonPanel.Controls.AddRange(new Control[] { saveButton, cancelButton });

        this.Controls.AddRange(new Control[] { _mainLayout, buttonPanel });

        // Set column styles
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
        _mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
    }

    private void BrowseServerPath_Click(object sender, EventArgs e)
    {
        using var dialog = new OpenFileDialog
        {
            Filter = "JAR files (*.jar)|*.jar|All files (*.*)|*.*",
            FilterIndex = 1,
            Title = "Select Server JAR File"
        };

        // Set initial directory to default if exists
        var defaultPath = GetDefaultServerPath();
        if (Directory.Exists(Path.GetDirectoryName(defaultPath)))
        {
            dialog.InitialDirectory = Path.GetDirectoryName(defaultPath);
        }

        if (dialog.ShowDialog() == DialogResult.OK)
        {
            _serverPathBox.Text = dialog.FileName;
        }
    }

    private void DefaultServerPath_Click(object sender, EventArgs e)
    {
        _serverPathBox.Text = GetDefaultServerPath();
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

        // Try to find Java in Program Files
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
            "default",
            "server.jar"
        );

        // Ensure the directory exists
        Directory.CreateDirectory(Path.GetDirectoryName(defaultPath));

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

    private void SaveButton_Click(object sender, EventArgs e)
    {
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

        try
        {
            _configManager.SaveServerConfigAsync(_currentConfig).Wait();
            DialogResult = DialogResult.OK;
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error saving configuration: {ex.Message}", 
                          "Error", 
                          MessageBoxButtons.OK, 
                          MessageBoxIcon.Error);
        }
    }
}