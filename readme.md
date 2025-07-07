# GitHub 多账号管理工具 (gh*)

一个 GitHub 多账号管理工具集，支持多账号 SSH 密钥切换、智能仓库克隆、用户配置管理和文件恢复等功能。

## 🚀 主要功能

### 多账号管理
- 🔐 **多账号 SSH 密钥管理** - 快速切换不同 GitHub 账号的 SSH 密钥
- 📧 **自动邮箱配置** - 克隆仓库时自动设置对应账号的邮箱
- 🏷️ **账号标签管理** - 清晰的账号名称标识，支持个人和工作账号分离

### 智能克隆
- 🎯 **账号指定克隆** - 使用指定账号克隆仓库，自动配置用户信息
- 🔄 **自动 SSH 配置** - 根据配置的主机别名自动选择正确的 SSH 密钥

### 文件恢复
- 🔍 **智能文件对比** - 比较不同 commit 之间的文件差异
- 📁 **选择性恢复** - 支持交互式选择或批量恢复缺失文件
- 🛡️ **安全备份** - 恢复前自动创建备份分支
- 🚫 **排除模式** - 支持排除特定文件模式

## 📦 安装

### 1. 克隆项目
```bash
git clone https://github.com/hye/gh ~/gh
chmod +x ~/gh/restore_missing_files.sh
```

### 2. 配置 Zsh
```bash
# 自动配置 zsh
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

### 3. 重新加载 Zsh 配置
```bash
source ~/.zshrc
```

## ⚙️ 配置

### 1. 编辑账号配置

编辑 `~/gh/gh.zsh` 文件中的 `GITHUB_ACCOUNTS` 数组：

```bash
# GitHub 账号列表 (格式: "名称 邮箱 配置主机")
GITHUB_ACCOUNTS=(
  "personal your-personal@email.com github.com-personal"
  "work your-work@email.com github.com-work"
  "company company@email.com github.com-company"
)
```

### 2. 配置 SSH 密钥

为每个账号创建对应的 SSH 密钥：

```bash
# 为个人账号创建密钥
ssh-keygen -t ed25519 -C "your-personal@email.com" -f ~/.ssh/id_ed25519_github_personal

# 为工作账号创建密钥
ssh-keygen -t ed25519 -C "your-work@email.com" -f ~/.ssh/id_ed25519_github_work
```

### 3. 配置 SSH 配置文件

编辑 `~/.ssh/config` 文件：

```ssh
# 个人账号
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_personal
    IdentitiesOnly yes

# 工作账号
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_work
    IdentitiesOnly yes
```

### 4. 将公钥添加到 GitHub

```bash
# 复制公钥到剪贴板
cat ~/.ssh/id_ed25519_github_personal.pub | pbcopy
```

然后在对应的 GitHub 账号中添加 SSH 密钥。

## 🎯 使用方法

### 账号管理命令

```bash
# 显示所有可用账号
gh-accounts  # 或 gh-list

# 切换到指定账号的 SSH 密钥
gh-use personal

# 显示当前使用的 SSH 密钥
gh-current  # 或 gcur
```

### 仓库管理命令

```bash
# 使用指定账号克隆仓库
gh-clone personal username/repo-name

# 使用指定账号克隆仓库到指定目录
gh-clone work company/project-name my-project

# 为当前仓库配置指定账号的邮箱
gh-config personal
```

### 文件恢复命令

```bash
# 恢复 HEAD~1 中存在但 HEAD 中不存在的文件
gh-restore

# 指定源和目标 commit
gh-restore -f HEAD~2 -t HEAD~1

# 排除特定文件模式
gh-restore -e "*.log" -e "temp/*"

# 非交互模式，恢复所有文件
gh-restore -y

# 仅显示文件列表，不执行恢复
gh-restore -d

# 查看帮助
gh-restore -h
```

## 📚 命令参考

### 主要命令

| 命令 | 别名 | 描述 |
|------|------|------|
| `gh-accounts` | `gh-list` | 显示所有可用的 GitHub 账号 |
| `gh-clone` | `gcl` | 使用指定账号克隆仓库 |
| `gh-config` | `gcfg` | 为当前仓库配置指定账号 |
| `gh-use` | `gkey` | 切换到指定账号的 SSH 密钥 |
| `gh-current` | `gcur` | 显示当前使用的 SSH 密钥 |
| `gh-restore` | - | 智能文件恢复 |

### 文件恢复选项

| 选项 | 描述 |
|------|------|
| `-f, --from COMMIT` | 源 commit（默认：HEAD~1） |
| `-t, --to COMMIT` | 目标 commit（默认：HEAD） |
| `-e, --exclude PATTERN` | 排除文件模式 |
| `-y, --yes` | 非交互模式 |
| `-d, --dry-run` | 仅显示文件列表 |
| `-h, --help` | 显示帮助信息 |

## 💡 使用示例

### 场景1：切换账号克隆仓库

```bash
# 切换到工作账号
gh-use work

# 使用工作账号克隆公司仓库
gh-clone work company/backend-api

# 切换到个人账号
gh-use personal

# 使用个人账号克隆个人项目
gh-clone personal myusername/my-project
```

### 场景2：为现有仓库配置账号

```bash
# 进入仓库目录
cd my-project

# 为当前仓库配置个人账号邮箱
gh-config personal

# 验证配置
git config user.email
```

### 场景3：恢复误删的文件

```bash
# 查看可恢复的文件
gh-restore -d

# 交互式选择恢复文件
gh-restore

# 恢复所有文件（非交互）
gh-restore -y

# 恢复特定范围的文件，排除日志文件
gh-restore -f HEAD~3 -t HEAD -e "*.log"
```

## ⚠️ 注意事项

1. **SSH 密钥管理**：确保每个账号的 SSH 密钥已正确配置并添加到对应的 GitHub 账号
2. **邮箱配置**：配置的邮箱地址必须是 GitHub 账号中已验证的邮箱
3. **权限管理**：确保对要克隆的仓库有相应的访问权限
4. **文件恢复**：恢复操作会修改工作区，建议在操作前确保工作区已提交或备份
5. **备份分支**：文件恢复操作会自动创建备份分支，可用于撤销操作

## 🔧 故障排除

### SSH 连接问题

```bash
# 测试 SSH 连接
ssh -T git@github.com-personal
ssh -T git@github.com-work

# 查看 SSH 密钥
ssh-add -l
```

### 权限问题

```bash
# 检查文件权限
ls -la ~/.ssh/

# 设置正确的权限
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/id_ed25519_github_*
chmod 644 ~/.ssh/id_ed25519_github_*.pub
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 📄 Unlicense license

请参阅 [LICENSE](LICENSE) 文件了解许可证详情。
