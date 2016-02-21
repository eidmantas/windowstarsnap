# Moded version of https://gist.github.com/breiter/536af352d561d34cdfab by @breiter 
# This can be ran as many times as needed, by just adding more dependencies in $package-dir
# Eid 2016/02/21
#
#
# directory where cygwin will be installed
$cygwinroot="C:\cygwin64"
# choose URL from  https://cygwin.com/mirrors.html
$mirror="http://www.mirrorservice.org/sites/sourceware.org/pub/cygwin/"
# packages to be installed on top of the base. Comma-separated, no spaces
$packages="cron,gcc-core,make,openssl,openssl-devel,zlib-devel,curl,bc,cygrunsrv,zip,unzip,openssl,openssh,nano"
 
 
# version of tarsnap to install
$tarsnapdist=(Invoke-WebRequest -uri https://www.tarsnap.com/download/ -UseBasicParsing).Content -split "`n" | 
        Select-String tarsnap-autoconf |
        Select-Object -last 1 |
        Foreach-Object { $_ -Replace "(<[^>]+>)|\s+", "" }
$unpackdir=$(New-Object IO.FileInfo ${tarsnapdist};).BaseName
$tarsnapver="tarsnap $([Regex]::Match($tarsnapdist, "\d+\.\d+\.\d+[a-z]?"))"
 
# note invoking cygwin installer or shell from powershell directly causes a hang
# that's why cygwin installer and shell are invoked with cmd
 
# create director if needed
if(-not (Test-Path $cygwinroot)) {
    $null = New-Item $cygwinroot -Type Directory
}
 
# download latest setup
Invoke-WebRequest -uri https://cygwin.com/setup-x86_64.exe -outfile "${cygwinroot}\setup-x86_64.exe"
 
# invoke unattended install/upgrade
cmd /c "${cygwinroot}\setup-x86_64.exe" --upgrade-also --quiet-mode --no-desktop --no-startmenu `
--packages $packages `
--local-package-dir $cygwinroot --root $cygwinroot `
--site $mirror
 
# set path to include cygwin
if(-not (write-output $env:path | select-string $cygwinroot.Replace("\","\\"))) {
    [Environment]::SetEnvironmentVariable("PATH", "$env:Path;$cygwinroot", [System.EnvironmentVariableTarget]::Machine)
}
 
# build and install tarsnap, if it is not present or outdated
if((-not (Test-Path "$cygwinroot\usr\local\bin\tarsnap.exe")) `
    -or $tarsnapver -ne (cmd /c "$cygwinroot\bin\sh.exe" -l -c "/usr/local/bin/tarsnap --version")) {
    $installtarsnap = "curl -O https://www.tarsnap.com/download/${tarsnapdist};" +
        "tar xzvf ${tarsnapdist};" +
        "cd ${unpackdir};" +
        "./configure && make && make install;" +
        "if [ ! -f '/usr/local/etc/tarsnap.conf' ]; then cp /usr/local/etc/tarsnap.conf.sample /usr/local/etc/tarsnap.conf; fi;" +
        "if [ ! -d '/root' ]; then mkdir /root; chmod 700 /root; fi;"
    cmd /c "$cygwinroot\bin\sh.exe" -l -c $installtarsnap
}
