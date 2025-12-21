{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    firefox
    brave
    librewolf
    tor-browser
  ];
}
