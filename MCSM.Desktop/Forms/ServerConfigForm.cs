using MCSM.Core.Models;
using MCSM.Core.Services;

namespace MCSM.Desktop.Forms;

public partial class ServerConfigForm : Form
{
    private readonly ConfigManager _configManager;
    private ServerConfig _currentConfig;
    
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

        var panel = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(10),
            RowCount = 13,
            ColumnCount = 2
        };

        // Server Path
        panel.Controls.Add(new Label { Text = "Server Path:" }, 0, 0);
        _serverPathBox = new TextBox { Dock = DockStyle.Fill };
        panel.Controls.Add(_serverPathBox, 1, 0);

        // Memory Settings
        panel.Controls.Add(new Label { Text = "Min Memory (MB):" }, 0, 1);
        _memoryMinBox = new NumericUpDown 
        { 
            Minimum = 512,
            Maximum = 32768,
            Value = 1024,
            Increment = 512
        };
        panel.Controls.Add(_memoryMinBox, 1, 1);

        panel.Controls.Add(new Label { Text = "Max Memory (MB):" }, 0, 2);
        _memoryMaxBox = new NumericUpDown
        {
            Minimum = 512,
            Maximum = 32768,
            Value = 2048,
            Increment = 512
        };
        panel.Controls.Add(_memoryMaxBox, 1, 2);

        // Java Path
        // TODO: Add a browse button to select the Java path or auto-detect it
        panel.Controls.Add(new Label { Text = "Java Path:" }, 0, 3);
        _javaPathBox = new TextBox { Dock = DockStyle.Fill };
        panel.Controls.Add(_javaPathBox, 1, 3);

        // Network Settings
        panel.Controls.Add(new Label { Text = "Port:" }, 0, 4);
        _portBox = new NumericUpDown
        {
            Minimum = 1025,
            Maximum = 65535,
            Value = 25565
        };
        panel.Controls.Add(_portBox, 1, 4);

        panel.Controls.Add(new Label { Text = "Server IP:" }, 0, 5);
        _serverIpBox = new TextBox { Text = "0.0.0.0" };
        panel.Controls.Add(_serverIpBox, 1, 5);

        // World Settings
        panel.Controls.Add(new Label { Text = "World Name:" }, 0, 6);
        _worldNameBox = new TextBox { Text = "world" };
        panel.Controls.Add(_worldNameBox, 1, 6);

        panel.Controls.Add(new Label { Text = "Max Players:" }, 0, 7);
        _maxPlayersBox = new NumericUpDown
        {
            Minimum = 1,
            Maximum = 100,
            Value = 20
        };
        panel.Controls.Add(_maxPlayersBox, 1, 7);

        panel.Controls.Add(new Label { Text = "Difficulty:" }, 0, 8);
        _difficultyBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        _difficultyBox.Items.AddRange(new[] { "peaceful", "easy", "normal", "hard" });
        _difficultyBox.SelectedIndex = 2; // normal
        panel.Controls.Add(_difficultyBox, 1, 8);

        // Game Settings
        _commandBlockBox = new CheckBox { Text = "Enable Command Blocks" };
        panel.Controls.Add(_commandBlockBox, 1, 9);

        panel.Controls.Add(new Label { Text = "MOTD:" }, 0, 10);
        _motdBox = new TextBox { Text = "A Minecraft Server" };
        panel.Controls.Add(_motdBox, 1, 10);

        _onlineModeBox = new CheckBox { Text = "Online Mode (Premium)" };
        _onlineModeBox.Checked = true;
        panel.Controls.Add(_onlineModeBox, 1, 11);

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

        this.Controls.AddRange(new Control[] { panel, buttonPanel });
    }

    private void LoadConfig()
    {
        if (_currentConfig == null) return;

        _serverPathBox.Text = _currentConfig.ServerPath;
        _memoryMinBox.Value = _currentConfig.MemoryMin;
        _memoryMaxBox.Value = _currentConfig.MemoryMax;
        _javaPathBox.Text = _currentConfig.JavaPath;
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