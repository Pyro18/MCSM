using MCSM.Core.Services;
using MCSM.Core.Models;
using MCSM.Core.Utils;

namespace MCSM.Desktop.Forms;

public partial class SettingsForm : Form
{
    private readonly ConfigManager _configManager;
    private readonly ServerConfig _currentConfig;
    
    private TextBox _javaPathTextBox;
    private CheckBox _autoStartCheckBox;
    private CheckBox _autoUpdateCheckBox;
    private CheckBox _minimizeToTrayCheckBox;
    private NumericUpDown _backupIntervalUpDown;
    private TextBox _backupFolderTextBox;
    private CheckBox _enableLoggingCheckBox;
    private ComboBox _logLevelComboBox;
    private CheckBox _deleteOldBackupsCheckBox;
    private NumericUpDown _keepBackupsForDaysUpDown;

    public SettingsForm(ConfigManager configManager, ServerConfig currentConfig)
    {
        _configManager = configManager;
        _currentConfig = currentConfig;
        InitializeComponent();
        LoadSettings();
    }

    private void InitializeComponent()
    {
        this.Text = "MCSM Settings";
        this.Size = new Size(500, 500);
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.StartPosition = FormStartPosition.CenterParent;

        var layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 2,
            RowCount = 11,
            Padding = new Padding(10)
        };

        int currentRow = 0;

        // Java Path
        layout.Controls.Add(new Label { Text = "Java Path:" }, 0, currentRow);
        var pathPanel = new Panel { Dock = DockStyle.Fill };
        _javaPathTextBox = new TextBox { Width = 280, Dock = DockStyle.Left };
        var browseButton = new Button { Text = "...", Width = 30, Dock = DockStyle.Right };
        var detectButton = new Button { Text = "Detect", Width = 60, Dock = DockStyle.Right };
        browseButton.Click += BrowseJavaPath_Click;
        detectButton.Click += DetectJavaPath_Click;
        pathPanel.Controls.AddRange(new Control[] { _javaPathTextBox, detectButton, browseButton });
        layout.Controls.Add(pathPanel, 1, currentRow++);

        // Auto Start
        layout.Controls.Add(new Label { Text = "Startup:" }, 0, currentRow);
        _autoStartCheckBox = new CheckBox { Text = "Start server on application launch" };
        layout.Controls.Add(_autoStartCheckBox, 1, currentRow++);

        // Auto Update
        layout.Controls.Add(new Label { Text = "Updates:" }, 0, currentRow);
        _autoUpdateCheckBox = new CheckBox { Text = "Check for updates on startup" };
        layout.Controls.Add(_autoUpdateCheckBox, 1, currentRow++);

        // Minimize to Tray
        layout.Controls.Add(new Label { Text = "Tray Icon:" }, 0, currentRow);
        _minimizeToTrayCheckBox = new CheckBox { Text = "Minimize to system tray" };
        layout.Controls.Add(_minimizeToTrayCheckBox, 1, currentRow++);

        // Backup Interval
        layout.Controls.Add(new Label { Text = "Backup Interval (hours):" }, 0, currentRow);
        _backupIntervalUpDown = new NumericUpDown
        {
            Minimum = 0,
            Maximum = 168, // one week
            Value = 24,
            DecimalPlaces = 0
        };
        layout.Controls.Add(_backupIntervalUpDown, 1, currentRow++);

        // Delete Old Backups
        layout.Controls.Add(new Label { Text = "Backup Cleanup:" }, 0, currentRow);
        _deleteOldBackupsCheckBox = new CheckBox { Text = "Delete old backups" };
        layout.Controls.Add(_deleteOldBackupsCheckBox, 1, currentRow++);

        // Keep Backups Days
        layout.Controls.Add(new Label { Text = "Keep Backups (days):" }, 0, currentRow);
        _keepBackupsForDaysUpDown = new NumericUpDown
        {
            Minimum = 1,
            Maximum = 365,
            Value = 7,
            DecimalPlaces = 0
        };
        layout.Controls.Add(_keepBackupsForDaysUpDown, 1, currentRow++);

        // Backup Folder
        layout.Controls.Add(new Label { Text = "Backup Folder:" }, 0, currentRow);
        var backupPanel = new Panel { Dock = DockStyle.Fill };
        _backupFolderTextBox = new TextBox { Width = 280, Dock = DockStyle.Left };
        var browseFolderButton = new Button { Text = "...", Width = 30, Dock = DockStyle.Right };
        browseFolderButton.Click += BrowseBackupFolder_Click;
        backupPanel.Controls.AddRange(new Control[] { _backupFolderTextBox, browseFolderButton });
        layout.Controls.Add(backupPanel, 1, currentRow++);

        // Enable Logging
        layout.Controls.Add(new Label { Text = "Logging:" }, 0, currentRow);
        _enableLoggingCheckBox = new CheckBox { Text = "Enable logging" };
        layout.Controls.Add(_enableLoggingCheckBox, 1, currentRow++);

        // Log Level
        layout.Controls.Add(new Label { Text = "Log Level:" }, 0, currentRow);
        _logLevelComboBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        _logLevelComboBox.Items.AddRange(Enum.GetNames<LogEntry.LogLevel>());
        _logLevelComboBox.SelectedIndex = 1; // Info
        layout.Controls.Add(_logLevelComboBox, 1, currentRow++);

        // Buttons
        var buttonPanel = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.RightToLeft
        };

        var saveButton = new Button { Text = "Save", Width = 80 };
        var cancelButton = new Button { Text = "Cancel", Width = 80 };
        
        saveButton.Click += SaveButton_Click;
        cancelButton.Click += CancelButton_Click;
        
        buttonPanel.Controls.Add(cancelButton);
        buttonPanel.Controls.Add(saveButton);
        layout.Controls.Add(buttonPanel, 1, currentRow);

        this.Controls.Add(layout);
    }

    private void LoadSettings()
    {
        _javaPathTextBox.Text = _currentConfig.JavaPath;
        _autoStartCheckBox.Checked = _currentConfig.AutoStartServer;
        _autoUpdateCheckBox.Checked = _currentConfig.CheckUpdatesOnStartup;
        _minimizeToTrayCheckBox.Checked = _currentConfig.MinimizeToTray;
        _backupIntervalUpDown.Value = _currentConfig.BackupIntervalHours;
        _backupFolderTextBox.Text = _currentConfig.BackupFolderPath;
        _enableLoggingCheckBox.Checked = _currentConfig.EnableLogging;
        _logLevelComboBox.SelectedItem = _currentConfig.MinimumLogLevel.ToString();
        _deleteOldBackupsCheckBox.Checked = _currentConfig.DeleteOldBackups;
        _keepBackupsForDaysUpDown.Value = _currentConfig.KeepBackupsForDays;
    }

    private void BrowseJavaPath_Click(object sender, EventArgs e)
    {
        using var dialog = new OpenFileDialog
        {
            Filter = "Java executable|java.exe|All files|*.*",
            FilterIndex = 1
        };

        if (dialog.ShowDialog() == DialogResult.OK)
        {
            _javaPathTextBox.Text = dialog.FileName;
        }
    }

    private void DetectJavaPath_Click(object sender, EventArgs e)
    {
        var fileHelper = new FileHelper();
        var javaPath = fileHelper.GetJavaPath();
        
        if (fileHelper.IsValidJavaInstallation(javaPath))
        {
            _javaPathTextBox.Text = javaPath;
        }
        else
        {
            MessageBox.Show("Could not detect a valid Java installation.\nPlease install Java or select the path manually.",
                          "Java Not Found",
                          MessageBoxButtons.OK,
                          MessageBoxIcon.Warning);
        }
    }

    private void BrowseBackupFolder_Click(object sender, EventArgs e)
    {
        using var dialog = new FolderBrowserDialog
        {
            Description = "Select Backup Folder Location",
            UseDescriptionForTitle = true
        };

        if (dialog.ShowDialog() == DialogResult.OK)
        {
            _backupFolderTextBox.Text = dialog.SelectedPath;
        }
    }

    private async void SaveButton_Click(object sender, EventArgs e)
    {
        try
        {
            _currentConfig.JavaPath = _javaPathTextBox.Text;
            _currentConfig.AutoStartServer = _autoStartCheckBox.Checked;
            _currentConfig.CheckUpdatesOnStartup = _autoUpdateCheckBox.Checked;
            _currentConfig.MinimizeToTray = _minimizeToTrayCheckBox.Checked;
            _currentConfig.BackupIntervalHours = (int)_backupIntervalUpDown.Value;
            _currentConfig.BackupFolderPath = _backupFolderTextBox.Text;
            _currentConfig.EnableLogging = _enableLoggingCheckBox.Checked;
            _currentConfig.MinimumLogLevel = Enum.Parse<LogEntry.LogLevel>(_logLevelComboBox.SelectedItem.ToString());
            _currentConfig.DeleteOldBackups = _deleteOldBackupsCheckBox.Checked;
            _currentConfig.KeepBackupsForDays = (int)_keepBackupsForDaysUpDown.Value;

            await _configManager.SaveServerConfigAsync(_currentConfig);
            DialogResult = DialogResult.OK;
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error saving settings: {ex.Message}",
                          "Error",
                          MessageBoxButtons.OK,
                          MessageBoxIcon.Error);
        }
    }

    private void CancelButton_Click(object sender, EventArgs e)
    {
        DialogResult = DialogResult.Cancel;
        Close();
    }
}