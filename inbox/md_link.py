import os
import re
import sys
import shutil
import hashlib
import platform
import subprocess
import urllib.error
import urllib.request


if platform.system() == 'Linux':
    try:
        import gi  # TODO doesn't work on early Python 3 versions
        gi.require_version('Gtk', '3.0')
        from gi.repository import Gio, Gtk
    except ImportError:
        pass


class URL:
    def __init__(self, url, folder_dir_path):
        """
        :param url: http(s)://...
        :param folder_dir_path: full absolute path to the note folder, to know where media folder is
        """
        self.url = url.strip()
        self.folder_dir_path = folder_dir_path

    @property
    def icon(self):
        """
        Get URL favicon from google's service
        :return: full absolute path to favicon image this function saved to media/favicons or nothing
        """
        try:
            favicon = urllib.request.urlopen('http://www.google.com/s2/favicons?domain=' + self.url, timeout=5)
        except (urllib.error.HTTPError, urllib.error.URLError):
            return

        favicon_content = favicon.read()
        favicon_hash = hashlib.md5(favicon_content).hexdigest()

        if favicon_hash == '3ca64f83fdcf25135d87e08af65e68c9':  # google's dummy icon
            return
        else:
            favicon_dir_path = self.folder_dir_path + os.sep + 'media' + os.sep + 'favicons'
            os.makedirs(favicon_dir_path, exist_ok=True)
            favicon_path = favicon_dir_path + os.sep + favicon_hash + '.png'
            if not os.path.isfile(favicon_path):
                with open(favicon_path, 'wb') as favicon_file:
                    favicon_file.write(favicon_content)
            return favicon_path

    @property
    def title(self):
        """
        Try to parse title from the web page located at URL
        :return: web page title for URL or nothing
        """
        try:
            html_text = urllib.request.urlopen(self.url).read().decode('utf-8')  # TODO encodings other that utf-8, https fails on early Python 3 versions
        except (urllib.error.HTTPError, urllib.error.URLError, UnicodeDecodeError):
            title = ''
        else:
            title = re.search('<title.*?>(.+?)</title>', html_text, re.IGNORECASE | re.DOTALL).group(1)

        if title:
            return title
        else:
            return self.url.split('//')[-1].split('/')[0]

    @property
    def md(self):
        """
        Get the most informative markdown syntax link for URL, with favicon and title if available
        :return: Markdown syntax link for URL
        """
        if self.icon:
            md_favicon = '![](file://media/favicons/{}) '.format(os.path.basename(self.icon))
        else:
            md_favicon = ''

        if self.title:
            md_link = '[{}]({})'.format(self.title, self.url)
        else:
            md_link = '<{}>'.format(self.url)

        return md_favicon + md_link


class File:
    def __init__(self, link_path, folder_dir_path, title=''):
        """
        :param link_path: full absolute path to the file
        :param folder_dir_path: full absolute path to the note folder, to know where media folder is
        :param title: optionally specify the file's title, otherwise file name will be used as such
        """
        self.path = link_path.strip()
        self.folder_dir_path = folder_dir_path
        self.filename = os.path.basename(self.path)
        self.ext = os.path.splitext(self.filename)[1]

        if self.ext == '.pdf':
            self.type = 'pdf'
        elif self.ext in ('.jpg', '.png', '.gif'):
            self.type = 'image'
        else:
            self.type = 'other'

        if title:
            self.title = title
        else:
            self.title = os.path.splitext(self.filename)[0]

    @property
    def icon(self, icon_size=16, save=True):
        """
        Get file type icon for File
        :param icon_size: requested icon size
        :param save: True to copy icon to media flder, otherwise will return path where OS stores the icon
        :return: full absolute path to File icon or nothing
        """
        if platform.system() == 'Linux':
            try:
                file = Gio.File.new_for_path(self.path)

                file_info = file.query_info('standard::icon', 0, Gio.Cancellable())
                file_icon = file_info.get_icon().get_names()[0]

                icon_theme = Gtk.IconTheme.get_default()
                icon_info = icon_theme.lookup_icon(file_icon, icon_size, 0)
                icon_path = icon_info.get_filename()
            except (NameError, AttributeError):
                return ''

            if os.path.isfile(icon_path):
                if save:
                    icon_store_path = os.path.join(self.folder_dir_path, 'media', 'fileicons')
                    if not os.path.isfile(icon_store_path + os.sep + os.path.basename(icon_path)):
                        try:
                            os.makedirs(icon_store_path, exist_ok=True)
                            icon_path = shutil.copy(icon_path, icon_store_path)
                            icon_path = 'media/fileicons/' + os.path.basename(icon_path)
                        except OSError:
                            pass

                return icon_path

    @property
    def thumb(self):
        """
        Make a thumbnail for appropriate File
        :return: full absolute path to File's thumbnail or nothing
        """
        if self.type == 'pdf':
            if platform.system() == 'Linux':
                dpi = 30
                thumb_path = os.path.join(self.folder_dir_path, 'media', 'thumbnails', 'th_' + self.filename + '.png')
                os.makedirs(os.path.dirname(thumb_path), exist_ok=True)

                subprocess.call(['gs', '-q', '-dNOPAUSE', '-dBATCH', '-sDEVICE=png16m', '-r' + str(dpi),
                                 '-sOutputFile=' + thumb_path, '-dLastPage=1', self.path],
                                timeout=10)

                if os.path.isfile(thumb_path):
                    return thumb_path

        if self.type == 'image':
            if platform.system() == 'Linux':
                target_width = 600
                img_width = int(subprocess.check_output(['identify', '-ping', '-format', '%w', self.path],
                                                        timeout=5).decode(sys.stdout.encoding))
                if img_width > target_width:
                    thumb_path = os.path.join(self.folder_dir_path, 'media', 'thumbnails', 'th_' + self.filename)
                    os.makedirs(os.path.dirname(thumb_path), exist_ok=True)

                    subprocess.call(['convert', self.path, '-thumbnail', str(target_width),
                                     '-auto-orient', '-unsharp', '0x.5', thumb_path],
                                    timeout=10)

                    if os.path.isfile(thumb_path):
                        return thumb_path

    @property
    def md(self):
        """
        Get the most informative markdown syntax link for File, as a thumbnail or with file icon if available
        :return: Markdown syntax link for File
        """
        link_path = os.path.relpath(self.path, self.folder_dir_path).replace(os.sep, '/')
        thumb = self.thumb
        if thumb:
            return '[![{}](file://{})](file://{})'.format(self.title, 'media/thumbnails/' + os.path.basename(thumb), link_path)
        elif self.type == 'image':
            return '![{}](file://{})'.format(self.title, link_path)
        else:
            icon = self.icon
            if icon:
                return '![](file://{})'.format('media/fileicons/' + os.path.basename(self.icon)) + ' ' + \
                       '[{}](file://{})'.format(self.title, link_path)
            else:
                return '[{}](file://{})'.format(self.title, link_path)