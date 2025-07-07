#!/bin/bash

# 智能文件恢复脚本
# 作用：动态比较两个commit之间的文件差异，并允许用户选择要恢复的文件

set -e  # 遇到错误时退出

# 默认参数
FROM_COMMIT="HEAD~1"
TO_COMMIT="HEAD"
EXCLUDE_PATTERN=""
INTERACTIVE=true
DRY_RUN=false

# 显示帮助信息
show_help() {
    cat << EOF
智能文件恢复脚本

用法: $0 [选项]

选项:
    -f, --from COMMIT       源commit (默认: HEAD~1)
    -t, --to COMMIT         目标commit (默认: HEAD)
    -e, --exclude PATTERN   排除文件模式 (支持通配符)
    -y, --yes              非交互模式，恢复所有文件
    -d, --dry-run          仅显示文件列表，不执行恢复操作
    -h, --help             显示此帮助信息

示例:
    $0                                    # 恢复HEAD~1中存在但HEAD中不存在的文件
    $0 -f HEAD~2 -t HEAD~1               # 恢复HEAD~2到HEAD~1之间的差异
    $0 -e "*.log" -e "temp/*"            # 排除日志文件和临时文件
    $0 -y                                # 非交互模式恢复所有文件
    $0 -d                                # 仅显示缺失文件列表，不执行恢复
    $0 -d -e ".DS_Store" # 显示排除指定文件后的列表
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--from)
            FROM_COMMIT="$2"
            shift 2
            ;;
        -t|--to)
            TO_COMMIT="$2"
            shift 2
            ;;
        -e|--exclude)
            EXCLUDE_PATTERN="$EXCLUDE_PATTERN $2"
            shift 2
            ;;
        -y|--yes)
            INTERACTIVE=false
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

if [[ "$DRY_RUN" == true ]]; then
    echo "🔍 正在分析commit差异... (DRY RUN 模式)"
else
    echo "🔍 正在分析commit差异..."
fi

# 检查是否在git仓库中
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ 错误：当前目录不是git仓库"
    exit 1
fi

# 检查commit是否存在
if ! git rev-parse "$FROM_COMMIT" > /dev/null 2>&1; then
    echo "❌ 错误：源commit不存在: $FROM_COMMIT"
    exit 1
fi

if ! git rev-parse "$TO_COMMIT" > /dev/null 2>&1; then
    echo "❌ 错误：目标commit不存在: $TO_COMMIT"
    exit 1
fi

echo "📋 源commit: $FROM_COMMIT ($(git rev-parse --short "$FROM_COMMIT"))"
echo "📋 目标commit: $TO_COMMIT ($(git rev-parse --short "$TO_COMMIT"))"

# 获取在源commit中存在但在目标commit中不存在的文件
echo "🔄 检测文件差异..."

# 获取两个commit的文件列表
FROM_FILES=$(git ls-tree -r --name-only "$FROM_COMMIT" | sort)
TO_FILES=$(git ls-tree -r --name-only "$TO_COMMIT" | sort)

# 找出在源commit中存在但在目标commit中不存在的文件
MISSING_FILES=$(comm -23 <(echo "$FROM_FILES") <(echo "$TO_FILES"))

# 应用排除模式
if [[ -n "$EXCLUDE_PATTERN" ]]; then
    echo "🚫 应用排除模式: $EXCLUDE_PATTERN"
    FILTERED_FILES=""
    for file in $MISSING_FILES; do
        should_exclude=false
        for pattern in $EXCLUDE_PATTERN; do
            if [[ "$file" == $pattern ]]; then
                should_exclude=true
                break
            fi
        done
        if [[ "$should_exclude" == false ]]; then
            FILTERED_FILES="$FILTERED_FILES$file"$'\n'
        fi
    done
    MISSING_FILES=$(echo "$FILTERED_FILES" | grep -v '^$' || true)
fi

# 检查是否有缺失文件
if [[ -z "$MISSING_FILES" ]]; then
    echo "✅ 没有发现缺失的文件"
    exit 0
fi

# 显示缺失文件列表
echo ""
echo "📋 发现以下缺失文件："
echo "$MISSING_FILES" | nl -w3 -s'. '

FILE_COUNT=$(echo "$MISSING_FILES" | wc -l | tr -d ' ')
echo ""
echo "📊 总共 $FILE_COUNT 个文件"

# 交互式选择
if [[ "$INTERACTIVE" == true ]] && [[ "$DRY_RUN" == false ]]; then
    echo ""
    echo "请选择要恢复的文件："
    echo "  a) 恢复所有文件"
    echo "  s) 选择特定文件"
    echo "  q) 取消退出"
    echo ""
    read -p "选择 (a/s/q): " -n 1 -r choice
    echo ""
    
    case $choice in
        [Aa])
            FILES_TO_RESTORE="$MISSING_FILES"
            ;;
        [Ss])
            echo "请输入要恢复的文件编号（用空格分隔，如：1 3 5）："
            read -r selected_numbers
            FILES_TO_RESTORE=""
            for num in $selected_numbers; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le "$FILE_COUNT" ]]; then
                    selected_file=$(echo "$MISSING_FILES" | sed -n "${num}p")
                    FILES_TO_RESTORE="$FILES_TO_RESTORE$selected_file"$'\n'
                fi
            done
            FILES_TO_RESTORE=$(echo "$FILES_TO_RESTORE" | grep -v '^$' || true)
            ;;
        [Qq])
            echo "❌ 用户取消操作"
            exit 0
            ;;
        *)
            echo "❌ 无效选择"
            exit 1
            ;;
    esac
else
    FILES_TO_RESTORE="$MISSING_FILES"
fi

# 检查是否有文件要恢复
if [[ -z "$FILES_TO_RESTORE" ]]; then
    echo "❌ 没有选择要恢复的文件"
    exit 0
fi

# Dry run模式：仅显示文件列表
if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "🔍 DRY RUN 模式 - 以下文件将被恢复："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    RESTORE_COUNT=0
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        echo "📁 $file"
        ((RESTORE_COUNT++))
    done <<< "$FILES_TO_RESTORE"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 总计: $RESTORE_COUNT 个文件将从 $FROM_COMMIT 恢复"
    echo "💡 要实际执行恢复，请不使用 -d/--dry-run 选项"
    echo ""
    echo "🔧 实际执行命令："
    echo "   $0 -f $FROM_COMMIT -t $TO_COMMIT"
    [[ -n "$EXCLUDE_PATTERN" ]] && echo "   排除模式: $EXCLUDE_PATTERN"
    exit 0
fi

# 检查工作区是否干净
if ! git diff --quiet && ! git diff --cached --quiet; then
    echo "⚠️  警告：工作区有未提交的更改"
    if [[ "$INTERACTIVE" == true ]]; then
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ 用户取消操作"
            exit 1
        fi
    fi
fi

# 创建备份分支
BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
echo "💾 创建备份分支: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH"

# 恢复文件
echo "🔄 开始恢复文件..."
RESTORED_COUNT=0
FAILED_COUNT=0

while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    
    echo "📁 恢复文件: $file"
    
    # 创建目录（如果不存在）
    mkdir -p "$(dirname "$file")"
    
    # 恢复文件
    if git checkout "$FROM_COMMIT" -- "$file" > /dev/null 2>&1; then
        echo "✅ 成功恢复: $file"
        ((RESTORED_COUNT++))
    else
        echo "❌ 恢复失败: $file"
        ((FAILED_COUNT++))
    fi
done <<< "$FILES_TO_RESTORE"

# 显示恢复结果
echo ""
echo "📊 恢复结果统计："
echo "   ✅ 成功恢复: $RESTORED_COUNT 个文件"
echo "   ❌ 失败: $FAILED_COUNT 个文件"

if [ $RESTORED_COUNT -eq 0 ]; then
    echo "❌ 没有文件被恢复，退出..."
    exit 1
fi

# 检查是否有文件需要提交
if git diff --cached --quiet; then
    echo "⚠️  没有文件需要提交"
    exit 0
fi

# 显示将要提交的文件
echo ""
echo "📋 将要提交的文件："
git diff --cached --name-only | sed 's/^/   /'

# 询问是否提交
COMMIT_MESSAGE="fix: restore missing files from $FROM_COMMIT

恢复了 $RESTORED_COUNT 个从 $FROM_COMMIT 中缺失的文件
备份分支: $BACKUP_BRANCH"

if [[ "$INTERACTIVE" == true ]]; then
    echo ""
    read -p "是否提交这些恢复的文件？(Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "📝 文件已恢复但未提交。可以使用以下命令手动提交："
        echo "   git commit -m \"fix: restore missing files from $FROM_COMMIT\""
        echo ""
        echo "💾 备份分支: $BACKUP_BRANCH"
        exit 0
    fi
fi

# 提交恢复的文件
echo "💾 提交恢复的文件..."
git commit -m "$COMMIT_MESSAGE"

echo ""
echo "🎉 恢复完成！"
echo "📋 新的commit: $(git rev-parse --short HEAD)"
echo "💾 备份分支: $BACKUP_BRANCH"
echo ""
echo "如需撤销，可以使用以下命令："
echo "   git reset --hard $BACKUP_BRANCH"
echo "   git branch -D $BACKUP_BRANCH" 