{
  programs.helix = {
    defaultEditor = true;
    enable = true;
    settings = {
      editor = {
        color-modes = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        cursorline = true;
        indent-guides.render = true;
        line-number = "relative";
      };
      theme = "catppuccin_latte";
    };
    themes.catppuccin_latte = {
      attribute = "yellow";
      comment = {
        fg = "overlay2";
        modifiers = [ "italic" ];
      };
      constant = "peach";
      "constant.character" = "teal";
      "constant.character.escape" = "pink";
      constructor = "sapphire";
      "diagnostic.error" = {
        underline = {
          color = "red";
          style = "curl";
        };
      };
      "diagnostic.hint" = {
        underline = {
          color = "teal";
          style = "curl";
        };
      };
      "diagnostic.info" = {
        underline = {
          color = "sky";
          style = "curl";
        };
      };
      "diagnostic.unnecessary" = {
        modifiers = [ "dim" ];
      };
      "diagnostic.warning" = {
        underline = {
          color = "yellow";
          style = "curl";
        };
      };
      "diff.delta" = "blue";
      "diff.minus" = "red";
      "diff.plus" = "green";
      error = "red";
      function = "blue";
      "function.macro" = "mauve";
      hint = "teal";
      info = "sky";
      keyword = "mauve";
      "keyword.control.conditional" = {
        fg = "mauve";
        modifiers = [ "italic" ];
      };
      label = "sapphire";
      "markup.bold" = {
        fg = "red";
        modifiers = [ "bold" ];
      };
      "markup.heading.1" = "red";
      "markup.heading.2" = "peach";
      "markup.heading.3" = "yellow";
      "markup.heading.4" = "green";
      "markup.heading.5" = "blue";
      "markup.heading.6" = "mauve";
      "markup.italic" = {
        fg = "red";
        modifiers = [ "italic" ];
      };
      "markup.link.text" = "lavender";
      "markup.link.url" = {
        fg = "blue";
        modifiers = [
          "italic"
          "underlined"
        ];
      };
      "markup.list" = "teal";
      "markup.list.checked" = "green";
      "markup.list.unchecked" = "overlay2";
      "markup.quote" = "pink";
      "markup.raw" = "green";
      namespace = {
        fg = "yellow";
        modifiers = [ "italic" ];
      };
      operator = "sky";
      palette = {
        base = "#eff1f5";
        blue = "#1e66f5";
        crust = "#dce0e8";
        cursorline = "#e8ecf1";
        flamingo = "#dd7878";
        green = "#40a02b";
        lavender = "#7287fd";
        mantle = "#e6e9ef";
        maroon = "#e64553";
        mauve = "#8839ef";
        overlay0 = "#9ca0b0";
        overlay1 = "#8c8fa1";
        overlay2 = "#7c7f93";
        peach = "#fe640b";
        pink = "#ea76cb";
        red = "#d20f39";
        rosewater = "#dc8a78";
        sapphire = "#209fb5";
        secondary_cursor = "#e1a99d";
        secondary_cursor_insert = "#74b867";
        secondary_cursor_normal = "#e1a99d";
        sky = "#04a5e5";
        subtext0 = "#6c6f85";
        subtext1 = "#5c5f77";
        surface0 = "#ccd0da";
        surface1 = "#bcc0cc";
        surface2 = "#acb0be";
        teal = "#179299";
        text = "#4c4f69";
        yellow = "#df8e1d";
      };
      punctuation = "overlay2";
      "punctuation.special" = "sky";
      special = "blue";
      string = "green";
      "string.regexp" = "pink";
      "string.special" = "blue";
      "string.special.symbol" = "red";
      tag = "blue";
      type = "yellow";
      "type.enum.variant" = "teal";
      "ui.background" = {
        bg = "base";
        fg = "text";
      };
      "ui.bufferline" = {
        bg = "mantle";
        fg = "subtext0";
      };
      "ui.bufferline.active" = {
        bg = "base";
        fg = "mauve";
        underline = {
          color = "mauve";
          style = "line";
        };
      };
      "ui.bufferline.background".bg = "crust";
      "ui.cursor" = {
        bg = "secondary_cursor";
        fg = "base";
      };
      "ui.cursor.insert" = {
        bg = "secondary_cursor_insert";
        fg = "base";
      };
      "ui.cursor.match" = {
        fg = "peach";
        modifiers = [ "bold" ];
      };
      "ui.cursor.normal" = {
        bg = "secondary_cursor_normal";
        fg = "base";
      };
      "ui.cursor.primary" = {
        bg = "rosewater";
        fg = "base";
      };
      "ui.cursor.primary.insert" = {
        bg = "green";
        fg = "base";
      };
      "ui.cursor.primary.normal" = {
        bg = "rosewater";
        fg = "base";
      };
      "ui.cursor.primary.select" = {
        bg = "flamingo";
        fg = "base";
      };
      "ui.cursor.select" = {
        bg = "secondary_cursor";
        fg = "base";
      };
      "ui.cursorline.primary".bg = "cursorline";
      "ui.help" = {
        bg = "surface0";
        fg = "overlay2";
      };
      "ui.highlight" = {
        bg = "surface1";
        modifiers = [ "bold" ];
      };
      "ui.linenr".fg = "surface1";
      "ui.linenr.selected".fg = "lavender";
      "ui.menu" = {
        bg = "surface0";
        fg = "overlay2";
      };
      "ui.menu.selected" = {
        bg = "surface1";
        fg = "text";
        modifiers = [ "bold" ];
      };
      "ui.popup" = {
        bg = "surface0";
        fg = "text";
      };
      "ui.selection".bg = "surface1";
      "ui.statusline" = {
        bg = "mantle";
        fg = "subtext1";
      };
      "ui.statusline.inactive" = {
        bg = "mantle";
        fg = "surface2";
      };
      "ui.statusline.insert" = {
        bg = "green";
        fg = "base";
        modifiers = [ "bold" ];
      };
      "ui.statusline.normal" = {
        bg = "lavender";
        fg = "base";
        modifiers = [ "bold" ];
      };
      "ui.statusline.select" = {
        bg = "flamingo";
        fg = "base";
        modifiers = [ "bold" ];
      };
      "ui.text" = "text";
      "ui.text.directory".fg = "blue";
      "ui.text.focus" = {
        bg = "surface0";
        fg = "text";
        modifiers = [ "bold" ];
      };
      "ui.text.inactive".fg = "overlay1";
      "ui.virtual" = "overlay0";
      "ui.virtual.indent-guide" = "surface0";
      "ui.virtual.inlay-hint" = {
        bg = "mantle";
        fg = "surface1";
      };
      "ui.virtual.jump-label" = {
        fg = "rosewater";
        modifiers = [ "bold" ];
      };
      "ui.virtual.ruler".bg = "surface0";
      "ui.window".fg = "crust";
      variable = "text";
      "variable.builtin" = "red";
      "variable.other.member" = "blue";
      "variable.parameter" = {
        fg = "maroon";
        modifiers = [ "italic" ];
      };
      warning = "yellow";
    };
  };
}
