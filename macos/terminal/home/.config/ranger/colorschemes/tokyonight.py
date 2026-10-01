from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import (
    black, blue, cyan, green, magenta, red, white, yellow, default,
    normal, bold, reverse, dim, BRIGHT,
    default_colors,
)


class TokyoNight(ColorScheme):
    progress_bar_color = blue

    def use(self, context):
        fg, bg, attr = default_colors

        if context.reset:
            return default_colors

        elif context.in_browser:
            if context.selected:
                attr = reverse
            if context.empty or context.error:
                fg = red
                attr |= bold
            if context.border:
                fg = default
            if context.media:
                if context.image:
                    fg = yellow
                elif context.video:
                    fg = magenta
                elif context.audio:
                    fg = cyan
                else:
                    fg = magenta
            if context.container:
                fg = red
            if context.directory:
                fg = blue
                attr |= bold
            elif context.executable and not any(
                (context.media, context.container, context.fifo, context.socket)
            ):
                fg = green
                attr |= bold
            if context.socket:
                fg = magenta
                attr |= bold
            if context.fifo or context.device:
                fg = yellow
                if context.device:
                    attr |= bold
            if context.link:
                fg = cyan if context.good else red
            if context.tag_marker and not context.selected:
                attr |= bold
                fg = red
            if not context.selected and (context.cut or context.copied):
                attr |= bold
                fg = black
                bg = default
            if context.main_column:
                if context.selected:
                    attr |= bold
                if context.marked:
                    attr |= bold
                    fg = yellow
            if context.badinfo:
                if attr & reverse:
                    bg = magenta
                else:
                    fg = magenta
            if context.inactive_pane:
                fg = default

        elif context.in_titlebar:
            if context.hostname:
                fg = red if context.bad else blue
            elif context.directory:
                fg = blue
                attr |= bold
            elif context.tab:
                if context.good:
                    fg = blue
                    attr |= bold
            elif context.link:
                fg = cyan

        elif context.in_statusbar:
            if context.permissions:
                if context.good:
                    fg = green
                elif context.bad:
                    fg = red
            if context.marked:
                attr |= bold | reverse
                fg = yellow
            if context.frozen:
                attr |= bold | reverse
                fg = cyan
            if context.message:
                if context.bad:
                    attr |= bold
                    fg = red
            if context.loaded:
                bg = self.progress_bar_color
            if context.vcsinfo:
                fg = cyan
                attr &= ~bold
            if context.vcscommit:
                fg = yellow
                attr &= ~bold
            if context.vcsdate:
                fg = cyan
                attr &= ~bold

        if context.text:
            if context.highlight:
                attr |= reverse

        if context.in_taskview:
            if context.title:
                fg = blue
            if context.selected:
                attr |= reverse
            if context.loaded:
                if context.selected:
                    fg = self.progress_bar_color
                else:
                    bg = self.progress_bar_color

        return fg, bg, attr
