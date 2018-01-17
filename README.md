# mac-provision

Provision a new Mac and/or manage an existing one.

## PREREQUISITES

None.

## PROVISION

To provision a new Mac:

```
$ git clone git@github.com:ljohnston/mac-provision.git ~/.mac-provision
$ cd ~/.mac-provision
$ bin/provision
$ ansible-playbook -i playbooks/inventory playbooks/main.yml
```

####  MANUAL UPDATES

##### iTerm

- Map session paste history to Cmd-Ctrl-h (must map a "Select Menu Item...")
    Default is Cmd-Shift-h, which we need to remap so as not to collide with
    below mappings
- Map split vertically with current profile to Cmd-Ctrl-l (must map a "Select Menu Item...") 
- Map split horizontally with current profile to Cmd-Ctrl-j (must map a "Select Menu Item...") 
- Map select pane above to Cmd-Shift-k
- Map select pane below to Cmd-Shift-j
- Map select pane left to Cmd-Shift-h
- Map select pane right to Cmd-Shift-l

## UPDATES

To modify configuration:

```
- Edit playbooks/base/tasks/main.yaml
$ ansible-playbook -i playbooks/inventory playbooks/main.yml
```
