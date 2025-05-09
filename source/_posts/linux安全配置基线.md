---
title: Linux安全配置基线
tags:
  - Linux
  - 安全基线
categories:
  - - 安全技术
  - - Linux
description: 本文介绍了 Linux安全配置基线 的相关知识点
abbrlink: 7cd2fa35
date: 2025-04-10 20:56:11
---
# linux安全配置基线

# 一、共享账号检查

```
配置名称：用户账号分配检查，避免共享账号存在
配置要求：1、系统需按照实际用户分配账号；
          2、避免不同用户间共享账号，避免用户账号和服务器间通信使用的账号共享。
操作指南：参考配置操作：cat /etc/passwd查看当前所有用户的情况；
检查方法：命令cat /etc/passwd查看当前所有用户的信息，与管理员确认是否有共享账号情况存在。
配置方法：如需建立用户，参考如下：
          #useradd username  #创建账号
          #passwd username   #设置密码
          使用该命令为不同的用户分配不同的账号，设置不同的口令及权限信息等。
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 二、多余账户锁定

```
配置名称：多余账户锁定策略
配置要求：应锁定与设备运行、维护等工作无关的账号。
操作指南：参考配置操作：
          查看锁定用户：
          # cat /etc/password，查看哪些账户的shell域中为nologin；
检查方法：人工检查：
          	# cat /etc/password后查看多余账户的shell域为nologin为符合；
          BVS基线检查：
          	多余账户处于锁定状态为符合。
配置方法：锁定用户：
        修改/etc/password文件，将需要锁定的用户的shell域设为nologin；
        或通过#passwd –l username锁定账户；
        只有具备超级用户权限的使用者方可使用#passwd –l username锁定用户,用#passwd –d username解锁后原有密码失效，登录需输入新密码。
        补充操作说明：
        一般情况下，需要锁定的用户：lp,nuucp,hpdb,www,demon
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 三、root账户登录控制

```
配置名称：root账户远程登录账户限制
配置要求：1、限制具备超级管理员权限的用户远程登录。
          2、远程执行管理员权限操作，应先以普通权限用户远程登录后，再切换到超级管理员权限账号后执行相应操作。
操作指南：使用root账户远程尝试登陆
检查方法：1、root远程登录不成功，提示“Not on system console”；
         2、普通用户可以登录成功，而且可以切换到root用户；
配置方法：修改/etc/ssh/sshd_config文件，将PermitRootLogin yes改为PermitRootLogin no，重启sshd服务。
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 四、口令复杂度要求

```
配置名称：操作系统口令复杂度策略
配置要求：口令长度至少12位，并包括数字、小写字母、大写字母和特殊符号。
操作指南：1、参考配置操作
        # cat /etc/pam.d/system-auth，找到password模块接口的配置部分，找到类似如下的配置行：
        password  requisite  /lib/security/$ISA/pam_cracklib.so minlen =6
        2、补充操作说明
        参数说明如下：
        1、retry=N，确定用户创建密码时允许重试的次数；
        2、minlen=N，确定密码最小长度要求，事实上，在默认配置下，此参数代表密码最小长度为N-1；
        3、dcredit=N，当N小于0时，代表新密码中数字字符数量不得少于（-N）个。例如，dcredit=-2代表密码中要至少包含两个数字字符；
        4、ucredit=N，当N小于0时，代表则新密码中大写字符数量不得少于（-N）个；
        5、lcredit=N，当N小于0时，代表则新密码中小写字符数量不得少于（-N）个；
        6、ocredit=N，当N小于0时，代表则新密码中特殊字符数量不得少于（-N）个；
检查方法：# cat /etc/pam.d/system-auth，参考操作指南检查对应参数
         	口令的最小长度至少12位
         	口令最少应包含的字符数量
         	口令中最少应包含的字母字符数量
         	口令中最少应包含的非字母数字字符数量
         通过以上4子项的输出综合判断该项是否满足。
配置方法：# vi /etc/pam.d/system-auth，找到password模块接口的配置部分，按照配置要求内容修改对应属性。
适用版本：Linux Redhat AS 4
```

# 五、口令最长生存期策略

```
配置名称：口令最长生存期策略
配置要求：要求操作系统的账户口令的最长生存期不长于90天
操作指南：# cat /etc/login.defs文件中指定配置项，其中：
          PASS_MAX_DAYS配置项决定密码最长使用期限；
          PASS_MIN_DAYS配置项决定密码最短使用期限；
          PASS_WARN_AGE配置项决定密码到期提醒时间。
检查方法：PASS_MAX_DAYS值小于等于90为符合；
         “对于采用静态口令认证技术的设备，账户口令的生存期不长于90天”项的当前值：表示当前的口令生存期长度。
配置方法：vi /etc/login.defs文件，修改PASS_MAX_DAYS值为小于等于9
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 六、系统关键目录访问权限

```
配置名称：关键目录权限控制
配置要求：根据安全需要，配置某些关键目录其所需的最小权限；
          重点要求password配置文件、shadow文件、group文件权限。
         当前主流版本的linux系统在默认情况下即对重要文件做了必要的权限设置，在日常管理和操作过程中应避免修改此类文件权限，除此以外，
         应定期对权限进行检查及复核，确保权限设置正确。
操作指南：查看关键目录的用户对应权限参考命令
          ls -l /etc/passwd
          ls -l /etc/shadow
          ls -l /etc/group
检查方法：与管理员确认已有权限为最小权限。
配置方法：参考配置操作：
        通过chmod命令对目录的权限进行实际设置。
        补充操作说明：
        	/etc/passwd 所有用户都可读，root用户可写 –rw-r—r— 
        配置命令：chmod 644 /etc/passwd
        	/etc/shadow 只有root可读 –r-------- 
        配置命令：chmod 600 /etc/shadow；
        	/etc/group 必须所有用户都可读，root用户可写 –rw-r—r—
        配置命令：chmod 644 /etc/group；
        如果是有写权限，就需移去组及其它用户对/etc的写权限（特殊情况除外）执行命令#chmod -R go-w,o-r /etc
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 七、用户缺省权限控制

```
配置名称：用户缺省权限控制
配置要求：控制用户缺省访问权限，当在创建新文件或目录时应屏蔽掉新文件或目录不应有的访问允许权限,防止同属于
该组的其它用户及别的组的用户修改该用户的文件或更高限制。
操作指南：1、# cat /etc/bashrc  查看全局默认设置umask值
          2、查看具体用户home目录下bash_profile，具体用户的umask
检查方法：查看全局默认设置umask值为027或更小权限为符合（如有特许权限需求，可根据实际情况判断）；
          查看具体用户的umask，本着最小权限的原则。
配置方法：参考配置操作：
          单独针对用户设置
          可修改用户home目录下的.bash_profile脚本文件，例如，可增加一条语句：umask 027；对于权限要求较严格的场合，建议设置为077。
          全局默认设置：
          默认通过全局脚本/etc/bashrc设置所有用户的默认umask值，修改脚本即可实现对用户默认umask值的全局性修改，
          通常建议将umask设置为027以上，对于权限要求较严格的场合，建议设置为077。
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 八、安全日志完备性要求

```
配置名称：安全日志完备性要求
配置要求：系统应配置完备日志记录，记录对与系统相关的安全事件。
操作指南：1、# cat /etc/syslog.conf查看是否有对应配置
          2、# cat /var/log/secure查看是否有对应配置
检查方法：1、cat /etc/syslog.conf确认有对应配置；
          2、查看/var/log/secure，应记录有需要的设备相关的安全事件。
配置方法：修改配置文件vi /etc/syslog.conf。
          配置如下类似语句：
          authpriv.*			/var/log/secure
          定义为需要保存的设备相关安全事件。
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 九、统一远程日志服务器配置

```
配置名称：统一远程日志服务器配置
配置要求：当前系统应配置远程日志功能，将需要重点关注的日志内容传输到日志服务器进行备份。
操作指南：# cat /etc/syslog.conf查看是否有对应配置
检查方法：配置了远程日志服务器为符合
配置方法：1、参考配置操作
          修改配置文件vi /etc/syslog.conf，
          加上这一行：
          *.* @192.168.0.1
          可以将"*.*"替换为你实际需要的日志信息。比如：kern.* / mail.* 等等；可以将此处192.168.0.1替换为实际的IP或域名。
          重新启动syslog服务，执行下列命令：
          services syslogd restart
          2、补充操作说明
          注意：*.*和@之间为一个Tab
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 十、设置history时间戳

```
配置名称：设置history时间戳
配置要求：配置history时间戳，便于审计。
操作指南：# cat /etc/bashrc查看是否有对应配置
检查方法：已添加，如：“export HISTTIMEFORMAT="%F %T”配置为符合。
配置方法：参考配置操作：
          在/etc/bashrc文件中增加如下行：
          export HISTTIMEFORMAT="%F %T
适用版本：Linux Redhat AS 4
```

# 十一、ssh登录配置

```
配置名称：SSH登录配置
配置要求：系统应配置使用SSH等加密协议进行远程登录维护，并安全配置SSHD的设置。不使用TELENT进行远程登录维护。
操作指南：1、查看SSH服务状态：# ps –elf|grep ssh；
          2、查看telnet服务状态：# ps –elf|grep telnet。
检查方法：1、	不能使用telnet进行远程维护；
          2、	应使用SSH进行远程维护；
          3、	SSH配置要符合如下要求；
              Protocol  2 #使用ssh2版本
              X11Forwarding yes #允许窗口图形传输使用ssh加密
              IgnoreRhosts  yes#完全禁止SSHD使用.rhosts文件
              RhostsAuthentication no #不设置使用基于rhosts的安全验证
              RhostsRSAAuthentication no #不设置使用RSA算法的基于rhosts的安全验证
              HostbasedAuthentication no #不允许基于主机白名单方式认证
              PermitRootLogin no #不允许root登录
              PermitEmptyPasswords no #不允许空密码
              Banner /etc/motd  #设置ssh登录时显示的banner
          4、以上条件都满足为符合。
配置方法：1、参考配置操作
            编辑 sshd_config，添加相关设置，SSHD相关安全设置选项参考检查方法中的描述。
          2、补充操作说明
            查看SSH服务状态：# ps –elf|grep ssh
适用版本：Linux Redhat AS 4
```

# 十二、关闭不必要的服务

```
配置名称：关闭不必要的系统服务
配置要求：根据每台机器的不同角色，关闭不需要的系统服务。操作指南中的服务项提供参考，根据服务器的角色和应用情况对启动项进行修改。
如无特殊需要，应关闭Sendmail、Telnet、Bind等服务。
操作指南：执行命令 #chkconfig --list，查看哪些服务开放。
检查方法：与管理员确认无用服务已关闭
配置方法：1、参考配置操作
        使用如下方式禁用不必要的服务
        #service <服务名> stop
        #chkconfig --level 35 off
        2、参考说明
        Linux/Unix系统服务中，部分服务存在较高安全风险，应当禁用，包括：
        “lpd”，此服务为行式打印机后台程序，用于假脱机打印工作的UNIX后台程序，此服务通常情况下不用，建议禁用；
        “telnet”，此服务采用明文传输数据，登陆信息容易被窃取，建议用ssh代替；
        “routed”，此服务为路由守候进程，使用动态RIP路由选择协议，建议禁用；
        “sendmail”，此服务为邮件服务守护进程，非邮件服务器应将其关闭；
        “Bluetooth”，此服务为蓝牙服务，如果不需要蓝牙服务时应关闭；
        “identd”，此服务为AUTH服务，在提供用户信息方面与finger类似，一般情况下该服务不是必须的，建议关闭；
        “xfs”，此服务为Linux中X Window的字体服务，关于该服务历史上出现过信息泄露和拒绝服务等漏洞，应以减少系统风险；
        R服务（“rlogin”、“rwho”、“rsh”、“rexec”），R服务设计上存在严重的安全缺陷，仅适用于封闭环境中信任主机之间便捷访问，
        其他场合下均必须禁用；
        基于inetd/xinetd的服务（daytime、chargen、echo等），此类服务建议禁用。
适用版本：Linux Redhat AS 3、Linux Redhat AS 4
```

# 十三、禁止ctr+alt+del键盘关闭命令

```
配置名称：禁止Control-Alt-Delete键盘关闭命令
配置要求：应禁止使用Control-Alt-Delete组合键重启服务器，防止误操作
操作指南：命令cat /etc/inittab，查看配置
检查方法：/etc/inittab 中应有：“#ca::ctrlaltdel:/sbin/shutdown -t3 -r now”配置为符合。
配置方法：1、参考配置操作
            在“/etc/inittab” 文件中注释掉下面这行（使用#）： ca::ctrlaltdel:/sbin/shutdown -t3 -r now  
            改为： #ca::ctrlaltdel:/sbin/shutdown -t3 -r now  
            为了使此改动生效，输入下面这个命令： # /sbin/init q
        2、补充说明
            禁止ctl-alt-del使得在控制台直接按ctl-alt-del不能重新启动计算机。
适用版本：Linux Redhat AS 4
```

# 十四、安装操作系统补丁

```
配置名称：安装操作系统更新补丁
配置要求：安装操作系统更新补丁，修复系统漏洞
操作指南：1、查看当前系统补丁版本
          2、检查官网当前系统版本是否发布安全更新。
检查方法：版本应保持为最新
配置方法：通过访问
https://rhn.redhat.com/errata/下载补丁安装包，在打开的页面上，选择与自己使用相对应的系统后，点击连接进入补丁包下载列表界面，
选择需要的补丁下载。
         下载的补丁为rpm安装包，将该安装包复制到目标系统上，使用命令rpm –ivh xxx.rpm进行安装，随后重新启动系统，
         检查所安装补丁的服务或应用程序是否运行正常，即完成该补丁的安装和升级工作。
适用版本：Linux Redhat AS 3 Linux Redhat AS 4
```