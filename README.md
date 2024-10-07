# QQ Installation Guide

## Installation

To install the `qq` tool on your system, simply run the following command in your terminal:

```bash
curl -sL https://github.com/ArturUshakov/qq/raw/master/install.sh | sudo bash
```

This command will download and execute the installation script directly from the repository.

## Usage

Once the installation is complete, you can use the `qq` command to start the application:

```bash
qq
```

This will launch the application as configured during the installation process.

## Uninstallation

If you ever need to remove the `qq` tool, simply delete the installation directory and remove the alias from your shell configuration files:

```bash
rm -rf ~/qq
sed -i '/alias qq=/d' ~/.bashrc ~/.bash_aliases
```

After that, reload your shell:

```bash
source ~/.bashrc
```

Now, `qq` will no longer be available as a command.