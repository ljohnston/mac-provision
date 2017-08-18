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

Done.

## UPDATES

To modify configuration:

```
- Edit playbooks/base/tasks/main.yaml
$ ansible-playbook -i playbooks/inventory playbooks/main.yml
```
