# GitHub 多账号管理配置

# GitHub 账号列表 (格式: "名称 邮箱 配置主机")
GITHUB_ACCOUNTS=(
  "personal personal@users.noreply.github.com github.com-personal"
  "work work@users.noreply.github.com github.com-work"
)

# 显示可用的 GitHub 账号
function gh-accounts() {
  echo "可用 GitHub 账号:"
  for account in "${GITHUB_ACCOUNTS[@]}"; do
    local name=$(echo "$account" | awk '{print $1}')
    local email=$(echo "$account" | awk '{print $2}')
    echo "  - $name ($email)"
  done
}

# 根据账号名称获取配置信息
function _get_gh_config() {
  local account_name="$1"
  local config_key="$2"
  local index=$(echo "$account_name" | tr '[:upper:]' '[:lower:]')

  for account in "${GITHUB_ACCOUNTS[@]}"; do
    local name=$(echo "$account" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
    if [[ "$name" == "$index" ]]; then
      echo "$account" | awk -v key="$config_key" '{print $key}'
      return
    fi
  done

  return 1
}

# 使用指定账号克隆仓库
function gh-clone() {
  if [[ $# -lt 2 ]]; then
    echo "用法: gh-clone <账号名称> <仓库路径> [目录名]"
    return 1
  fi

  local account_name="$1"
  local repo_path="$2"
  local target_dir="${3:-$(basename "$repo_path" .git)}"
  local host=$(_get_gh_config "$account_name" 3)

  if [[ -z "$host" ]]; then
    echo "错误: 未找到账号 '$account_name'"
    return 1
  fi

  git clone "git@${host}:${repo_path}" "$target_dir"

  if [[ $? -eq 0 && -d "$target_dir" ]]; then
    # 自动配置仓库的用户信息
    local email=$(_get_gh_config "$account_name" 2)
    (cd "$target_dir" && git config user.email "$email")
    echo "已为仓库 '$target_dir' 配置用户邮箱: $email"
  fi
}

# 为当前仓库配置 GitHub 账号
function gh-config() {
  if [[ $# -ne 1 ]]; then
    echo "用法: gh-config <账号名称>"
    return 1
  fi

  local account_name="$1"
  local email=$(_get_gh_config "$account_name" 2)

  if [[ -z "$email" ]]; then
    echo "错误: 未找到账号 '$account_name'"
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "错误: 当前目录不是 Git 仓库"
    return 1
  fi

  git config user.email "$email"
  echo "已为当前仓库配置用户邮箱: $email"
}

# 快速切换 SSH 代理使用的密钥
function gh-use() {
  if [[ $# -ne 1 ]]; then
    echo "用法: gh-use <账号名称>"
    return 1
  fi

  local account_name="$1"
  local key_file=$(_get_gh_config "$account_name" 3 | sed 's/github\.com-//')

  if [[ -z "$key_file" ]]; then
    echo "错误: 未找到账号 '$account_name'"
    return 1
  fi

  # 清除所有已添加的密钥
  ssh-add -D >/dev/null 2>&1

  # 添加指定密钥
  key_path="$HOME/.ssh/id_ed25519_github_${key_file}"
  if [[ -f "$key_path" ]]; then
    ssh-add "$key_path"
    echo "已切换到 GitHub 账号: $account_name"
  else
    echo "错误: SSH 密钥文件不存在: $key_path"
    return 1
  fi
}

# 显示当前使用的 SSH 密钥
function gh-current() {
  echo "当前使用的 GitHub SSH 密钥:"
  ssh-add -l | grep "github" || echo "未添加 GitHub 相关 SSH 密钥"
}

# 别名设置
alias gh-list='gh-accounts'
alias gcl='gh-clone'
alias gcfg='gh-config'
alias gkey='gh-use'
alias gcur='gh-current'
alias gh-restore='$HOME/gh/restore_missing_files.sh'

# 自动补全
function _gh_accounts_completion() {
  local accounts=()
  for account in "${GITHUB_ACCOUNTS[@]}"; do
    accounts+=("$(echo "$account" | awk '{print $1}')")
  done
  compadd "${accounts[@]}"
}

compdef _gh_accounts_completion gh-clone gh-config gh-use gh-list gcl gcfg gkey gcur