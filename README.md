# mac-provision

Provision a new Mac and/or manage an existing one.

## TODO

- Add karabininer config (~/.config/karabiner/karabiner.json)

## PREREQUISITES

- git

## PROVISION

To provision a new Mac:

```
$ git clone git@github.com:ljohnston/mac-provision.git ~/.mac-provision
$ cd ~/.mac-provision
$ bin/provision
$ ansible-playbook -i playbooks/inventory playbooks/main.yml --ask-become-pass
```

## PRE- OR POST- PROVISION MANUAL UPDATES

Configure keyboard modifier keys:

Settings > Keyboard > Keyboard Shortcuts... > Modifier Keys

  - Caps Lock > Control
  - Control > Caps Lock

  May need to do this for multiple keyboards.

## POST-PROVISION MANUAL UPDATES

### iTerm

The mac-provision project includes config file for iTerm. It can't, however,
update the iTerm preference needed to read/write the config file. 

  iTerm > Settings > General > Settings
    - Check "Load preferences from a custom folder or URL"
    - Enter path as "~/.iterm"
    - Save changes: When Quitting

Keyboard shortcuts

  NOTE: If using the custom config file described above, these shortcuts
  should already be accounted for.

  - Map session paste history to Cmd-Ctrl-h (must map a "Select Menu Item...")
      Default is Cmd-Shift-h, which we need to remap so as not to collide with
      below mappings
  - Map split vertically with current profile to Cmd-Ctrl-l (must map via "Select Menu Item...") 
  - Map split horizontally with current profile to Cmd-Ctrl-j (must map via "Select Menu Item...") 
  - Map select pane above to Cmd-Shift-k
  - Map select pane below to Cmd-Shift-j
  - Map select pane left to Cmd-Shift-h
  - Map select pane right to Cmd-Shift-l

### Browsers

In all browsers, I use an _awesome_ extension called "surfingkeys", which
provides vim-like features inside the browser. There are a number of browser
customizations that can be made to improve the user experience when using 
surfingkeys. See comments in the .vim README for more info.

There are a number of non-surfingkeys related customizations, however, that I
like, described here.

#### Vivaldi

- Settings / General...
    - set Vivaldi as default browser
    - Homepage / Specific Page: google.com
    - Startup: Homepage
- Settings / Tabs...
    - New Tab Page: Homepage
- Settings / Downloads...
    - Uncheck "Display Downloads Automatically"
- Settings / Privacy & Security / Passwords: uncheck "Save Webpage Passwords"
- View / Customize Toolbar
    - Update as desired

## Maccy

- Open App / Preferences / General...
    - Launch at login
    - Check for updates automatically
    - Open: Ctrl-Cmd-\

## UPDATES

To modify configuration:

```
- Edit playbooks/base/tasks/main.yaml
$ ansible-playbook -i playbooks/inventory playbooks/main.yml --ask-become-pass
```
