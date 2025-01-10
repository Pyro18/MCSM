using MCSM.Core.Services;
using MCSM.Core.Models;
using MCSM.Core.Utils;

namespace MCSM.Desktop.Forms;

public class AddServerForm : Form
{
    private readonly ServerListManager _serverListManager;
    private readonly UpdateManager _updateManager;
    private readonly Logger _logger;
    
    private TextBox _nameTextBox;
    private ComboBox _serverTypeComboBox;
    private ComboBox _versionComboBox;
    private Button _createButton;
    private Button _cancelButton;
    private Label _errorLabel;
    
    public AddServerForm(ServerListManager serverListManager)
    {
        _serverListManager = serverListManager;
        _updateManager = new UpdateManager();
        _logger = new Logger();
        
        InitializeComponent();
        LoadVersions();
    }
    
    private void InitializeComponent()
    {
        this.Text = "Add New Server";
        this.Size = new Size(400, 250);
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.StartPosition = FormStartPosition.CenterParent;
        this.MaximizeBox = false;
        this.MinimizeBox = false;
        
        var layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(10),
            ColumnCount = 2,
            RowCount = 5
        };
        
        // Server Name
        layout.Controls.Add(new Label { Text = "Server Name:" }, 0, 0);
        _nameTextBox = new TextBox { Width = 200 };
        layout.Controls.Add(_nameTextBox, 1, 0);
        
        // Server Type
        layout.Controls.Add(new Label { Text = "Server Type:" }, 0, 1);
        _serverTypeComboBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList,
            Width = 200
        };
        _serverTypeComboBox.Items.AddRange(new[] { "PaperMC", "Vanilla" });
        _serverTypeComboBox.SelectedIndex = 0;
        _serverTypeComboBox.SelectedIndexChanged += ServerType_Changed;
        layout.Controls.Add(_serverTypeComboBox, 1, 1);
        
        // Version
        layout.Controls.Add(new Label { Text = "Version:" }, 0, 2);
        _versionComboBox = new ComboBox
        {
            DropDownStyle = ComboBoxStyle.DropDownList,
            Width = 200
        };
        layout.Controls.Add(_versionComboBox, 1, 2);
        
        // Error Label
        _errorLabel = new Label
        {
            ForeColor = Color.Red,
            AutoSize = true
        };
        layout.Controls.Add(_errorLabel, 1, 3);
        
        // Buttons
        var buttonPanel = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.RightToLeft,
            Dock = DockStyle.Fill
        };
        
        _createButton = new Button
        {
            Text = "Create",
            DialogResult = DialogResult.OK,
            Width = 80
        };
        _createButton.Click += CreateButton_Click;
        
        _cancelButton = new Button
        {
            Text = "Cancel",
            DialogResult = DialogResult.Cancel,
            Width = 80
        };
        
        buttonPanel.Controls.Add(_cancelButton);
        buttonPanel.Controls.Add(_createButton);
        layout.Controls.Add(buttonPanel, 1, 4);
        
        // Configure layout
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
        
        for (int i = 0; i < layout.RowCount; i++)
        {
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        }
        
        this.Controls.Add(layout);
    }
    
    private async void LoadVersions()
    {
        try
        {
            _versionComboBox.Items.Clear();
            _versionComboBox.Items.Add("Loading...");
            _versionComboBox.SelectedIndex = 0;
            _versionComboBox.Enabled = false;
            _createButton.Enabled = false;
            
            bool isPaperMC = _serverTypeComboBox.SelectedItem?.ToString() == "PaperMC";
            
            var versions = await _updateManager.GetAvailableVersions(isPaperMC);
            
            _versionComboBox.Items.Clear();
            foreach (var version in versions)
            {
                _versionComboBox.Items.Add(version);
            }
            
            if (_versionComboBox.Items.Count > 0)
            {
                _versionComboBox.SelectedIndex = 0;
            }
            
            _errorLabel.Text = "";
        }
        catch (Exception ex)
        {
            _errorLabel.Text = "Error loading versions. Please try again.";
            _logger.Log($"Error loading versions: {ex.Message}", LogEntry.LogLevel.Error);
        }
        finally
        {
            _versionComboBox.Enabled = true;
            _createButton.Enabled = true;
        }
    }
    
    private void ServerType_Changed(object sender, EventArgs e)
    {
        LoadVersions();
    }
    
    private async void CreateButton_Click(object sender, EventArgs e)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(_nameTextBox.Text))
            {
                _errorLabel.Text = "Please enter a server name";
                return;
            }
        
            if (_versionComboBox.SelectedItem == null)
            {
                _errorLabel.Text = "Please select a version";
                return;
            }
        
            _createButton.Enabled = false;
            _errorLabel.Text = "Creating server...";
        
            string name = _nameTextBox.Text.Trim();
            string version = _versionComboBox.SelectedItem.ToString();
            bool isPaperMC = _serverTypeComboBox.SelectedItem?.ToString() == "PaperMC";
        
            using (var loadingForm = new LoadingForm("Creating server..."))
            {
                loadingForm.Show(this);
                // Create server (which will also download the JAR)
                var server = await _serverListManager.CreateServer(name, version, isPaperMC);
            }
        
            DialogResult = DialogResult.OK;
            Close();
        }
        catch (Exception ex)
        {
            _errorLabel.Text = "Error creating server. Please try again.";
            _logger.Log($"Error creating server: {ex.Message}", LogEntry.LogLevel.Error);
            MessageBox.Show(
                $"Error creating server: {ex.Message}",
                "Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
        finally
        {
            _createButton.Enabled = true;
        }
    }
}