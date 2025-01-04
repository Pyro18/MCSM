using MCSM.Core.Services;

namespace MCSM.Desktop.Forms;

public partial class SettingsForm : Form
{
    private readonly ConfigManager _configManager;
    
    private TextBox javaPathTextBox;
    private CheckBox autoStartCheckBox;
    private CheckBox autoUpdateCheckBox;
    private CheckBox minimizeToTrayCheckBox;
    private NumericUpDown backupIntervalUpDown;
    private TextBox backupFolderTextBox;
    private CheckBox enableLoggingCheckBox;
    private ComboBox logLevelComboBox;

    public SettingsForm(ConfigManager configManager)
    {
        _configManager = configManager;
        InitializeComponent();
        LoadSettings();
    }

    private void InitializeComponent()
    {
        this.Text = "Impostazioni MCSM";
        this.Size = new Size(500, 400);
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.MaximizeBox = false;
        this.StartPosition = FormStartPosition.CenterParent;

        var layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 2,
            RowCount = 9,
            Padding = new Padding(10)
        };

        // Java Path
        layout.Controls.Add(new Label { Text = "Percorso Java:" }, 0, 0);
        var pathPanel = new Panel { Dock = DockStyle.Fill };
        javaPathTextBox = new TextBox { Dock = DockStyle.Fill };
        var browseButton = new Button { Text = "...", Width = 30 };
        browseButton.Click += BrowseJavaPath_Click;
        pathPanel.Controls.Add(javaPathTextBox);
        pathPanel.Controls.Add(browseButton);
        layout.Controls.Add(pathPanel, 1, 0);

        // Auto Start
        layout.Controls.Add(new Label { Text = "Avvio Automatico:" }, 0, 1);
        autoStartCheckBox = new CheckBox { Text = "Avvia il server all'apertura" };
        layout.Controls.Add(autoStartCheckBox, 1, 1);

        // Auto Update
        layout.Controls.Add(new Label { Text = "Aggiornamenti:" }, 0, 2);
        autoUpdateCheckBox = new CheckBox { Text = "Controlla aggiornamenti all'avvio" };
        layout.Controls.Add(autoUpdateCheckBox, 1, 2);

        // Minimize to Tray
        layout.Controls.Add(new Label { Text = "Tray Icon:" }, 0, 3);
        minimizeToTrayCheckBox = new CheckBox { Text = "Minimizza nella system tray" };
        layout.Controls.Add(minimizeToTrayCheckBox, 1, 3);

        // Backup Interval
        layout.Controls.Add(new Label { Text = "Intervallo Backup (ore):" }, 0, 4);
        backupIntervalUpDown = new NumericUpDown
        {
            Minimum = 0,
            Maximum = 168, // one week
            Value = 24,
            DecimalPlaces = 0
        };
        layout.Controls.Add(backupIntervalUpDown, 1, 4);

        // Backup Folder
        layout.Controls.Add(new Label { Text = "Cartella Backup:" }, 0, 5);
        var backupPanel = new Panel { Dock = DockStyle.Fill };
        backupFolderTextBox = new TextBox { Dock = DockStyle.Fill };
        var browseFolderButton = new Button { Text = "...", Width = 30 };
        browseFolderButton.Click += BrowseBackupFolder_Click;
        backupPanel.Controls.Add(backupFolderTextBox);
        backupPanel.Controls.Add(browseFolderButton);
        layout.Controls.Add(backupPanel, 1, 5);

        // Enable Logging
        layout.Controls.Add(new Label { Text = "Logging:" }, 0, 6);
        enableLoggingCheckBox = new CheckBox { Text = "Abilita logging" };
        layout.Controls.Add(enableLoggingCheckBox, 1, 6);

        // Log Level
        layout.Controls.Add(new Label { Text = "Livello Log:" }, 0, 7);
        logLevelComboBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        logLevelComboBox.Items.AddRange(new[] { "Debug", "Info", "Warning", "Error" });
        logLevelComboBox.SelectedIndex = 1; // default to Info
        layout.Controls.Add(logLevelComboBox, 1, 7);

        // Buttons
        var buttonPanel = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.RightToLeft
        };

        var saveButton = new Button { Text = "Salva" };
        var cancelButton = new Button { Text = "Annulla" };
        
        saveButton.Click += SaveButton_Click;
        cancelButton.Click += CancelButton_Click;
        
        buttonPanel.Controls.Add(cancelButton);
        buttonPanel.Controls.Add(saveButton);
        layout.Controls.Add(buttonPanel, 1, 8);

        this.Controls.Add(layout);
    }

    private void LoadSettings()
    {
        // TODO: Upload settings using ConfigManager
        javaPathTextBox.Text = "java";
        autoStartCheckBox.Checked = false;
        autoUpdateCheckBox.Checked = true;
        minimizeToTrayCheckBox.Checked = true;
        backupIntervalUpDown.Value = 24;
        backupFolderTextBox.Text = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "backups");
        enableLoggingCheckBox.Checked = true;
        logLevelComboBox.SelectedItem = "Info";
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
            javaPathTextBox.Text = dialog.FileName;
        }
    }

    private void BrowseBackupFolder_Click(object sender, EventArgs e)
    {
        using var dialog = new FolderBrowserDialog
        {
            Description = "Seleziona la cartella per i backup",
            UseDescriptionForTitle = true
        };

        if (dialog.ShowDialog() == DialogResult.OK)
        {
            backupFolderTextBox.Text = dialog.SelectedPath;
        }
    }

    private void SaveButton_Click(object sender, EventArgs e)
    {
        try
        {
            // TODO: Save settings using ConfigManager
            // Example (i guess):
            // _configManager.SaveSettings(new AppSettings { ... });

            DialogResult = DialogResult.OK;
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Errore nel salvataggio delle impostazioni: {ex.Message}",
                          "Errore",
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