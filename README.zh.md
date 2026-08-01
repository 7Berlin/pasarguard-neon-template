<p align="center">
  <a href="README.md">🇮🇷 فارسی</a> ·
  <a href="README.en.md">🇬🇧 English</a> ·
  <a href="README.ru.md">🇷🇺 Русский</a> ·
  <strong>🇨🇳 中文</strong>
</p>

# PasarGuard 霓虹订阅模板

## 从 GitHub 快速安装

```bash
curl -fsSL https://raw.githubusercontent.com/7Berlin/pasarguard-neon-template/main/install.sh | sudo bash -s -- --activate
```

此命令仅使用**波斯语**安装并启用模板。

![英文模板预览](assets/preview.webp)

## 安装命令

| 命令 | 说明 |
|---|---|
| `sudo bash install.sh --activate` | 安装模板，默认语言为波斯语 |
| `sudo bash install.sh --activate -fa -en` | 安装波斯语和英语；波斯语为默认语言 |
| `sudo bash install.sh --activate -en -ru --default-lang en` | 安装英语和俄语；英语为默认语言 |
| `sudo bash install.sh --activate -fa -en -ru -zh` | 安装全部语言 |
| `sudo bash install.sh --activate --config ./template.conf` | 使用自定义配置文件安装 |

| 参数 | 语言 |
|---|---|
| `-fa` | 🇮🇷 波斯语 |
| `-en` | 🇬🇧 英语 |
| `-ru` | 🇷🇺 俄语 |
| `-zh` | 🇨🇳 中文 |

## 配置模板

编辑 `template.conf`，然后重新运行安装程序：

```bash
git clone https://github.com/7Berlin/pasarguard-neon-template.git
cd pasarguard-neon-template
nano template.conf
sudo bash install.sh --activate --config ./template.conf
```

| 选项 | 用途 |
|---|---|
| `BRAND_NAME` | 服务名称 |
| `BRAND_SUBTITLE` | 用户名下方的文字 |
| `AVATAR_URL` | 头像或徽标的公开 URL |
| `AVATAR_FILE` | 本地 PNG、JPG、WEBP、GIF 或 SVG 文件 |
| `PRIMARY_COLOR` | 主色 |
| `SECONDARY_COLOR` | 第二颜色 |
| `CYAN_COLOR` | 强调色 |
| `DEFAULT_THEME` | `dark` 或 `light` 主题 |
| `SUPPORT_URL` | 教程或支持链接 |
| `PANEL_DOMAIN` | 必要时填写面板域名 |

请在 GitHub 上为项目点亮 Star 以支持项目 ⭐
