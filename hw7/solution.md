# Homework 7 - Packaging

## Task

Build RPM package, then create RPM repo and publish the package there (localy, using **nginx**)

## Prerequisites

OS: **Ubuntu 24.04**

## Solution

### 0. Create simple example project

It contains only one file `hello.sh` with contents:

```sh
#!/usr/bin/env bash
echo "Hello, I am inside RPM package!"
```

After that, post it on [GitHub](https://github.com/giveuper39/rpm-example)

### 1. Install required packages

```bash
❯ sudo apt install -y wget git rpm createrepo-c nginx \
               build-essential libtool automake autoconf \
               make cmake pkg-config dnf
```

### 2. Manually create rpmbuild directories

```bash
❯ mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
```

### 3. Clone the project and copy it to sources

```bash
❯ git clone https://github.com/giveuper39/rpm-example
Cloning into 'rpm-example'...
remote: Enumerating objects: 8, done.
remote: Counting objects: 100% (8/8), done.
remote: Compressing objects: 100% (7/7), done.
remote: Total 8 (delta 1), reused 3 (delta 0), pack-reused 0 (from 0)
Receiving objects: 100% (8/8), 6.60 KiB | 6.60 MiB/s, done.
Resolving deltas: 100% (1/1), done.
```

```bash
❯ cd ~/rpmbuild/SOURCES
❯ cp -r ~/rpm-example .
❯ tar -czf rpm-example-1.0.tar.gz rpm-example
❯ rm -rf rpm-example
```

### 4. Create .spec file for package

```bash
❯ cd ../SPECS
❯ nvim rpm-example.spec
```


```bash
> rpm-example.spec

Name:           rpm-example
Version:        1.0
Release:        1%{?dist}
Summary:        RPM package example
License:        Apache-2.0
URL:            https://github.com/giveuper39/rpm-example
Source0:        %{name}-%{version}.tar.gz
AutoReqProv:    no
AutoReq:        no  # dnf in ubuntu doesn't really like '#!/usr/bin/env bash'
BuildArch:      noarch

%description
This package is a test RPM package with one script

%prep
%setup -q -n rpm-example

%install
mkdir -p %{buildroot}/usr/local/bin
chmod +x hello.sh
cp -p hello.sh %{buildroot}/usr/local/bin/rpm-example

%files
/usr/local/bin/rpm-example
```

### 5. Build rpm package

```bash
❯ rpmbuild -ba rpm-example.spec
Executing(%prep): /bin/sh -e /var/tmp/rpm-tmp.O4Kl7B
+ umask 022
+ cd /home/giveuper39/rpmbuild/BUILD
+ cd /home/giveuper39/rpmbuild/BUILD
+ rm -rf rpm-example
+ /usr/lib/rpm/rpmuncompress -x /home/giveuper39/rpmbuild/SOURCES/rpm-example-1.0.tar.gz
+ STATUS=0
+ [ 0 -ne 0 ]
+ cd rpm-example
+ /bin/chmod -Rf a+rX,u+w,g-w,o-w .
+ RPM_EC=0
+ jobs -p
+ exit 0
Executing(%install): /bin/sh -e /var/tmp/rpm-tmp.IoNMRJ
+ umask 022
+ cd /home/giveuper39/rpmbuild/BUILD
+ /bin/rm -rf /home/giveuper39/rpmbuild/BUILDROOT/rpm-example-1.0-1.x86_64
+ /bin/mkdir -p /home/giveuper39/rpmbuild/BUILDROOT
+ /bin/mkdir /home/giveuper39/rpmbuild/BUILDROOT/rpm-example-1.0-1.x86_64
+ cd rpm-example
+ mkdir -p /home/giveuper39/rpmbuild/BUILDROOT/rpm-example-1.0-1.x86_64/usr/local/bin
+ chmod +x hello.sh
+ cp -p hello.sh /home/giveuper39/rpmbuild/BUILDROOT/rpm-example-1.0-1.x86_64/usr/local/bin/rpm-example
+ /usr/lib/rpm/brp-compress /usr
+ /usr/lib/rpm/brp-elfperms
+ /usr/lib/rpm/brp-strip /usr/bin/strip
+ /usr/lib/rpm/brp-strip-static-archive /usr/bin/strip
+ /usr/lib/rpm/brp-strip-comment-note /usr/bin/strip /usr/bin/objdump
+ /usr/lib/rpm/brp-remove-la-files
Processing files: rpm-example-1.0-1.noarch
Provides: rpm-example = 1.0-1
Requires(rpmlib): rpmlib(CompressedFileNames) <= 3.0.4-1 rpmlib(FileDigests) <= 4.6.0-1 rpmlib(PayloadFilesHavePrefix) <= 4.0-1
Checking for unpackaged file(s): /usr/lib/rpm/check-files /home/giveuper39/rpmbuild/BUILDROOT/rpm-example-1.0-1.x86_64
Wrote: /home/giveuper39/rpmbuild/SRPMS/rpm-example-1.0-1.src.rpm
Wrote: /home/giveuper39/rpmbuild/RPMS/noarch/rpm-example-1.0-1.noarch.rpm
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.75jt3F
+ umask 022
+ cd /home/giveuper39/rpmbuild/BUILD
+ cd rpm-example
+ /bin/rm -rf /home/giveuper39/rpmbuild/BUILDROOT/rpm-example-1.0-1.x86_64
+ RPM_EC=0
+ jobs -p
+ exit 0
Executing(rmbuild): /bin/sh -e /var/tmp/rpm-tmp.2dXIuP
+ umask 022
+ cd /home/giveuper39/rpmbuild/BUILD
+ rm -rf rpm-example rpm-example.gemspec
+ RPM_EC=0
+ jobs -p
+ exit 0

❯ ls -l ../RPMS/noarch
   rw-r--r--   1   giveuper39   giveuper39      6 KiB   Tue Jun  9 20:05:24 2026    rpm-example-1.0-1.noarch.rpm
```

### 6. Create local RPM repo using nginx and createrepo_c (Ubuntu version)

```bash
❯ sudo mkdir -p /var/www/html/repo
❯ sudo cp ~/rpmbuild/RPMS/noarch/*.rpm /var/www/html/repo/
❯ sudo createrepo_c /var/www/html/repo
Directory walk started
Directory walk done - 1 packages
Temporary output repo path: /var/www/html/repo/.repodata/
Preparing sqlite DBs
Pool started (with 5 workers)
Pool finished
❯ sudo nvim /etc/nginx/sites-available/default
    # add 'autoindex on;'
    # change server port to 8081 (80 is taken): 'listen 8081 default_server;'
❯ sudo nginx -s reload

❯ curl -a http://localhost:8081/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          09-Jun-2026 17:11                   -
<a href="rpm-example-1.0-1.noarch.rpm">rpm-example-1.0-1.noarch.rpm</a>                       09-Jun-2026 17:10                6466
</pre><hr></body>
</html>
```

### 7. Add this repo to yum (dnf) repo list and check its availability

```bash
❯ sudo mkdir -p /etc/yum.repos.d
❯ sudo tee /etc/yum.repos.d/otus.repo << EOF
[otus]
name=RPM Example Repo
baseurl=http://localhost:8081/repo
gpgcheck=0
enabled=1
EOF
❯ dnf makecache
RPM Example Repo                                                                                                                        99 kB/s | 896  B     00:00
Metadata cache created.
❯ dnf repolist enabled
repo id                                                                        repo name
otus                                                                           RPM Example Repo
❯ dnf list available
Available Packages
rpm-example.noarch                                                                      1.0-1                                                                      otus
```

### 8. Install the package from repo and run executable

```bash
❯ sudo dnf install -y rpm-example
Dependencies resolved.
=======================================================================================================================================================================
 Package                                     Architecture                           Version                                 Repository                            Size
=======================================================================================================================================================================
Installing:
 rpm-example                                 noarch                                 1.0-1                                   otus                                 6.2 k

Transaction Summary
=======================================================================================================================================================================
Install  1 Package

Total download size: 6.2 k
Installed size: 59
Downloading Packages:
rpm-example-1.0-1.noarch.rpm                                                                                                           1.5 MB/s | 6.2 kB     00:00
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                  623 kB/s | 6.2 kB     00:00
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                               1/1
  Installing       : rpm-example-1.0-1.noarch                                                                                                                      1/1
  Verifying        : rpm-example-1.0-1.noarch                                                                                                                      1/1

Installed:
  rpm-example-1.0-1.noarch

Complete!

❯ rpm-example
Hello, I am inside RPM package!
```
