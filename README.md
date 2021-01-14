# mac-provision

Provision a new Mac and/or manage an existing one.

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

### POST-PROVISION MANUAL UPDATES

#### iTerm

The mac-provision project includes config file for iTerm. It can't, however,
update the iTerm preference needed to read/write the config file. 

  iTerm > Preferences > General > Preferences
    - Check "Load preferences from a custom folder or URL"
    - Enter path as "~/.iterm"
    - Check "Save changes to folder when iTerm2 quits"

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

#### Browsers

See comments in the .vim README for info.

## UPDATES

To modify configuration:

```
- Edit playbooks/base/tasks/main.yaml
$ ansible-playbook -i playbooks/inventory playbooks/main.yml --ask-become-pass
```
