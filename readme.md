edit `GITHUB_ACCOUNTS` in `gh.zsh`

```shell
git clone https://github.com/hye/gh ~/gh
chmod +x ~/gh/restore_missing_files.sh

```

```zsh
# zsh 配置添加命令
(
  # 获取正确的 zsh 配置文件路径
  ZSH_CONFIG_DIR="${ZDOTDIR:-$HOME}"
  ZSH_CONFIG_FILE="$ZSH_CONFIG_DIR/.zshrc"

  # 确保配置目录存在
  mkdir -p "$ZSH_CONFIG_DIR"

  # 检查是否已经存在这行配置，避免重复添加
  if ! grep -q 'source "$HOME/gh/gh.zsh"' "$ZSH_CONFIG_FILE" 2>/dev/null; then
    echo 'source "$HOME/gh/gh.zsh"' >> "$ZSH_CONFIG_FILE"
    echo "已添加配置到: $ZSH_CONFIG_FILE"
  else
    echo "配置已存在于: $ZSH_CONFIG_FILE"
  fi
)
```