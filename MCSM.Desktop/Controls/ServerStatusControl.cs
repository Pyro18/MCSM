namespace MCSM.Desktop.Controls;

public partial class ServerStatusControl : UserControl
{
    private Label statusLabel;
    private Label uptimeLabel;
    private Label playersLabel;
    private Label memoryLabel;
    private System.Windows.Forms.Timer updateTimer;

    public ServerStatusControl()
    {
        InitializeComponent();
        SetupTimer();
    }

    private void InitializeComponent()
    {
        TableLayoutPanel layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 2,
            RowCount = 4,
            Padding = new Padding(5)
        };

        // Status
        layout.Controls.Add(new Label { Text = "Stato:", Dock = DockStyle.Fill }, 0, 0);
        statusLabel = new Label { Text = "Offline", Dock = DockStyle.Fill, ForeColor = Color.Red };
        layout.Controls.Add(statusLabel, 1, 0);

        // Uptime
        layout.Controls.Add(new Label { Text = "Uptime:", Dock = DockStyle.Fill }, 0, 1);
        uptimeLabel = new Label { Text = "00:00:00", Dock = DockStyle.Fill };
        layout.Controls.Add(uptimeLabel, 1, 1);

        // Players
        layout.Controls.Add(new Label { Text = "Giocatori:", Dock = DockStyle.Fill }, 0, 2);
        playersLabel = new Label { Text = "0/20", Dock = DockStyle.Fill };
        layout.Controls.Add(playersLabel, 1, 2);

        // Memory
        layout.Controls.Add(new Label { Text = "Memoria:", Dock = DockStyle.Fill }, 0, 3);
        memoryLabel = new Label { Text = "0 MB", Dock = DockStyle.Fill };
        layout.Controls.Add(memoryLabel, 1, 3);

        Controls.Add(layout);
    }

    private void SetupTimer()
    {
        updateTimer = new System.Windows.Forms.Timer
        {
            Interval = 1000 // Aggiorna ogni secondo
        };
        updateTimer.Tick += UpdateTimer_Tick;
        updateTimer.Start();
    }

    private void UpdateTimer_Tick(object sender, EventArgs e)
    {
        // Qui aggiorneremo i valori in tempo reale
        UpdateStatus();
    }

    public void UpdateStatus(bool isOnline = false, TimeSpan uptime = default, int players = 0, int maxPlayers = 20, long memoryUsage = 0)
    {
        if (InvokeRequired)
        {
            Invoke(new Action(() => UpdateStatus(isOnline, uptime, players, maxPlayers, memoryUsage)));
            return;
        }

        statusLabel.Text = isOnline ? "Online" : "Offline";
        statusLabel.ForeColor = isOnline ? Color.Green : Color.Red;
        
        uptimeLabel.Text = uptime.ToString(@"hh\:mm\:ss");
        playersLabel.Text = $"{players}/{maxPlayers}";
        memoryLabel.Text = $"{memoryUsage / 1024 / 1024} MB";
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            updateTimer?.Stop();
            updateTimer?.Dispose();
        }
        base.Dispose(disposing);
    }
}