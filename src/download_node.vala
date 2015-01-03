namespace alaia {
    class ProgressBullet : Clutter.Actor {
        private Clutter.Canvas c;
        private DownloadNode parent;
        private double fraction = 50.0;
        public ProgressBullet(DownloadNode parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.x = 0;
            this.y = 0;
            this.content = c;
            this.set_size(rnd(parent.width), rnd(parent.height));
            this.c.set_size(rnd(parent.width), rnd(parent.height));
            this.c.draw.connect(do_draw);
            this.c.invalidate();
        }

        public bool do_draw(Cairo.Context cr, int w, int h) {
            cr.set_source_rgba(0,0,0,0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.set_source_rgba(col_h2f(this.parent.color.red)*2,
                              col_h2f(this.parent.color.green)*2,
                              col_h2f(this.parent.color.blue)*2,
                              1);
            cr.set_operator(Cairo.Operator.OVER);
            cr.set_line_width(Config.c.bullet_stroke);
            cr.rectangle(0,0,Config.c.node_height,Config.c.node_height);
            cr.stroke();
            cr.set_source_rgba(col_h2f(this.parent.color.red),
                              col_h2f(this.parent.color.green),
                              col_h2f(this.parent.color.blue),
                              1.0);
            cr.rectangle(5,5,this.fraction*(Config.c.node_height-10),Config.c.node_height-10);
            cr.fill();
            return true;
        }

        public void set_fraction(double fraction) {
            this.fraction = fraction;
            this.c.invalidate();
        }
    }

    class DownloadNode : Node {
        private WebKit.Download dl;
        private bool finished=false;
        private ProgressBullet progress;
        private Clutter.Text text;

        public DownloadNode(HistoryTrack track, WebKit.Download download, Node? par) {
            base(track,par);
            this.dl = download;
            this.progress = new ProgressBullet(this);
            this.add_child(this.progress);
            this.text = new Clutter.Text.with_text("Monospace Bold 9", "0 %");
            this.text.color = this.color.lighten();
            this.add_child(this.text);
            this.text.x = Config.c.node_height/2;
            this.text.y = Config.c.node_height/2;
            this.text.add_constraint(
                new Clutter.AlignConstraint(this, Clutter.AlignAxis.BOTH,0.5f)
            );
            
            this.opacity = 0x7F;
            this.background_color = this.color;
            this.dl.finished.connect(()=>{this.finished=true;});
            this.dl.failed.connect(()=>{this.finished=true;});
            GLib.Idle.add(this.update);
        }

        public bool update() {
            stdout.printf("updating\n");
            this.progress.set_fraction(this.dl.get_estimated_progress());
            double percent = this.dl.get_estimated_progress()*100;
            this.text.set_text("%d %".printf((int)percent));
            if (!this.finished) {
                GLib.Idle.add(this.update);
            }
            return false;
        }
    }
}