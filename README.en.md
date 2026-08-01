<p align="center">
  <a href="README.md">🇮🇷 فارسی</a> ·
  <strong>🇬🇧 English</strong> ·
  <a href="README.ru.md">🇷🇺 Русский</a> ·
  <a href="README.zh.md">🇨🇳 中文</a>
</p>

# PasarGuard Neon Template

## Quick install from GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/7Berlin/pasarguard-neon-template/main/install.sh | sudo bash -s -- --activate
```

This command installs and activates the template with **Persian only**.

![English template preview](assets/preview.webp)

## Install commands

| Command | Description |
|---|---|
| `sudo bash install.sh --activate` | Install with Persian as the default language |
| `sudo bash install.sh --activate -fa -en` | Install Persian and English; Persian is default |
| `sudo bash install.sh --activate -en -ru --default-lang en` | Install English and Russian; English is default |
| `sudo bash install.sh --activate -fa -en -ru -zh` | Install all languages |
| `sudo bash install.sh --activate --config ./template.conf` | Install with a custom configuration file |

| Flag | Language |
|---|---|
| `-fa` | 🇮🇷 Persian |
| `-en` | 🇬🇧 English |
| `-ru` | 🇷🇺 Russian |
| `-zh` | 🇨🇳 Chinese |

## Configure the template

Edit `template.conf`, then run the installer again:

```bash
git clone https://github.com/7Berlin/pasarguard-neon-template.git
cd pasarguard-neon-template
nano template.conf
sudo bash install.sh --activate --config ./template.conf
```

| Option | Purpose |
|---|---|
| `BRAND_NAME` | Service name |
| `BRAND_SUBTITLE` | Text below the user name |
| `AVATAR_URL` | Public profile image or logo URL |
| `AVATAR_FILE` | Local PNG, JPG, WEBP, GIF, or SVG file |
| `PRIMARY_COLOR` | Primary color |
| `SECONDARY_COLOR` | Secondary color |
| `CYAN_COLOR` | Accent color |
| `DEFAULT_THEME` | `dark` or `light` theme |
| `SUPPORT_URL` | Guide or support URL |
| `PANEL_DOMAIN` | Panel domain when required |

Support the project by giving it a GitHub star ⭐
