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
}