using MCSM.Core.Services;
using MCSM.Core.Models;
using MCSM.Desktop.Controls;

namespace MCSM.Desktop.Forms;

public partial class MainForm : Form
{
    private readonly ServerManager _serverManager;
    private readonly ConfigManager _configManager;
    
    public MainForm()
    {
        InitializeComponent();
        
        _serverManager = new ServerManager();
        _configManager = new ConfigManager();
        
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

        var serverStatus = new ServerStatusControl
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };
        mainLayout.Controls.Add(serverStatus, 1, 0);

        var console = new ConsoleControl
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };
        mainLayout.SetColumnSpan(console, 2);
        mainLayout.Controls.Add(console, 0, 1);

        var controlPanel = new Panel
        {
            Dock = DockStyle.Fill,
            BorderStyle = BorderStyle.FixedSingle
        };

        var startButton = new Button
        {
            Text = "Avvia Server",
            Dock = DockStyle.Top,
            Height = 40,
            Margin = new Padding(5)
        };
        startButton.Click += StartServer_Click;

        var stopButton = new Button
        {
            Text = "Ferma Server",
            Dock = DockStyle.Top,
            Height = 40,
            Margin = new Padding(5)
        };
        stopButton.Click += StopServer_Click;

        var configButton = new Button
        {
            Text = "Configurazione",
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

    private void StartServer_Click(object sender, EventArgs e)
    {
        // TODO: Implements the server start
    }

    private void StopServer_Click(object sender, EventArgs e)
    {
        // TODO: Implement the server stop
    }

    private void ConfigButton_Click(object sender, EventArgs e)
    {
        using var configForm = new ServerConfigForm(_configManager, new ServerConfig());
        if (configForm.ShowDialog() == DialogResult.OK)
        {
            // TODO: Implement server save configuration
        }
    }

    private void SetupEventHandlers()
    {
        this.Load += MainForm_Load;
        this.FormClosing += MainForm_FormClosing;
        
    }

    private void MainForm_Load(object sender, EventArgs e)
    {
        LoadServerConfigurations();
    }

    private void MainForm_FormClosing(object sender, FormClosingEventArgs e)
    {
        SaveServerConfigurations();
        StopServerIfRunning();
    }

    private void LoadServerConfigurations()
    {
        try
        {
            // TODO: Implement the server configurations loading
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Errore nel caricamento delle configurazioni: {ex.Message}",
                          "Errore",
                          MessageBoxButtons.OK,
                          MessageBoxIcon.Error);
        }
    }

    private void SaveServerConfigurations()
    {
        try
        {
            // TODO: Implement the server configurations saving
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Errore nel salvataggio delle configurazioni: {ex.Message}",
                          "Errore",
                          MessageBoxButtons.OK,
                          MessageBoxIcon.Error);
        }
    }

    private void StopServerIfRunning()
    {
        try
        {
            _serverManager.StopServer();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Errore nell'arresto del server: {ex.Message}",
                          "Errore",
                          MessageBoxButtons.OK,
                          MessageBoxIcon.Warning);
        }
    }
}