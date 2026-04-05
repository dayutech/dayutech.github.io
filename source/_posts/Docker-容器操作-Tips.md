---
title: Docker 容器操作 Tips
tags:
  - Docker
categories:
  - Tips
top: 1000
description: 本文记载了一些docker容器文件系统的操作方法
abbrlink: 3031c334
date: 2026-03-10 14:39:11
---
# 逻辑卷挂载技巧 LVM 格式分区
```shell
# 1. 扫描物理卷 (识别 /dev/sdb4)
sudo pvscan

# 2. 扫描卷组 (识别 sdb4 所属的卷组)
sudo vgscan

# 3. 激活所有卷组 (关键步骤：让逻辑卷可用)
sudo vgchange -ay

sudo lvscan
# 或者使用更详细的列表
sudo lvs
# 显示可挂载的逻辑券
ACTIVE            '/dev/my_vg/data_lv' [500.00 GiB] inherit
# 挂载
sudo mount /dev/my_vg/data_lv /mnt/my_lvm_disk
```
# 提取镜像分层系统文件
## 手动操作流程
1. 查看镜像元数据获取镜像id与镜像名的对应关系    
```shell
sudo cat docker/image/overlay2/repositories.json
```
结果如下  
```shell
{
  "Repositories": {
    "test.com/test": {
        # 仓库名@标签: 镜像ID
        # 这两行只是不同的引用方式的区别，实际的镜像id为后面一部分
      "test.com/test:20250603.0820-e4ea12569e37": "sha256:a908d64f22d5a56e50e39cfeee54b5154d96cba95019033112f9f6c698d2bed2",
      "test.com/test@sha256:d9b50f02d83446fbd536a7e085b31fd4c0e56b61cc1533d2a1dae4ca0fd31818": "sha256:a908d64f22d5a56e50e39cfeee54b5154d96cba95019033112f9f6c698d2bed2"
    },
    "test.com/test1": {
      "test.com/test1:20250512.1141-35963b76c12d": "sha256:3c552a4cabeacb758ddece2ce8390a36f7c8f1091f3dd2f1cc31ff0a0c4aa4cf",
      "test.com/test1@sha256:ed3186c81fa8a647257a32f4e6d4491317d0134d1901c531de7e851860bd87dd": "sha256:3c552a4cabeacb758ddece2ce8390a36f7c8f1091f3dd2f1cc31ff0a0c4aa4cf"
    },
	...
}
```

2.通过镜像id获取diff_ids 列表  
```shell
sudo cat docker/image/overlay2/imagedb/content/sha256/1c2f8b354b734f4f5aa240ac269ab10222dfbf5c9244c1590fcbd251e44f297e | jq '.rootfs.diff_ids'
```
得到最终结果如下  
```shell
[
  "sha256:f7080c1639e2a2b89e699aed4361e1aae141930f1ad1e96fa77a12073af2160b",
  "sha256:b37962d933d891f690d67696cd91b5d39499b969d95eaa95e059baec0ef3b0c8",
  "sha256:e2e94e3c8a616f9cd91a223f8909b63bdd5bb2b7d8059f3c4e81b5b43fb5e1b4",
  "sha256:c69cd6d9a1a0dfaccd6ca123adf5b871a4c00d854d5f7ef65fe6989df20f0b63",
  "sha256:46d6ca2266f3071ed95ee2b92492c7792d21a16430cdeeb0f44ae370b53d35a3",
  "sha256:d0470f9fb91deb565285e71d8bc2ac3f6290af1419bdf11846a6360b4b4bc071",
  "sha256:49f0cdd03432487835b5827eb2070b2fed6e32e1b4a0dc12dd8fa52a5b7db7b5",
  "sha256:466fffced12bcd9abfbc69ac54f8f53ca3bf45dd4dc4ba8efb66b954682b24e1",
  "sha256:e1bafc0932ba978b1d0e5751c58e56fc264e562b04531874ce18a5ee1f4550c7",
  "sha256:90fb7a283b908896f2d7c78adb7d1c96b8733dd846e090fe80fde9242a0f22a1",
  "sha256:e43ee2de9390a537224597fc3136746236be755de0398aca8df58b6302be0784",
  "sha256:3ae7fab6ebf7f7d333d8db18586dfbbdc94f483a32a66f656eb480a4ecf0c376",
  "sha256:533f88c659b0142a101c2078912544a06becd11619ffc57576341a5bd1aa0a35",
  "sha256:522caf17e56d46f57481dc3e15a25a2a588bbeed53a6e62cdf0350d0087654d4",
  "sha256:57b42b9dbfc36838124f9da0b44dbd5f0516279f8be6cc560af86c4683a5eac6",
  "sha256:c763d284294e6b14ee92585582fe5ba74d8a13566d23efc0ba5a7357ea3a5862",
  "sha256:ecfc9be0a95d47874565b731eb0de068bf4ae07ffbc4ea447cdb7c07491c14bd",
  "sha256:85edb0d86a314aedd2d56688c50d30fb8d2ab11d59a8c0b2fd376b8d361405bd",
  "sha256:fb99c184e6c078a1a44593af58cadb4a3b80e56f0498f4faf2b16d7e8a790df2",
  "sha256:944c9ad54bd63d5c217cadd7c7f9b0082766164e7d10ab13d3e39df0e11d34bc",
  "sha256:521c567b6b456081ba926616754266b7c0c9549ae878ac730a94971a2463c068", # nginx配置
  "sha256:377959c06747903f5574f27c21454beebc8a3acb3473336fcf2e3a868df58a4d", # nginx配置
  "sha256:78b4ea1c0c8689ed0e384decd127438f6327e05f1256fb126d336166fb24bd60",
  "sha256:399314c879ceacea922699dbfad874b181633167614db704dd9f68c3fc7c3653",
  "sha256:afca8ae24c9c666ed76bbd20f14002c87d2f7fcbdcc578bbe16ed0f5560b1643"
]
```
这就是diff_ids列表。  
同样我们可以稍微修改这条命令便可以得到镜像的构建历史  
```shell
sudo cat docker/image/overlay2/imagedb/content/sha256/1c2f8b354b734f4f5aa240ac269ab10222dfbf5c9244c1590fcbd251e44f297e | jq '.history'
```
得到如下结果
```json
......
  {
  # 复制nginix配置文件
    "created": "2025-06-23T13:29:20.562655432Z",
    "created_by": "COPY nginx/conf.d/test.conf /etc/nginx/conf.d/test.conf # buildkit",
    "comment": "buildkit.dockerfile.v0"
  },
  # 复制nginix配置文件
  {
    "created": "2025-06-23T13:29:20.584421536Z",
    "created_by": "COPY nginx/site.conf.d/*.conf /etc/nginx/test/site.conf.d/ # buildkit",
    "comment": "buildkit.dockerfile.v0"
  },
  # 复制自动执行的启动命令
  {
    "created": "2025-06-23T13:29:20.596360759Z",
    "created_by": "COPY ./init.d/test.sh /opt/base/init.d/test.sh # buildkit",
    "comment": "buildkit.dockerfile.v0"
  },
  # 复制入口点文件
  {
    "created": "2025-06-23T13:29:20.607926741Z",
    "created_by": "COPY ./init.d/start.sh /opt/init.d/start.sh # buildkit",
    "comment": "buildkit.dockerfile.v0"
  },
  # 设置入口点
  {
    "created": "2025-06-23T13:29:20.607926741Z",
    "created_by": "ENTRYPOINT [\"/opt/init.d/start.sh\"]",
    "comment": "buildkit.dockerfile.v0",
    "empty_layer": true
  }

```
可以通过构建历史的顺序找到我们需要的文件的对应diff_id，比如我需要nginx的配置文件，那么我就需要倒数第4第5层的内容。  

3. 通过diff_id 查找 chain_id   
diff_id 是被存在文件中的，所以此时用`grep`进行文件内容搜索  
```shell
sudo grep -R "377959c06747903f5574f27c21454beebc8a3acb3473336fcf2e3a868df58a4d" docker/image/overlay2/layerdb/sha256
```
得到结果
```shell
docker/image/overlay2/layerdb/sha256/84ef1c1817d7edfd09dc525f0e058895b999dd893492c3524913b1fd1589ba9e/diff:sha256:377959c06747903f5574f27c21454beebc8a3acb3473336fcf2e3a868df58a4d
```
`84ef1c1817d7edfd09dc525f0e058895b999dd893492c3524913b1fd1589ba9e` 即为chain_id  

4. 通过chain_id 找到cache_id  
```shell
sudo cat docker/image/overlay2/layerdb/sha256/84ef1c1817d7edfd09dc525f0e058895b999dd893492c3524913b1fd1589ba9e/cache-id
```
得到结果  
`cfe2eda799a0e99bc48d8387645a1c2b3f563be7508788058bb3851096f22e53`  

5. 通过cache_id 找到分层文件  
分层文件目录名使用的是cache_id  
```shell
sudo ls docker/overlay2/cfe2eda799a0e99bc48d8387645a1c2b3f563be7508788058bb3851096f22e53
```
diff 目录下就是复制的文件  

## 自动化脚本
执行前检查是否有 `jq awk sed` 命令
```shell
#!/bin/sh
set -u

DOCKER_ROOT="${DOCKER_ROOT:-/var/lib/docker}"
OUTPUT_BASE="${1:-/tmp}"

REPO_JSON="$DOCKER_ROOT/image/overlay2/repositories.json"
IMAGE_DB_DIR="$DOCKER_ROOT/image/overlay2/imagedb/content/sha256"
LAYERDB_DIR="$DOCKER_ROOT/image/overlay2/layerdb/sha256"
OVERLAY2_DIR="$DOCKER_ROOT/overlay2"

TMP_FILES=""
MAP_FILE=""
DIFF_FILE=""
HIST_FILE=""
MERGED_FILE=""
TOTAL_IMAGES=0
HIST_COUNT=0
CHOSEN=""
RESOLVED_CHAIN_ID=""
RESOLVED_CACHE_ID=""

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err() { printf '[ERROR] %s\n' "$*" >&2; }

cleanup() {
  for f in $TMP_FILES; do
    [ -n "$f" ] && [ -e "$f" ] && rm -f "$f"
  done
}
trap 'cleanup' EXIT HUP INT TERM

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "未检测到命令: $1"
    return 1
  fi
  return 0
}

is_number() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

sanitize_name() {
  printf '%s' "$1" | sed 's/[^A-Za-z0-9._-]/_/g'
}

init_tmp_files() {
  MAP_FILE="$(mktemp /tmp/image_map.XXXXXX)" || return 1
  DIFF_FILE="$(mktemp /tmp/image_diff.XXXXXX)" || return 1
  HIST_FILE="$(mktemp /tmp/image_hist.XXXXXX)" || return 1
  MERGED_FILE="$(mktemp /tmp/image_merged.XXXXXX)" || return 1
  TMP_FILES="$MAP_FILE $DIFF_FILE $HIST_FILE $MERGED_FILE"
  return 0
}

load_image_mappings() {
  if [ ! -f "$REPO_JSON" ]; then
    err "未找到 repositories.json: $REPO_JSON"
    return 1
  fi

  if ! jq -r '.Repositories | to_entries[] as $repo | $repo.value | to_entries[] | [.key, .value] | @tsv' "$REPO_JSON" | awk -F '\t' '!seen[$2]++' > "$MAP_FILE"; then
    err "解析 repositories.json 失败"
    return 1
  fi

  TOTAL_IMAGES="$(awk 'END{print NR+0}' "$MAP_FILE")"
  if [ "$TOTAL_IMAGES" -le 0 ]; then
    err "repositories.json 中未解析到镜像映射"
    return 1
  fi
  return 0
}

show_image_mappings() {
  printf '\n==== 镜像列表 ====\n'
  awk -F '\t' '{printf "%3d) %s => %s\n", NR, $1, $2}' "$MAP_FILE"
}

load_image_metadata() {
  image_id="$1"
  image_hash="$(printf '%s' "$image_id" | sed 's/^sha256://')"
  image_cfg="$IMAGE_DB_DIR/$image_hash"

  if [ ! -f "$image_cfg" ]; then
    err "未找到镜像配置文件: $image_cfg"
    return 1
  fi

  if ! jq -r '.rootfs.diff_ids[]?' "$image_cfg" > "$DIFF_FILE"; then
    err "读取 diff_ids 失败"
    return 1
  fi

  if ! jq -r '.history[] | [(.created // ""), (.created_by // ""), ((.empty_layer // false)|tostring)] | @tsv' "$image_cfg" > "$HIST_FILE"; then
    err "读取 history 失败"
    return 1
  fi

  awk -F '\t' '
    NR==FNR { d[++n]=$0; next }
    {
      created=$1; cmd=$2; empty=$3;
      if (empty=="true") { diff=""; type="empty" }
      else { i++; diff=d[i]; type="layer" }
      printf "%d\t%s\t%s\t%s\t%s\t%s\n", FNR, type, diff, created, cmd, empty
    }
  ' "$DIFF_FILE" "$HIST_FILE" > "$MERGED_FILE"

  HIST_COUNT="$(awk 'END{print NR+0}' "$MERGED_FILE")"
  if [ "$HIST_COUNT" -le 0 ]; then
    err "该镜像没有可用 history"
    return 1
  fi
  return 0
}

show_history_layers() {
  printf '\n==== 历史构建命令 ====\n'
  awk -F '\t' '
    {
      idx=$1; type=$2; diff=$3; created=$4; cmd=$5;
      if (type=="empty") diff="N/A";
      printf "%3s) [%s] diff_id=%s\n", idx, type, diff;
      printf "     created=%s\n", created;
      printf "     cmd=%s\n\n", cmd;
    }
  ' "$MERGED_FILE"
}

add_choice() {
  idx="$1"
  max="$2"

  if ! is_number "$idx"; then
    return 1
  fi
  if [ "$idx" -lt 1 ] || [ "$idx" -gt "$max" ]; then
    return 1
  fi

  case " $CHOSEN " in
    *" $idx "*) ;;
    *) CHOSEN="$CHOSEN $idx" ;;
  esac
  return 0
}

parse_selection() {
  selection="$1"
  max="$2"
  CHOSEN=""

  selection="$(printf '%s' "$selection" \
    | tr -d '\r' \
    | tr '，' ',' \
    | sed 's/[[:space:]]*-[[:space:]]*/-/g; s/^[[:space:]]*//; s/[[:space:]]*$//')"

  for token in $(printf '%s' "$selection" | tr ',' ' '); do
    token="$(printf '%s' "$token" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -z "$token" ] && continue

    case "$token" in
      *-*)
        start="${token%-*}"
        end="${token#*-}"
        if ! is_number "$start" || ! is_number "$end"; then
          return 1
        fi
        if [ "$start" -gt "$end" ]; then
          return 1
        fi
        i="$start"
        while [ "$i" -le "$end" ]; do
          add_choice "$i" "$max" || return 1
          i=$((i + 1))
        done
        ;;
      *)
        add_choice "$token" "$max" || return 1
        ;;
    esac
  done

  [ -n "$CHOSEN" ]
}

resolve_layer_ids() {
  diff_id="$1"
  RESOLVED_CHAIN_ID=""
  RESOLVED_CACHE_ID=""

  [ -n "$diff_id" ] || return 1

  diff_path="$(grep -Rsl --fixed-strings -- "$diff_id" "$LAYERDB_DIR" 2>/dev/null | grep '/diff$' | head -n 1)"
  [ -n "$diff_path" ] || return 1

  RESOLVED_CHAIN_ID="$(basename "$(dirname "$diff_path")")"
  cache_file="$LAYERDB_DIR/$RESOLVED_CHAIN_ID/cache-id"
  [ -f "$cache_file" ] || return 1

  RESOLVED_CACHE_ID="$(cat "$cache_file" 2>/dev/null)"
  [ -n "$RESOLVED_CACHE_ID" ] || return 1
  return 0
}

extract_copy_destination() {
  cmd="$1"
  dest=""

  case "$cmd" in
    *"#(nop) COPY "*" in "*)
      dest="${cmd##* in }"
      ;;
    *COPY*)
      body="$(printf '%s\n' "$cmd" | sed 's/^.*COPY[[:space:]][[:space:]]*//; s/[[:space:]]# buildkit.*$//')"
      # shellcheck disable=SC2086
      set -- $body
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --*) shift ;;
          *) break ;;
        esac
      done

      if [ "$#" -gt 0 ]; then
        last=""
        for arg in "$@"; do
          last="$arg"
        done
        dest="$last"
      fi
      ;;
  esac

  dest="$(printf '%s' "$dest" | sed "s/,$//; s/^['\"]//; s/['\"]$//")"
  printf '%s' "$dest"
}

extract_from_diff() {
  diff_id="$1"
  created_by="$2"
  target_dir="$3"

  case "$created_by" in
    *COPY*) ;;
    *) return 2 ;;
  esac

  dest_path="$(extract_copy_destination "$created_by")"
  if [ -z "$dest_path" ]; then
    warn "COPY 命令解析失败，跳过: $created_by"
    return 1
  fi

  case "$dest_path" in
    /*) ;;
    *)
      warn "COPY 目标路径不是绝对路径，跳过: $dest_path"
      return 1
      ;;
  esac

  if ! resolve_layer_ids "$diff_id"; then
    warn "无法通过 diff_id 找到 cache-id: $diff_id"
    return 1
  fi

  diff_dir="$OVERLAY2_DIR/$RESOLVED_CACHE_ID/diff"
  if [ ! -d "$diff_dir" ]; then
    warn "diff 目录不存在: $diff_dir"
    return 1
  fi

  rel="$(printf '%s' "$dest_path" | sed 's#^/##; s#/$##')"
  if [ -z "$rel" ]; then
    warn "目标路径为空，跳过: $dest_path"
    return 1
  fi

  src="$diff_dir/$rel"
  if [ -d "$src" ]; then
    mkdir -p "$target_dir/$rel" || return 1
    cp -a "$src"/. "$target_dir/$rel"/ || return 1
    info "已提取目录: $dest_path"
    return 0
  fi

  if [ -e "$src" ]; then
    parent="$(dirname "$rel")"
    mkdir -p "$target_dir/$parent" || return 1
    cp -a "$src" "$target_dir/$rel" || return 1
    info "已提取文件: $dest_path"
    return 0
  fi

  warn "在 diff 中未找到目标路径，跳过: $dest_path"
  return 1
}

main() {
  require_cmd jq || {
    err "请先安装 jq，例如: sudo apt-get install -y jq"
    exit 1
  }
  require_cmd awk || exit 1
  require_cmd grep || exit 1
  require_cmd sed || exit 1
  require_cmd cp || exit 1
  require_cmd mktemp || exit 1

  if [ ! -d "$DOCKER_ROOT" ]; then
    err "DOCKER_ROOT 不存在: $DOCKER_ROOT"
    exit 1
  fi

  mkdir -p "$OUTPUT_BASE" || {
    err "无法创建输出目录: $OUTPUT_BASE"
    exit 1
  }

  init_tmp_files || {
    err "初始化临时文件失败"
    exit 1
  }

  info "DOCKER_ROOT=$DOCKER_ROOT"
  info "OUTPUT_BASE=$OUTPUT_BASE"

  while :; do
    load_image_mappings || exit 1
    show_image_mappings

    printf '\n输入镜像编号继续；输入 q 退出。\n'
    printf '请选择镜像编号: '
    IFS= read -r image_choice || break

    case "$image_choice" in
      q|Q) info "退出。"; break ;;
    esac

    if ! is_number "$image_choice" || [ "$image_choice" -lt 1 ] || [ "$image_choice" -gt "$TOTAL_IMAGES" ]; then
      warn "镜像编号无效，请重试。"
      continue
    fi

    image_ref="$(awk -F '\t' -v n="$image_choice" 'NR==n{print $1; exit}' "$MAP_FILE")"
    image_id="$(awk -F '\t' -v n="$image_choice" 'NR==n{print $2; exit}' "$MAP_FILE")"
    image_safe="$(sanitize_name "$image_ref")"

    load_image_metadata "$image_id" || continue
    show_history_layers

    printf '\n输入层编号（支持 3,5-7），仅非 empty 层可选；输入 b 返回镜像列表。\n'
    printf '请选择层编号: '
    IFS= read -r layer_selection || break

    case "$layer_selection" in
      b|B) continue ;;
    esac

    if ! parse_selection "$layer_selection" "$HIST_COUNT"; then
      warn "层编号无效，请输入 1-$HIST_COUNT 范围内，例如: 3,5-7"
      continue
    fi

    invalid=0
    for idx in $CHOSEN; do
      type="$(awk -F '\t' -v n="$idx" 'NR==n{print $2; exit}' "$MERGED_FILE")"
      if [ "$type" = "empty" ]; then
        warn "第 $idx 层是 empty_layer，不能提取。"
        invalid=1
      fi
    done
    [ "$invalid" -eq 1 ] && continue

    final_target="$OUTPUT_BASE/$image_safe"
    mkdir -p "$final_target" || {
      warn "无法创建目录: $final_target"
      continue
    }

    printf '\n==== 选择结果 ====\n'
    printf '镜像: %s\n' "$image_ref"
    printf '镜像ID: %s\n' "$image_id"
    printf '输出目录: %s\n' "$final_target"
    printf '层详情:\n'

    for idx in $CHOSEN; do
      diff_id="$(awk -F '\t' -v n="$idx" 'NR==n{print $3; exit}' "$MERGED_FILE")"
      cmd_text="$(awk -F '\t' -v n="$idx" 'NR==n{print $5; exit}' "$MERGED_FILE")"

      chain_id="not-found"
      cache_id="not-found"
      if resolve_layer_ids "$diff_id"; then
        chain_id="$RESOLVED_CHAIN_ID"
        cache_id="$RESOLVED_CACHE_ID"
      fi

      printf '  - 层编号=%s\n' "$idx"
      printf '    diff_id=%s\n' "$diff_id"
      printf '    chain_id=%s\n' "$chain_id"
      printf '    cache_id(layer id)=%s\n' "$cache_id"
      printf '    history_cmd=%s\n' "$cmd_text"
    done

    extracted_ok=0
    extracted_fail=0
    for idx in $CHOSEN; do
      diff_id="$(awk -F '\t' -v n="$idx" 'NR==n{print $3; exit}' "$MERGED_FILE")"
      cmd_text="$(awk -F '\t' -v n="$idx" 'NR==n{print $5; exit}' "$MERGED_FILE")"

      case "$cmd_text" in
        *COPY*)
          if extract_from_diff "$diff_id" "$cmd_text" "$final_target"; then
            extracted_ok=$((extracted_ok + 1))
          else
            extracted_fail=$((extracted_fail + 1))
          fi
          ;;
        *)
          info "第 $idx 层不是 COPY 命令，跳过提取。"
          ;;
      esac
    done

    printf '\n==== 执行完成 ====\n'
    printf '镜像: %s\n' "$image_ref"
    printf '选中层数: %s\n' "$(printf '%s\n' "$CHOSEN" | awk '{print NF}')"
    printf 'COPY 提取成功: %s\n' "$extracted_ok"
    printf 'COPY 提取失败: %s\n' "$extracted_fail"
    printf '提取目录: %s\n' "$final_target"
    printf '%s\n' '-----------------------------'
  done
}

main "$@"

```