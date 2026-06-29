{ lib, pkgs, ... }:

with lib;

{
  home.packages = [
    pkgs.git-credential-manager
  ];

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      settings = {
        alias = {
          adog = "log --all --decorate --oneline --graph";
          filing = "commit --amend --signoff --no-edit --reset-author";
          poi = "commit --amend --no-edit";
          pouf = "push --force-with-lease";
          refiling = "rebase --exec 'git filing'";
          tape = "push --mirror";
        };
        advice.skippedCherryPicks = false;
        credential.helper = "manager";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase = {
          autostash = true;
          updateRefs = true;
        };
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        aliases = {
          ghstack =
            let
              ghstack = pkgs.writeShellScript "jj-ghstack" ''
                if [ -z "$1" ]; then
                  set -- "submit"
                fi
                if [ "$1" = "submit" ]; then
                  ${getExe pkgs.jujutsu} abandon -r 'stack() & nulls()'
                  ${getExe pkgs.jujutsu} rebase -d 'trunk()'
                fi
                ${getExe pkgs.ghstack} "$@"
              '';
            in
            [
              "util"
              "exec"
              "--"
              "${ghstack}"
            ];
          prune = [
            "abandon"
            "nulls()"
            "conflicts()"
          ];
          sync = [
            "git"
            "fetch"
            "--all-remotes"
          ];
          restack = [
            "rebase"
            "--onto"
            "trunk()"
            "--source"
            "roots(trunk()..) & mutable()"
          ];
        };
        git.private-commits = "description(glob:'secret:*')";
        templates = {
          commit_trailers = ''
            format_signed_off_by_trailer(self)
            ++ if(!trailers.contains_key("Change-Id"), format_gerrit_change_id_trailer(self))
          '';
          git_push_bookmark = "\"shikanime/push-\" ++ change_id.short()";
        };
        revset-aliases = {
          "nulls()" = "empty() & mutable()";
          "stack()" = "stack(@)";
          "stack(x)" = "stack(x, 2)";
          "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";
        };
        ui.default-command = "log";
      };
    };

    sapling = {
      enable = true;
      extraConfig = {
        committemplate = {
          emptymsg = "{if(title, title, defaulttitle)}\n\nSummary: {summary}\n\nFixes: {fixes}\n\nSigned-off-by: {author}";
          commit-message-fields = "Summary,Fixes,Signed-off-by";
        };

        hooks = {
          precommit.git-hooks = "test -f .git/hooks/pre-commit && .git/hooks/pre-commit || true";
          preoutgoing.git-hooks = "test -f .git/hooks/pre-push && .git/hooks/pre-push || true";
          update.git-hooks = "test -f .git/hooks/post-rewrite && .git/hooks/post-rewrite || true";
        };
      };
    };
  };
}
