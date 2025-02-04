## System-wide dependencies

### Debian, Ubuntu, etc:
```
libcurl4-openssl-dev
libxml2-dev 
libfontconfig1-dev 
libcurl4-openssl-dev
libxml2-dev
libharfbuzz-dev
libfribidi-dev
libfreetype6-dev
libpng-dev
libtiff5-dev
libjpeg-dev
```

```bash
# install with apt
sudo apt install libcurl4-openssl-dev libxml2-dev libfontconfig1-dev libcurl4-openssl-dev libxml2-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev

```

### Fedora, CentOS, RHEL:
```
libcurl-devel
libxml2-devel
fontconfig-devel
harfbuzz-devel
fribidi-devel
freetype-devel
libpng-devel
libtiff-devel
libjpeg-devel
```

```bash
# install with yum
sudo yum install libcurl-devel libxml2-devel fontconfig-devel harfbuzz-devel fribidi-devel freetype-devel libpng-devel libtiff-devel libjpeg-devel

```

### Installing ProToDeviseR system-wide, for all users
If you want to install ProToDeviseR system-wide (not for your current user in ~/), for example to make a distribution-specific package, make sure that the `pfam` subfolder (exact path would depend on your distribution) is writeable by all, e.g.:

```
# owner still should be root
chown root:root /usr/lib/R/library/protodeviser/webApp/www/pfam/

# make it possible for everyone to read/write:
chmod 777 /usr/lib/R/library/protodeviser/webApp/www/pfam/
```

### Installing on CRUX
I use [CRUX](https://crux.nu/) distribution of GNU/Linux. Installing **ProToDeviser** there is quite straightforward.

* the `contrib` ports collection should to be enabled ([Point 6.2.5 from the Handbook](https://crux.nu/Main/Handbook3-7#ntoc60)).
* grab my ports repository HttpUp file ([r4-modules.httpup](https://raw.githubusercontent.com/slackalaxy/crux-ports/main/r4-modules/r4-modules.httpup)) and Public key ([r4-modules.pub](https://raw.githubusercontent.com/slackalaxy/crux-ports/main/r4-modules/r4-modules.pub)) and place them in `/etc/ports`. Then just sync the ports collections and install what's needed:
```bash
ports -u
prt-get depinst r4-protodeviser
```
