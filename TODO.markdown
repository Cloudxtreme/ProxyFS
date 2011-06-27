
# Todo

- handle errors during a write better
  - make write_to completly atomic somewhow
    - our Net::SFTP.mv! implementation has to become atomic (currently: remove and rename)
  - the transaction should enforce stronger guarantees
- some errors won't get better if we try again (e.g. permissions)
  - possibly, we should check sftp error codes more precisely
- add code documentation (rdoc)
- add tests

