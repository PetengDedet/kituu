#!/usr/bin/python

import os, stat, time
import gst, gtk, gobject

class GUI(object):

    PLAY_IMAGE = gtk.image_new_from_stock(gtk.STOCK_MEDIA_PLAY, gtk.ICON_SIZE_BUTTON)
    PAUSE_IMAGE = gtk.image_new_from_stock(gtk.STOCK_MEDIA_PAUSE, gtk.ICON_SIZE_BUTTON)

    OPEN_IMAGE = gtk.image_new_from_stock(gtk.STOCK_ADD, gtk.ICON_SIZE_BUTTON)
    CLOSED_IMAGE = gtk.image_new_from_stock(gtk.STOCK_REFRESH, gtk.ICON_SIZE_BUTTON)
    toggled = True

    column_names = ['Name', 'Size', 'Mode', 'Last Changed']

    def __init__(self, dname = None):
        self.window = gtk.Window()
        self.window.set_size_request(300, 600)
        self.window.connect("delete_event", gtk.main_quit)

# player

        self.play_button = gtk.Button()
        self.slider = gtk.HScale()

        self.hbox = gtk.HBox()
        self.hbox.pack_start(self.play_button, False)
        self.hbox.pack_start(self.slider, True, True)

        self.play_button.set_image(self.PLAY_IMAGE)
        self.play_button.connect('clicked', self.the_method, "/home/px/scripts/beatnitpycker/preview.mp3")

        self.slider.set_range(0, 100)
        self.slider.set_increments(1, 10)
        self.slider.connect('value-changed', self.on_slider_change)

        self.playbin = gst.element_factory_make('playbin2')
        self.playbin.set_property('uri', 'file:////home/px/scripts/beatnitpycker/preview.mp3')

        self.bus = self.playbin.get_bus()
        self.bus.add_signal_watch()

        self.bus.connect("message::eos", self.on_finish)

        self.is_playing = False

# end player
# lister

        cell_data_funcs = (None, self.file_size, self.file_mode,
                           self.file_last_changed)

        listmodel = self.make_list(dname)

        # create the TreeView
        self.treeview = gtk.TreeView()

        # create the TreeViewColumns to display the data
        self.tvcolumn = [None] * len(self.column_names)
        cellpb = gtk.CellRendererPixbuf()
        self.tvcolumn[0] = gtk.TreeViewColumn(self.column_names[0], cellpb)
        self.tvcolumn[0].set_cell_data_func(cellpb, self.file_pixbuf)
        cell = gtk.CellRendererText()
        self.tvcolumn[0].pack_start(cell, False)
        self.tvcolumn[0].set_cell_data_func(cell, self.file_name)
        self.treeview.append_column(self.tvcolumn[0])
        for n in range(1, len(self.column_names)):
            cell = gtk.CellRendererText()
            self.tvcolumn[n] = gtk.TreeViewColumn(self.column_names[n], cell)
            if n == 1:
                cell.set_property('xalign', 1.0)
            self.tvcolumn[n].set_cell_data_func(cell, cell_data_funcs[n])
            self.treeview.append_column(self.tvcolumn[n])

        # self.treeview.connect('row-activated', self.open_file)
        self.treeview.set_model(listmodel)

# end lister

        vbox = gtk.VBox()

        self.button = gtk.Button() # THIS is the button to modify
        self.button.set_image(self.OPEN_IMAGE)

        # liststore = gtk.ListStore(str)
        # liststore.append(["foo"])
        # liststore.append(["bar"])
        # self.treeview = gtk.TreeView(liststore)
        # cell = gtk.CellRendererText()
        # col = gtk.TreeViewColumn("Column 1")
        # col.pack_start(cell, True)
        # col.set_attributes(cell,text=0)
        # self.treeview.append_column(col)

        vbox.pack_start(self.hbox, False, False, 1)
        vbox.pack_start(self.button, False, False, 1)
        vbox.pack_start(self.treeview, False, False, 1)

        self.treeview.connect('row-activated', self.the_other_wrapper, "plop")
        self.button.connect('clicked', self.the_method, "plop")

        self.window.add(vbox)
        self.window.show_all()
        return

    def ex_open_file(self, treeview, path, column):
        model = treeview.get_model()
        iter = model.get_iter(path)
        filename = os.path.join(self.dirname, model.get_value(iter, 0))
        filestat = os.stat(filename)
        if stat.S_ISDIR(filestat.st_mode):
            new_model = self.make_list(filename)
            treeview.set_model(new_model)
        else:
            self.the_method(self, filename)
            # Engine().load_file(filename)
        # return

    def the_other_wrapper(self, treeview, path, button, *args):
        model = treeview.get_model()
        iter = model.get_iter(path)
        filename = os.path.join(self.dirname, model.get_value(iter, 0))
        filestat = os.stat(filename)
        if stat.S_ISDIR(filestat.st_mode):
            new_model = self.make_list(filename)
            treeview.set_model(new_model)
        else:
            self.the_method(self, filename)
            # Engine().load_file(filename)

    def the_method_wrapper(self, button, filename, *args):
        self.the_method(self, filename)

    def loader(self, button, filename, *args):
        print "filename is", filename

    def the_method(self, button, filename):
        print filename
        # print vars(self)
        print self.playbin.get_property('uri')
        print self.playbin.get_state()
        print "------------------------"
        if not self.is_playing:
            self.playbin.set_state(gst.STATE_READY)
            print self.playbin.get_state()
            self.playbin.set_property('uri', 'file:///' + filename)
            self.play_button.set_image(self.PAUSE_IMAGE)
            self.is_playing = True

            self.playbin.set_state(gst.STATE_PLAYING)
            gobject.timeout_add(100, self.update_slider)

        else:
            self.play_button.set_image(self.PLAY_IMAGE)
            self.is_playing = False

            self.playbin.set_state(gst.STATE_PAUSED)

        # if self.toggled:
        #     self.button.set_image(self.CLOSED_IMAGE)
        #     self.toggled = False
        # else:
        #     self.button.set_image(self.OPEN_IMAGE)
        #     self.toggled = True

# Lister funcs

    def make_list(self, dname=None):
        if not dname:
            self.dirname = os.path.expanduser('~')
        else:
            self.dirname = os.path.abspath(dname)
        # self.window.set_title(self.dirname)
        files = [f for f in os.listdir(self.dirname) if f[0] != '.']
        files.sort()
        files = ['..'] + files
        listmodel = gtk.ListStore(object)
        for f in files:
            listmodel.append([f])
        return listmodel

    def open_file(self, treeview, path, column):
        model = treeview.get_model()
        iter = model.get_iter(path)
        filename = os.path.join(self.dirname, model.get_value(iter, 0))
        filestat = os.stat(filename)
        if stat.S_ISDIR(filestat.st_mode):
            new_model = self.make_list(filename)
            treeview.set_model(new_model)
        else:
            print "it's afile!"
            # self.buttonInstance.load_file(filename)
            # Engine().load_file(filename)
        # return

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

# player funcs
    def on_play(self, button):
        if not self.is_playing:
            self.play_button.set_image(self.PAUSE_IMAGE)
            self.is_playing = True

            self.playbin.set_state(gst.STATE_PLAYING)
            gobject.timeout_add(100, self.update_slider)

        else:
            self.play_button.set_image(self.PLAY_IMAGE)
            self.is_playing = False

            self.playbin.set_state(gst.STATE_PAUSED)

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

    def on_slider_change(self, slider):
        seek_time_secs = slider.get_value()
        self.playbin.seek_simple(gst.FORMAT_TIME, gst.SEEK_FLAG_FLUSH | gst.SEEK_FLAG_KEY_UNIT, seek_time_secs * gst.SECOND)

    def update_slider(self):
        if not self.is_playing:
            return False # cancel timeout
            print "nope"
        print "yep"

        try:
            nanosecs, format = self.playbin.query_position(gst.FORMAT_TIME)
            duration_nanosecs, format = self.playbin.query_duration(gst.FORMAT_TIME)

            # block seek handler so we don't seek when we set_value()
            self.slider.handler_block_by_func(self.on_slider_change)

            self.slider.set_range(0, float(duration_nanosecs) / gst.SECOND)
            self.slider.set_value(float(nanosecs) / gst.SECOND)

            self.slider.handler_unblock_by_func(self.on_slider_change)

            print nanosecs

        except gst.QueryError:
            # pipeline must not be ready and does not know position
         pass

        return True # continue calling every 30 milliseconds


def main():
    gtk.main()

if __name__ == "__main__":
    GUI()
    main()
