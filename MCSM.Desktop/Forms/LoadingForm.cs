namespace MCSM.Desktop.Forms;

public class LoadingForm : Form
{
    public LoadingForm(string message)
    {
        this.Size = new Size(300, 100);
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.StartPosition = FormStartPosition.CenterParent;
        this.ControlBox = false;
        
        var label = new Label
        {
            Text = message,
            AutoSize = true,
            Location = new Point(10, 20)
        };
        
        var progress = new ProgressBar
        {
            Style = ProgressBarStyle.Marquee,
            MarqueeAnimationSpeed = 30,
            Size = new Size(280, 23),
            Location = new Point(10, 40)
        };
        
        this.Controls.AddRange(new Control[] { label, progress });
    }

    /// <summary>
    /// Required method for Designer support - do not modify
    /// the contents of this method with the code editor.
    /// </summary>
    private void InitializeComponent()
    {
        SuspendLayout();
        // 
        // LoadingForm
        // 
        ClientSize = new System.Drawing.Size(473, 403);
        ResumeLayout(false);
    }
}