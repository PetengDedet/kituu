#!/usr/bin/env python

import os, stat, time
import pprint
import pygtk, gtk

import pygst
pygst.require('0.10')
import gst
import gobject

import pygame.mixer

from matplotlib.figure import Figure
from matplotlib.backends.backend_gtkagg import FigureCanvasGTKAgg as FigureCanvas
import scipy.io.wavfile as wavfile

pygame.init()


interface = """
<ui>
    <menubar name="MenuBar">
        <menu action="File">
            <menuitem action="New"/>
            <menuitem action="Open"/>
            <menuitem action="Save"/>
            <menuitem action="Quit"/>
        </menu>
        <menu action="Edit">
            <menuitem action="Preferences"/>
        </menu>
        <menu action="Help">
            <menuitem action="About"/>
        </menu>
    </menubar>
</ui>
"""

class Nitpick:
    column_names = ['Name', 'Size', 'Mode', 'Last Changed']

    def about_box(self, widget):
        about = gtk.AboutDialog()
        about.set_program_name("BeatNitPycker")
        about.set_version("0.1")
        about.set_copyright("(c) Philippe \"xaccrocheur\" Coatmeur")
        about.set_comments("Simple sound sample auditor")
        about.set_website("https://github.com/xaccrocheur")
        about.set_logo(gtk.icon_theme_get_default().load_icon("gstreamer-properties", 128, 0))
        about.run()
        about.destroy()

    def stop_audio(self, plop):
        pygame.mixer.stop()

    def delete_event(self, widget, event, data=None):
        gtk.main_quit()
        return False

    def get_sel_file(self, tree_selection) :
        (model, pathlist) = tree_selection.get_selected_rows()
        for path in pathlist :
            tree_iter = model.get_iter(path)
            filename = os.path.join(self.dirname, model.get_value(tree_iter,0))
            value = model.get_value(tree_iter,0)
            # print "playing " + filename
            return filename

    def __init__(self, dname = None):
        cell_data_funcs = (None, self.file_size, self.file_mode,
                           self.file_last_changed)

        self.window = gtk.Window()
        self.window.set_size_request(300, 600)
        self.window.connect("delete_event", self.delete_event)
        self.window.set_icon(gtk.icon_theme_get_default().load_icon("gstreamer-properties", 128, 0))

        self.image = gtk.Image()

        vbox = gtk.VBox()
        hbox = gtk.VBox(True)
        bbox = gtk.HBox()


        self.play_button = gtk.Button()
        self.slider = gtk.HScale()

        bbox.pack_start(self.play_button, False)
        bbox.pack_start(self.slider, True, True)

        # self.main_window.add(self.hbox)
        # self.main_window.connect('destroy', self.on_destroy)

        fileName = self.get_sel_file

        myPlayer = PlaybackInterface(fileName)

        # self.play_button.set_image(self.PLAY_IMAGE)
        self.play_button.connect('clicked', myPlayer.on_play)


        self.slider.set_range(0, 100)
        self.slider.set_increments(1, 10)
        self.slider.connect('value-changed', myPlayer.on_slider_change)

        vbox.pack_start (bbox, False, False, 1)
        vbox.pack_start (hbox, False, False, 1)
        hbox.pack_start (self.image, True, True, 0)

        obutton = gtk.Button ("Open a picture...")
        vbox.pack_start (obutton, False, False, 0)

        # open image
        obutton.connect_after('clicked', self.on_open_clicked)

        uimanager = gtk.UIManager()
        accelgroup = uimanager.get_accel_group()
        self.window.add_accel_group(accelgroup)

        listmodel = self.make_list(dname)
        liststore = gtk.ListStore(str, int, int, str)

        # create the TreeView
        self.treeview = gtk.TreeView(liststore)


        tree_selection = self.treeview.get_selection()
        tree_selection.set_mode(gtk.SELECTION_MULTIPLE)
        tree_selection.connect("changed", myPlayer.on_play)


        # create the TreeViewColumns to display the data
        self.tvcolumn = [None] * len(self.column_names)

        self.bouton = gtk.ToolButton(gtk.STOCK_MEDIA_STOP)
        self.bouton.connect('clicked', self.stop_audio)
        vbox.pack_end(self.bouton, False)

        cellpb = gtk.CellRendererPixbuf()
        self.tvcolumn[0] = gtk.TreeViewColumn(self.column_names[0], cellpb)
        self.tvcolumn[0].set_cell_data_func(cellpb, self.file_pixbuf)
        cell = gtk.CellRendererText()
        self.tvcolumn[0].pack_start(cell, False)
        self.tvcolumn[0].set_cell_data_func(cell, self.file_name)
        self.tvcolumn[0].set_sort_column_id(0)

        self.treeview.append_column(self.tvcolumn[0])
        for n in range(1, len(self.column_names)):
            cell = gtk.CellRendererText()
            self.tvcolumn[n] = gtk.TreeViewColumn(self.column_names[n], cell)

            if n == 1:
                cell.set_property('xalign', 1.0)
            self.tvcolumn[n].set_cell_data_func(cell, cell_data_funcs[n])

            self.treeview.append_column(self.tvcolumn[n])

        self.treeview.connect('row-activated', self.open_file)
        self.scrolledwindow = gtk.ScrolledWindow()
        self.scrolledwindow.add(self.treeview)
        self.treeview.set_model(listmodel)

        self.actiongroup = gtk.ActionGroup("uimanager")

        self.actiongroup.add_actions([
            ("New", gtk.STOCK_NEW, "_New", None, "Create a New Document"),
            ("Open", gtk.STOCK_OPEN, "_Open", None, "Open an Existing Document"),
            ("Save", gtk.STOCK_SAVE, "_Save", None, "Save the Current Document"),
            ("Quit", gtk.STOCK_QUIT, "_Quit", None, "Quit the Application", lambda w: gtk.main_quit()),
            ("File", None, "_File"),
            ("Preferences", gtk.STOCK_PREFERENCES, "_Preferences", None, "Edit the Preferences"),
            ("Edit", None, "_Edit"),
            ("About", gtk.STOCK_ABOUT, "_About", None, "yow", self.about_box),
            ("Help", None, "_Help")
        ])

        uimanager.insert_action_group(self.actiongroup, 0)
        uimanager.add_ui_from_string(interface)

        menubar = uimanager.get_widget("/MenuBar")
        vbox.pack_start(menubar, False)
        vbox.pack_start(self.scrolledwindow)

        self.window.add(vbox)
        self.window.show_all()
        return

    def on_open_clicked (self, button):
        self.image.set_from_file("/usr/lib/lv2/paramEQ-Rafols.lv2/combopix/peak.png")
        self.scrolledwindow.show_all()
        self.myplot.draw()

        # pp = pprint.PrettyPrinter(indent=4)
        # pp.pprint(plop)

    def make_list(self, dname=None):
        if not dname:
            self.dirname = os.path.expanduser('/home/px/scripts/beatnitpycker/')
        else:
            self.dirname = os.path.abspath(dname)
        self.window.set_title("BeatNitpycker : " + self.dirname)
        files = [f for f in os.listdir(self.dirname) if f[0] <> '.']
        files.sort()
        files = ['..'] + files
        listmodel = gtk.ListStore(object)
        for f in files:
            listmodel.append([f])
        return listmodel

    def open_file(self, treeview, path, column):
        audioFormats = [ ".wav", ".mp3", ".ogg", ".flac" ]
        model = treeview.get_model()
        iter = model.get_iter(path)
        filename = os.path.join(self.dirname, model.get_value(iter, 0))
        filestat = os.stat(filename)
        # print filename
        if stat.S_ISDIR(filestat.st_mode):
            new_model = self.make_list(filename)
            treeview.set_model(new_model)
        else:
            if filename.endswith(tuple(audioFormats)):
                myPlayer = PlaybackInterface(filename)
                # self.myPlayer(self, "plop")
                pygame.mixer.stop()
                pygame.mixer.Sound(filename).play()
                while pygame.mixer.music.get_busy():
                    pygame.event.wait()
                    # pygame.time.Clock().tick(10)
                if filename.endswith(".wav"):
                    rate, data = wavfile.read(open(filename, 'r'))
                    f = Figure(figsize=(4.5,1), linewidth=0.0, edgecolor='b', facecolor='r', dpi=100)
                    self.drawing_area = FigureCanvas(f)
                    a = f.add_subplot(111)
                    a.plot(range(len(data)),data)
                    a.axis('off')
                    f.savefig("/home/px/tmp/f.png",
                              edgecolor='r',
                              facecolor='w',
                              orientation='portrait',
                              papertype=None,
                              format=None,
                              transparent=False,
                              bbox_inches='tight',
                              pad_inches=0.1,
                              frameon=True
                    )
                    self.image.set_from_file("/home/px/tmp/f.png")
                else:
                    self.image.set_from_pixbuf(None)
        return

    def file_pixbuf(self, column, cell, model, iter):
        audioFormats = [ ".wav", ".mp3", ".ogg", ".flac" ]
        filename = os.path.join(self.dirname, model.get_value(iter, 0))
        filestat = os.stat(filename)
        if stat.S_ISDIR(filestat.st_mode):
            pb = gtk.icon_theme_get_default().load_icon("folder", 24, 0)
        elif filename.endswith(tuple(audioFormats)):
            pb = gtk.icon_theme_get_default().load_icon("audio-volume-medium", 24, 0)
        else:
            pb = gtk.icon_theme_get_default().load_icon("edit-copy", 24, 0)
        cell.set_property('pixbuf', pb)
        return



    def file_name(self, column, cell, model, iter):
        cell.set_property('text', model.get_value(iter, 0))
        return

    def file_size(self, column, cell, model, iter):
        filename = os.path.join(self.dirname, model.get_value(iter, 0))
        filestat = os.stat(filename)
        cell.set_property('text', filestat.st_size)
        return

    def file_mode(self, column, cell, model, iter):
        filename = os.path.join(self.dirname, model.get_value(iter, 0))
        filestat = os.stat(filename)
        cell.set_property('text', oct(stat.S_IMODE(filestat.st_mode)))
        return

    def file_last_changed(self, column, cell, model, iter):
        filename = os.path.join(self.dirname, model.get_value(iter, 0))
        filestat = os.stat(filename)
        cell.set_property('text', time.ctime(filestat.st_mtime))
        return


class PlaybackInterface:

    PLAY_IMAGE = gtk.image_new_from_stock(gtk.STOCK_MEDIA_PLAY, gtk.ICON_SIZE_BUTTON)
    PAUSE_IMAGE = gtk.image_new_from_stock(gtk.STOCK_MEDIA_PAUSE, gtk.ICON_SIZE_BUTTON)

    def __init__(self, filename):
        print "yown"
        print filename
        # self.main_window = gtk.Window()

        # self.main_window.set_border_width(6)
        # self.main_window.set_size_request(600, 50)

        self.playbin = gst.element_factory_make('playbin2')
        self.playbin.set_property('uri', filename)

        self.bus = self.playbin.get_bus()
        self.bus.add_signal_watch()

        self.bus.connect("message::eos", self.on_finish)

        self.is_playing = False

        # self.main_window.show_all()

    def on_finish(self, bus, message):
        self.playbin.set_state(gst.STATE_PAUSED)
        self.play_button.set_image(self.PLAY_IMAGE)
        self.is_playing = False
        self.playbin.seek_simple(gst.FORMAT_TIME, gst.SEEK_FLAG_FLUSH, 0)
        self.slider.set_value(0)

    def on_destroy(self, window):
        # NULL state allows the pipeline to release resources
        self.playbin.set_state(gst.STATE_NULL)
        self.is_playing = False
        gtk.main_quit()

    def on_play(self, button):
        if not self.is_playing:
            # self.play_button.set_image(self.PAUSE_IMAGE)
            self.is_playing = True

            # self.playbin.set_state(gst.STATE_PLAYING)
            gobject.timeout_add(100, self.update_slider)

        else:
            # self.play_button.set_image(self.PLAY_IMAGE)
            self.is_playing = False

            # self.playbin.set_state(gst.STATE_PAUSED)

    def on_slider_change(self, slider):
        seek_time_secs = slider.get_value()
        self.playbin.seek_simple(gst.FORMAT_TIME, gst.SEEK_FLAG_FLUSH | gst.SEEK_FLAG_KEY_UNIT, seek_time_secs * gst.SECOND)

    def update_slider(self):
        if not self.is_playing:
            return False # cancel timeout

        try:
            nanosecs, format = self.playbin.query_position(gst.FORMAT_TIME)
            duration_nanosecs, format = self.playbin.query_duration(gst.FORMAT_TIME)

            # block seek handler so we don't seek when we set_value()
            self.slider.handler_block_by_func(self.on_slider_change)

            self.slider.set_range(0, float(duration_nanosecs) / gst.SECOND)
            self.slider.set_value(float(nanosecs) / gst.SECOND)

            self.slider.handler_unblock_by_func(self.on_slider_change)

        except gst.QueryError:
            # pipeline must not be ready and does not know position
         pass

        return True # continue calling every 30 milliseconds


def main():
    gtk.main()

if __name__ == "__main__":
    flcdexample = Nitpick()
    main()
