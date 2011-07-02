
# Todo

## High priority

- add code documentation (rdoc)
- add tests

## Low priority

- on daemon shutdown, the daemon should block until we are in a good state
  - install a signal trap handler and sychronize a mutex, then exit

<pre>
trap("SIGTERM") do
  mutex.synchronize
    exit
  end
end
</pre>

- if mysql goes away, we have to recognize it and reconnect

