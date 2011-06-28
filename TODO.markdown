
# Todo

## High priority

- some errors won't get better if we try again (e.g. permissions)
  - possibly, we should check sftp error codes more precisely
  - it's not a good thing to try to transfer possibly gigabyte files over and over again
- add code documentation (rdoc)
- add tests

## Low priority

- on daemon shutdown, the daemon should block until we are in a good state
- if mysql goes away, we have to recognize it and reconnect

