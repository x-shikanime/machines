{
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release
  home.stateVersion = "26.05";

  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
