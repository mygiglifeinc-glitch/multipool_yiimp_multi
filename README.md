# multipool_yiimp_multi
Installation files for YiiMP multi server

#### These files do nothing on their own please go to https://github.com/mygiglifeinc-glitch/Multi-Pool-Installer

Supported operating systems: Ubuntu 22.04, 24.04 and 26.04 LTS (x86_64), on every server of the pool.

## How it works

The installer is started on the server that will host the database. It asks all
questions up front, installs the DB (or DB + stratum) server locally and then
installs the web, stratum and daemon servers over SSH:

* each server is logged in to once; the connection is reused for every step, the
  password is never written to disk or passed on a command line, and host keys are
  checked (`StrictHostKeyChecking=accept-new`, stored in `~/.ssh/multipool_known_hosts`);
* the remote user needs password-less sudo (the multipool user setup configures it;
  otherwise the installer adds it with the password you entered);
* files are copied to a private temporary directory on each server that is removed
  when that server is done, and each server only receives the settings it needs
  (no SSH or database root passwords).

The database accounts may only connect from the web/stratum server that uses them,
MariaDB listens on the private IP only and the firewall (ufw) of every server only
allows SSH, what the server role needs publicly and traffic from the other pool
servers. Without provider private IPs, install the WireGuard network first (menu
option 1).

## Install-time overrides

| Variable | Default | Purpose |
|:--|:--|:--|
| `YIIMP_REPO` | `https://github.com/mygiglifeinc-glitch/yiimp.git` | YiiMP source repository |
| `YIIMP_BRANCH` | repository default (`multi-port` with dedicated coin ports) | YiiMP branch or tag |
| `DISABLE_FIREWALL` | unset | Set to `1` to skip the ufw configuration |

## Stratum servers

* `stratum start|stop|restart algo` starts or stops the stratum of an algo.
* `addport` creates a dedicated port stratum for a coin. `addport_multi` does the
  same and also updates the stratum servers listed, one `user@private_ip` per line,
  in `$STORAGE_ROOT/yiimp/.remote_stratums.conf` (SSH asks for each password
  unless you use SSH keys).
