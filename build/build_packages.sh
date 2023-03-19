#!/usr/bin/env bash

function whichPM() {
    local package_manager=''
    # Ubuntu, Debian and Linux mint
    if [ -n "$(command -v apt-get)" ] || [ -n "$(command -v apt)" ]; then
	    package_manager="sudo apt" 
    
    # CentOS, RHEL and Fedora
    elif [ -n "$(command -v yum)" ]; then
	    package_manager="sudo yum"
    elif [ -n "$(command -v dnf)" ]; then
	    package_manager="sudo dnf"
   
   # Arch Linux and Manjaro Systems
    elif [ -n "$(command -v pacman)" ]; then
	    package_manager="sudo pacman -S"
    # OpenSuse systems
    elif [ -n "$(command -v zypper)" ]; then
	    package_manager="sudo zypper"
    else 
      echo -e "Package manager not found (apt,yum,dnf,pacman or zypper)"
      exit 1;
    fi

    echo "$package_manager"
}

package_manager=$(whichPM)

# MacOS
# if [[ $OSTYPE == 'darwin'* ]]; then
#     brew install ruby ruby-build

# else 
#     $package_manager install ruby ruby-dev build-essential
# fi

# sudo gem install fpm

 # Especificar los nombres de los archivos de origen y configuración
script_name="ipharvest.sh"
config_file="fpm-config.json"

# Especificar el nombre y la versión del paquete
package_name="ipharvest"
package_version="1.0.0"
build_directory='.'

# Create build directory if not exists
[[ ! -d $build_directory ]] \
    && mkdir -p $build_directory

# Available packages to build with fpm
# apk, cpan, deb, dir, empty, freebsd, gem, npm, osxpkg, p5p, pacman, pear, pkgin, pleaserun, puppet, python, rpm, sh, snap, solaris, tar, virtualenv, zip

# Create installation package for MacOS
fpm -s dir -t osxpkg -n $package_name -v $package_version -C "$build_directory" --config-files $config_file $script_name

# Create installation package for Linux
fpm -s dir -t deb -n $package_name -v $package_version -C  "$build_directory" --config-files $config_file $script_name

# Create installation package for Windows
#fpm -s dir -t msi -n $package_name -v $package_version -C "$build_directory" --config-files $config_file $script_name
