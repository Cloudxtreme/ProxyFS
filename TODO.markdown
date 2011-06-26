
# Todo

- handle errors during a write better
  - possibly, parts of the file have been transmitted and stay wrong on the remote side
  - the transaction should enforce stronger guarantees
- some errors won't get better if we try again (e.g. permissions)
  - possibly, we should check sftp error codes more precisely
- add code documentation (rdoc)
- add tests

