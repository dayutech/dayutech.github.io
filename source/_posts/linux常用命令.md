---
title: Linux常用命令
tags:
  - Linux
categories:
  - - 安全技术
  - - Linux
description: 本文介绍了 数据库 的相关知识点
abbrlink: d0edc1ed
date: 2025-04-10 20:56:11
---
# linux常用命令

# linux系统的文件结构

Linux系统命令行的含义

[linux文件系统结构](linux%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F%E7%BB%93%E6%9E%84%204de50be84c4e44a5b0a8fb15c5169a19.csv)

# Linux系统命令行的含义

示例：root@app00:~#

root            //用户名，root为超级用户
@               //分隔符
app00        //主机名称
~               //当前所在目录，默认用户目录为~，会随着目录切换而变化，例如：（root@app00:/bin# ，当前位置在bin目录下）

#                //表示当前用户是超级用户，普通用户为，例如：（"yao@app00:/root$" ，表示使用用户"yao"访问/root文件夹

# 命令的组成

示例：命令 参数名 参数值

# 基础操作

## 重启系统

1. 立刻关机
    
    shutdown -h now 或者 poweroff
    
2. 两分钟后关机
    
      shutdown -h 2
    

## 关闭系统

1. 立刻重启
    
     shutdown -r now 或者 reboot
    
2. 两分钟后重启
    
    shutdown -r 2
    

## 帮助命令

ifconfig --help //查看 ifconfig 命令的用法

## 命令说明书

man shutdown //打开命令说明后，可按"q"键退出

## 切换用户

su - yao               //切换为用户"yao",输入后回车需要输入该用户的密码
  exit                 //退出当前用户

# 目录操作

## 切换目录

cd /                             //切换到根目录
cd /bin                        //切换到根目录下的bin目录
cd ../                           //切换到上一级目录 或者使用命令：cd ..
cd ~                           //切换到home目录
cd -                            //切换到上次访问的目录
cd xx(文件夹名)         //切换到本目录下的名为xx的文件目录，如果目录不存在报错
cd /xxx/xx/x              //可以输入完整的路径，直接切换到目标目录，输入过程中可以使用tab键快速补全

## 查看目录

ls                    //查看当前目录下的所有目录和文件
ls -a                //查看当前目录下的所有目录和文件（包括隐藏的文件）
ls -l                //列表查看当前目录下的所有目录和文件（列表查看，显示更多信息），与命令"ll"效果一样
ls /bin              //查看指定目录下的所有目录和文件

## 创建目录

mkdir tools              //在当前目录下创建一个名为tools的目录
  mkdir /bin/tools     //在指定目录下创建一个名为tools的目录

## 删除目录与文件

rm 文件名              //删除当前目录下的文件
rm -f 文件名           //删除当前目录的的文件（不询问）
rm -r 文件夹名         //递归删除当前目录下此名的目录
rm -rf 文件夹名        //递归删除当前目录下此名的目录（不询问）
rm -rf *              //将当前目录下的所有目录和文件全部删除
rm -rf /*             //将根目录下的所有文件全部删除【慎用！相当于格式化系统】

## 修改目录

mv 当前目录名 新目录名        //修改目录名，同样适用与文件操作
mv /usr/tmp/tool /opt       //将/usr/tmp目录下的tool目录剪切到 /opt目录下面
mv -r /usr/tmp/tool /opt    //递归剪切目录中所有文件和文件夹 //该命令错误

## 拷贝目录

cp /usr/tmp/tool /opt       //将/usr/tmp目录下的tool目录复制到 /opt目录下面
  cp -r /usr/tmp/tool /opt    //递归剪复制目录中所有文件和文件夹

cp -a a.txt b.txt   //复制时保留文件的元数据，既保留所属用户所属组等信息

cp -f a.txt b.txt //强制覆盖目标目录同名文件，因为别名的存在可能不成功，需要撤销默认定义的别名

## 搜索目录

find /bin -name 'a*' //查找/bin目录下的所有以a开头的文件或者目录

## 查看当前目录

pwd //显示当前位置路径

# 文件操作

## 新增文件

touch a.txt //在当前目录下创建名为a的txt文件（文件不存在），如果文件存在，将文件时间属性修改为当前系统时间

## 删除文件

rm 文件名              //删除当前目录下的文件
  rm -f 文件名           //删除当前目录的的文件（不询问）

## 编辑文件

vi 文件名              //打开需要编辑的文件
--进入后，操作界面有三种模式：命令模式（command mode）、插入模式（Insert mode）和底行模式（last line mode）
命令模式
-刚进入文件就是命令模式，通过方向键控制光标位置，
-使用命令"dd"删除当前整行
-使用命令"/字段"进行查找
-按"i"在光标所在字符前开始插入
-按"a"在光标所在字符后开始插入
-按"o"在光标所在行的下面另起一新行插入
-按"："进入底行模式
插入模式
-此时可以对文件内容进行编辑，左下角会显示 "-- 插入 --""
-按"ESC"进入底行模式
底行模式
-退出编辑：      :q
-强制退出：      :q!
-保存并退出：    :wq

##操作步骤示例##

1.保存文件：按"ESC" -> 输入":" -> 输入"wq",回车     //保存并退出编辑
2.取消操作：按"ESC" -> 输入":" -> 输入"q!",回车     //撤销本次修改并退出编辑

##补充##

vim +10 filename.txt                   //打开文件并跳到第10行
vim -R /etc/passwd                     //以只读模式打开文件

## 查看文件

cat a.txt          //查看文件最后一屏内容
less a.txt         //PgUp向上翻页，PgDn向下翻页，"q"退出查看
more a.txt         //显示百分比，回车查看下一行，空格查看下一页，"q"退出查看
tail -100 a.txt    //查看文件的后100行，"Ctrl+C"退出查看

tail -f a.txt

sort

uniq

od

strings

# 别名

alias ^c='clear' //定义命令的别名

unalias clear //撤销别名

# 文件权限

## 权限说明

文件权限简介：'r' 代表可读（4），'w' 代表可写（2），'x' 代表执行权限（1），括号内代表"8421法"
##文件权限信息示例：-rwxrw-r--
-第一位：'-'就代表是文件，'d'代表是文件夹
-第一组三位：拥有者的权限
-第二组三位：拥有者所在的组，组员的权限
-第三组三位：代表的是其他用户的权限

## 文件权限

普通授权    chmod +x a.txt 

chmod a=rwx a.txt   
  8421法     chmod 777 a.txt     //1+2+4=7，"7"说明授予所有权限

文件默认最高权限 666

目录默认最高权限777

权限掩码umask 0022

权限掩码设置为333时，计算的默认权限应为333，实际却为444，因为文件默认没有可执行权限，如果为333得话则拥有了可执行权限，故3+1得到读权限

**SUID-setuid**

临时赋予当前用户可执行文件所有者的权限。

chmod u+s /use/bin/rm

**SGID-setgid**

临时赋予当前用户可执行文件所有者的权限

具有sgid权限的目录下的文件的属组继承其父目录的属组

chmod g+s /tmp/a

**stickybit 粘滞位**

在设置了粘滞位的目录下面的文件，只有文件的属主或者root才拥有删除的权限

chmod o+t /tmp/a

一般/tmp配置有粘滞位

## ACL

setfacl -m u:armandhe:rwx a.txt //给用户armandhe设置acl

setfacl -m m::rwx filename //设置文件的最大有效权限为rwx

setfacl -x u:armandhe:rw filename //删除armandhe的rw权限

setfacl -x g:armandhe:rw filename //删除组armandhe的rw权限

setfacl -b a //删除所有acl权限

setfacl -m d:u:armandhe:rw dirname //指定默认acl权限，只对目录生效，以后新建的所有子文件都继承该目录的acl权限，只针对新建的文件生效

setfacl -m u:armandhe:rwx -R/tmp //指定递归acl权限，父目录下的所有文件都继承父目录的acl

getacl a.txt //查看文件的acl信息

mount //查看系统挂载信息

dumpe2fs -h 分区 查看指定分区文件系统详细信息

## 修改用户使用命令权限执行系统操作

有些命令普通用户并没有执行的权限，那么怎么让某一个用户拥有执行这些命令的权限呢？

修改/etc/sudoers文件来赋予用户操作系统的权限：可使用命令visudo 直接跳到该文件编辑

配置文件内容：

root ALL=(ALL)  ALL 

第一个参数-用户名，第二个参数-用户从哪儿登录-主机IP地址/prefix，第三个参数-以什么身份运行，最后一个参数-哪些命令-命令的绝对路径，通过逗号分割

这样修改太过麻烦暴力，可以通过将用户加入到wheel组中来实现赋予普通用户系统级权限。

armandhe ALL=(root) NOPASSWD:/usr/passwd [a-zA-z]* ,!/usr/passwd root //不需要输入当前用户密码即可执行passwd命令 不允许修改root用户的密码

armandhe ALL=(root) /usr/ifconfig,! /usr/ifconfig [a-zA-Z]* down //可以更改IP地址，不可以关闭网卡

修改之后，切换到用户armandhe，通过在命令前面添加sudo 来获取root用户的执行权限。

# 打包与解压

## 说明

.zip、.rar        //windows系统中压缩文件的扩展名
.tar              //Linux中打包文件的扩展名
.gz               //Linux中压缩文件的扩展名
.tar.gz           //Linux中打包并压缩文件的扩展名

zcat compress_file //查看压缩文件的内容

gzip -d a.txt.gz //解压

gzip -c a.txt > a.txt.gz //保留源文件

tar -xf jack.txt.tar -C /tmp/  //解压另存为

tar -cft jack tar a.txt b.txt // 列出包中文件

## 打包文件

tar -zcvf 打包压缩后的文件名 要打包的文件
  参数说明：z：调用gzip压缩命令进行压缩; c：打包文件; v：显示运行过程; f：指定文件名;
  示例：
 tar -zcvf a.tar file1 file2,...      //多个文件压缩打包

## 解压文件

tar -zxvf a.tar                      //解包至当前目录
tar -zxvf a.tar -C /usr------        //指定解压的位置

zip [a.txt.zip](http://a.txt.zip) a.txt
unzip test.zip             //解压*.zip文件
unzip -l test.zip          //查看*.zip文件的内容

# 其他常用命令

## find

find . -name "*.c"     //将目前目录及其子目录下所有延伸档名是 c 的文件列出来
find . -type f         //将目前目录其其下子目录中所有一般文件列出
find . -ctime -20      //将目前目录及其子目录下所有最近 20 天内更新过的文件列出
find /var/log -type f -mtime +7 -ok rm {} \;     //查找/var/log目录中更改时间在7日以前的普通文件，并在删除之前询问它们
find . -type f -perm 644 -exec ls -l {} \;       //查找前目录中文件属主具有读、写权限，并且文件所属组的用户和其他用户具有读权限的文件
find / -type f -size 0 -exec ls -l {} \;         //为了查找系统中所有文件长度为0的普通文件，并列出它们的完整路径

find / -size +2M //查找大于两兆的文件

find / -size -2K //查找小于2k的文件

ls | xargs wc //将前面的命令的执行结果作为后一个命令的参数

## whereis

whereis ls //将和ls文件相关的文件都查找出来，命令所在目录以及手册所在目录

## which

说明：which指令会在环境变量$PATH设置的目录里查找符合条件的文件。
  which bash             //查看指令"bash"的绝对路径

## sudo

说明：sudo命令以系统管理者的身份执行指令，也就是说，经由 sudo 所执行的指令就好像是 root 亲自执行。需要输入自己账户密码。
使用权限：在 /etc/sudoers 中有出现的使用者
sudo -l                              //列出目前的权限
$ sudo -u yao vi ~www/index.html    //以 yao 用户身份编辑  home 目录下www目录中的 index.html 文件

## grep

grep -i "the"  demo_file              //在文件中查找字符串(不区分大小写)
grep -A 3 -i "example"  demo_text     //输出成功匹配的行，以及该行之后的三行苏
grep -r "ramesh"  *                   //在一个文件夹中递归查询包含指定字符串的文件

grep -E //使用扩展正则表达式

grep -o //输出匹配部分

egrep //扩展正则表达式

grep -c //输出匹配到的行

## service

说明：service命令用于运行System V init脚本，这些脚本一般位于/etc/init.d文件下，这个命令可以直接运行这个文件夹里面的脚本，而不用加上路径
service ssh status      //查看服务状态
service --status-all    //查看所有服务状态
service ssh restart     //重启服务

## free

说明：这个命令用于显示系统当前内存的使用情况，包括已用内存、可用内存和交换内存的情况 
  free -g            //以G为单位输出内存的使用量，-g为GB，-m为MB，-k为KB，-b为字节 
  free -t            //查看所有内存的汇总

`free -s N //每N秒打印一次`

`free -c  N  //打印N次后停止`

## top

top //显示当前系统中占用资源最多的一些进程, shift+m 按照内存大小查看

## df

说明：显示文件系统的磁盘使用情况
  df -h            //一种易看的显示

## mount

mount /dev/sdb1 /u01              //挂载一个文件系统，需要先创建一个目录，然后将这个文件系统挂载到这个目录上
dev/sdb1 /u01 ext2 defaults 0 2   //添加到fstab中进行自动挂载，这样任何时候系统重启的时候，文件系统都会被加载 0是否检查 2转换

## uname

说明：uname可以显示一些重要的系统信息，例如内核名称、主机名、内核版本号、处理器类型之类的信息 
  uname -a

uname -r //内核版本

uname -m //架构

uname -s //设备类型

uname -o //操作系统

unam -n //node信息，用户名

## yum

说明：安装插件命令
  yum install httpd      //使用yum安装apache 
  yum update httpd       //更新apache 
  yum remove httpd       //卸载/删除apache

## rpm

说明：插件安装命令
rpm -ivh httpd-2.2.3-22.0.1.el5.i386.rpm      //使用rpm文件安装apache
rpm -uvh httpd-2.2.3-22.0.1.el5.i386.rpm      //使用rpm更新apache
rpm -ev httpd                                 //卸载/删除apache

## date

date -s "01/31/2010 23:59:53" ///设置系统时间

## wget

说明：使用wget从网上下载软件、音乐、视频
示例：wget [http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.2.1.tar.gz](http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.2.1.tar.gz)
//下载文件并以指定的文件名保存文件
wget -O nagios.tar.gz [http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.2.1.tar.gz](http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.2.1.tar.gz)

## ftp

ftp IP/hostname    //访问ftp服务器
mls *.html -       //显示远程主机上文件列表

## scp

scp /opt/data.txt 192.168.1.101:/opt/ [//将本地opt目录下的data文件发送到192.168.1.101服务器的opt目录下](https://xn--optdata192-8i2pi2g2vp1vfuto6zssin290ai4g046fs2bd94w.168.1.xn--101opt-np7i262axyi7ix4mtpn6bqeb/)安全的拷贝

# 系统管理

## 防火墙操作

service iptables status      //查看iptables服务的状态
service iptables start       //开启iptables服务
service iptables stop        //停止iptables服务
service iptables restart     //重启iptables服务
chkconfig iptables off       //关闭iptables服务的开机自启动
chkconfig iptables on        //开启iptables服务的开机自启动
##centos7 防火墙操作
systemctl status firewalld.service     //查看防火墙状态
systemctl stop firewalld.service       //关闭运行的防火墙
systemctl disable firewalld.service    //永久禁止防火墙服务
x

## 修改主机名

hostnamectl set-hostname 主机名

## 查看ip

ifconfig

## 修改IP

修改网络配置文件，文件地址：/etc/sysconfig/network-scripts/ifcfg-eth0

主要修改以下配置：
TYPE=Ethernet //网络类型
BOOTPROTO=static //静态IP
DEVICE=ens00 //网卡名
IPADDR=192.168.1.100 //设置的IP
NETMASK=255.255.255.0 //子网掩码
GATEWAY=192.168.1.1 //网关
DNS1=192.168.1.1 //DNS
DNS2=8.8.8.8 //备用DNS
ONBOOT=yes //系统启动时启动此设置

修改保存以后使用命令重启网卡：service network restart

## 配置映射

修改文件： vi /etc/hosts
在文件最后添加映射地址，示例如下：
192.168.1.101  node1
192.168.1.102  node2
192.168.1.103  node3
配置好以后保存退出，输入命令：ping node1 ，可见实际 ping 的是 192.168.1.101。

## 查看进程

ps -ef //查看所有正在运行的进程

## 结束进程

kill pid       //杀死该pid的进程
kill -9 pid    //强制杀死该进程

## 查看连接

ping IP        //查看与此IP地址的连接情况
netstat -an    //查看当前系统端口
netstat -antplu | grep 8080     //查看指定端口

## 快速清屏

ctrl+l //清屏，往上翻可以查看历史操作

## 远程主机

ssh IP       //远程主机，需要输入用户名和密码

# 颜色与类型的关系

[Untitled](Untitled%2089612a0e61964bd0bcf641f9d74c2bb9.csv)

[Untitled](Untitled%20daabe5b96d5f4c8c86a5fe8a42c2f598.csv)

[linux中$符号的基础用法总结_Linux_脚本之家](https://www.jb51.net/article/174033.htm)

!! 最后一条命令
`!$` 将上一条命令的参数应用于这一条
^R 查找命令

su切换用户时加-与不加的区别
加-：会加载切换用户的shell环境，运行的的login shell 运行 /etc/profile /etc/bashrc  ~/.bashrc ~/.bash_profile (~/.bash_history-历史命令 ~/.bash_logout-可以写入命令在退出用户时执行)退出时运行
不加-：不会加载用户的shell环境，运行的是nologin shell /etc/bashrc ~/.bashrc  (~/bash_history ~/bash_logout)退出时运行

ls | tee a.txt 与| a.txt的区别tee管道不会截流，命令结果仍然或输出到屏幕

/etc/profile //系统启动的时候才执行一次，之后不再执行，其中主要定义一些环境变量

~/.bashrc  //当前用户每新开一个shell就执行一次 ，其中主要定义别名之类的信息

系统开机时首先去执行/etc/profile文件，然后根据其中的内容到/etc/profile.d/中读取额外的设定文档。然后读取/etc/bashrc的内容。然后根据登录用户的信息去对应的家目录读取~/.bash_profile，如果不能读取则去读取~/.bash_login，如果仍不能读取则去读~/.profile中的内容，这三个文件中的内容基本一致。然后读取~/.bashrc中的内容
`eject //弹出挂载的光盘`

## **shell 脚本中使用python脚本**

```bash
/usr/bin/python <<-a
print("armandhe")
a
\ls //不使用别名输出，例中将运行结果将不显示颜色 
unalias ls //取消ls的别名
```

`echo -e "\e[1;31m this is a test to change fg color \e[0m" //30-37 前景色
echo -e "\e[1;40m this is a test to change fg color \e[0m" //40-47 背景色`

./a.sh
bash a.sh
子shell执行
. a.sh
source a.sh
当前shell执行
^k //删除光标后的内容
^a //回到命令开头
^e //回到命令结尾
^b //光标向前移动一格
^n //清空当前命令
^h //退格删除
read -p "please type ip addr: " ip //提示用户输入
id username //判断用户是否存在

$? //上一条命令执行的结果 执行陈工为0

env //显示当前所有的环境变量

expr $num1 + $num2    expr 1 + 2
[ 1 + 2 ] 
echo $(($num1 + $num2))
echo $((num1 + num2))

```bash
url=[www.baidu.com.cn](https://www.notion.so/www.baidu.com.cn)
echo ${url#*.} //baidu.com.cn 从前往后删除匹配部分，非贪婪匹配
echo ${url##*.} //cn 从前往后删除匹配部分，贪婪匹配
echo ${url%.cn} // [www.baidu.com](https://www.notion.so/www.baidu.com) 从后往前删除匹配部分，非贪婪匹配
echo ${url%%.*} //www 从王往前删除匹配部分，贪婪匹配
echo ${url/c/C} //[www.baidu.Com.cn](https://www.notion.so/www.baidu.Com.cn) 内容替换替换单个
echo ${url//c/C} //[www.baidu.Com.Cn](https://www.notion.so/www.baidu.Com.Cn) 内容替换，替换多个
```

unset var
echo ${var-aaaa} //变量未被定义，var的值被替换为aaaa

var=1
echo ${var-aaaa} //var有值，其值不能被替代

var=
echo ${var-aaa} //var被定义过，其值不可被提到

var=
echo ${var:-aaaa} //var被定义过，但为空，其值被替代为aaaa

`+ :+
=  :=
? :？`

let i++
let ++i
let --i
let I--

```bash
for i in {1..5} #集合
do
    echo 2345
done   //循环执行五次

date）//在子shell中执行
```

((1<2)) //使用< > 等符号进行比较
touch $(date +%F)_file.txt //命令替换与``效果一致
$((1+2))
test 1 -eq 2 //条件测试
[ 1 -eq 2 ] //条件测试
`[[[www.baidu.com](https://www.notion.so/www.baidu.com) =~ *baidu]] //条件测试 正则比较未测试成功` 正则比较必须用这种格式
=~ //按照正则方式匹配
$[1 + 2] //整数运算
{} //集合{1..8}
${} //使用变量，定界
`export a=1 //环境变量`

sh -vx a.sh //以调试的方式执行
sh -n a.sh //仅调试语法测试

seq 10 //生成一个1-10的序列

seq 1 10 //生成1-10的序列

seq 1 2 10 //以2为步长生成1-10的序列

userdel -rf a //删除用户及其家目录

## 更改centos镜像源

首先备份原镜像配置文件

cp /etc/yum.repos.d/centos-base.repo /etc/yum.repos.d/centos-base.repo.bak

cd到/etc/yum.repos.d

下载你的镜像配置文件

wget [http://domain](http://domain)  

## 安装中文输入法

apt-get install fcitx -y //安装输入法框架

apt-get install fcitx-googlepinyin

reboot

搜索fcitx将谷歌拼音设置为首选输入法

# 磁盘管理

[Linux 磁盘管理](https://www.runoob.com/linux/linux-filesystem.html)

[磁盘管理](%E7%A3%81%E7%9B%98%E7%AE%A1%E7%90%86%2062b6eff0337a41abbeeec6c6025fb791.csv)

# 磁盘管理

## raid-独立磁盘冗余整列

分为软件整列与硬件整列

raid0 

数据写入的时候，被分成N块，同时并发写入不同的磁盘，没有校验机制，一个磁盘损坏所有磁盘就算坏了，高效

raid1

数据被复制n份，同时写入不同的磁盘，速度慢

raid3

数据被分成n份写入，添加了校验机制，一块磁盘单独来保存校验信息，一块磁盘损坏可通过校验信息来回复。校验磁盘损坏后就失去了回复的能力

raid5

数据被分成n份写入，每一块磁盘中都包含了属于其他磁盘的校验信息，当一块磁盘损坏了，就可以根据其他磁盘回复数据

raid6

数据被分成n份写入，在raid5的基础上添加了双重校验功能，每一个磁盘都有了两份校验数据

raid10

先将数据复制两份，每一份再按照raid0的方式存储

磁盘

柱面 磁头 扇区 块 分区

分区 

**mbr** ：4个分区，3个主分区+1个逻辑分区 扇区 512字节 0号扇区中包括226字节的bootloader 64字节的分区表，2字节的表值 一个分区占用16字节，故最多只能有4个分区，最多有2**16*4个扇区，2**16*512*4 字节的存储空间。

**gpt：**第一个扇区定义了分区的数量等信息，第二个扇区为分区表头，第三个扇区开始为分区表，gpt分区一般有32个扇区的分区表，一个扇区可以有4个分区信息，那么一个分区就有128位，故一共可以有128个分区，所以基本上不会有分区大小与分区数量的限制。

硬盘接口类型

ide sata scsi sas等接口

查看分区信息

partx /dev/sda //

cat /proc/partitions //显示分区信息

partprobe /dev/sda //重新加载硬盘信息

linux vfs-虚拟文件系统。对底层文件系统的抽象，用户使用该文件系统操作文件

## 硬盘分区步骤

分区

格式化文件系统

挂载：临时挂载，永久挂载-修改/etc/fstab

mount -a //重读挂载表

## 交换分区

内存中不常用的数据可放在交换分区中，window中叫做虚拟内存

m //查看帮助

fsdisk /dev/sda

分区

t  // 输入分区编号为82，通看分区类型，82为交换分区

重新加载分区表 partprobe /dev/sda

mkswap /dev/sda3 //创建交换分区

swapon  /dev/sda3 //开启交换分区

swapoff /dev/sda3 //关闭交换分区

## 磁盘挂载配置文件

进入/dev/fstable

/dev/mapper/centos-root / xfs defaults 0 0 

设备文件 挂载点 文件系统类型 挂载选项 检测顺序0表示不检测 转存

mount -a //重读挂载表

## LVM-logic volume manager 逻辑卷管理器

将不同的硬盘逻辑划分为不同的分区

pv-物理卷 整块物理硬盘或者他上面的分区

pe-物理区域  extent 

vg-卷组

lv-逻辑卷

le 逻辑区域

卷组描述区域

### 创建逻辑卷过程

1. 创建物理卷
    
    pvcreat /dev/sda1
    
    pvcreat /dev/sda2
    
2. 创建卷组
    
    vgcreat volumegroupname /dev/sda{1,2}
    
3. 创建逻辑卷
    
    lvcreat -L|—size volumesize vgname -n lvname
    

格式化逻辑卷

mkfs.ext4 /dev/vgname/lvname

mkfs -t ext4 /dev/vgname/lvname

挂载

mount /dev/vgname/lvname 挂载点

扩展逻辑卷

lvextend -L +extendsize /dev/vgname/lvname

扩展文件系统

resize2fs /dev/vgname/lvname

扩展卷组

vgextend vgname /dev/sda3

制作快照分区

lvcreate -L lvsize -n snapshot-lvname -s(指定为快照卷) lvname

挂载快照卷

mount -r /dev/vgname/lvname 挂载路径

### 备份数据

**备份类型**

冷备-离线备份

温备-只读备份

热备-读写备份

几乎热备

快照卷的大小是数据变化的大小

拍摄了快照之后，当原卷发生变化的时候，快照将获取变化信息，并进行写入快照。写时复制。

**备份过程-几乎热备**

首先锁定要备份的文件，然后拍摄快照，然后解锁，然后根据快照对数据进行备份。

## inode-索引节点

[Linux的inode的理解_猿子-CSDN博客_inode](https://blog.csdn.net/xuz0917/article/details/79473562)

磁盘的最小存储单位叫做扇区，操作系统的最小操作单位叫做块，一个块由8个扇区组成。一个扇区512bytes，所以一个块4k

文件数据存储在块block中，其他如时间、创建者等信息储存在另一个区域，这个存储文件元信息的区域就叫做inode，即索引节点。

**其中包含**

文件的大小

uid

gid

权限

时间戳：访问、修改、inode变动时间

links

inode号码

blocks数

ioblock块大小

设备号码

一个inode节点的大小一般是128或者256字节，在格式化的时候一般时每1kB或者2kB就设置一个inode节点。

每个inode都有一个号码，操作系统通过inode号码来识别不同的文件而不是文件名

ls -i a.txt//查看inode信息

df -i //查看磁盘inode信息

stat a.txt //查看文件元数据

**普通文件**

系统通过文件名找到文件的inode号码，然后哦那个过inode号码获取inode信息，根据inode信息，找到数据所在的block,从而获取信息

**目录文件**

目录文件中是一系列目录项的列表，每个目录项里包括两部分，所包含的文件名以及文件名对应的inode号码

**硬链接**

源文件与目标文件都指向同一个inode,删除一个文件并不会整的删除文件信息，只有当所有的文件名都被删除后，文件才真正被删除。inode节点信息中的links就表示指向同一文件的文件名的个数。

创建目录时会生成两个目录项.和..。所以任何一个目录的连接数都等于2加上他的子目录的总数包括隐藏目录

**软连接**

软连接目标文件的文件内容是指向文件的路径，当系统访问目标文件的时候，目标会见会将访问者导向前一文件。

# 网络管理

ifconfig -a //显示所有的网卡，包括down掉得

ifconig ens33 ip/prefix broadcast down/up

ifconfig ens33:0 ip/prefix up|down

ifconfig ens33 hw ether macaddr //修改mac次啊hi

ifconfig ens33 add ipv6/ 64

ifconfig ens33 arp

ifconfig ens33 -arp

ifconfig ens33 mtu 1500

ifconfig ens33 up

ifconfig ens33 down

route -n //数字形式显示
-net //网络路由

-host //主机路由

route add -net 100.100.100.0/24 gw net_skip_addr

route add -host 100.100.100.100 dev 网卡名

route add default gw net_skip_addr

route add -net 0.0.0.0/0 gw net_skip_addr

route del -net 网段 netmask 子网掩码 reject //设置目标网段不可达

del //删除

/etc/resolv.conf //域名地址

netstat -r //查询路由

netstat -n //不解析成主机名

netstat //解析成主机名

netstat -tn //tcp

netstat -un //udp

netstat -ln //监听状态

netstat -a //监听状态与建立连接状态

netstat -p //启动该端口的进程

curl http://www.baidu.com

ab -n 10000 -c 100 [http://127.0.0.1/](http://127.0.0.1/) //压力测试，

ip link show

ip link set ens33 up

ip link set ens33 down

ip link set ens33 promisc on

ip link set ens33 promisc off

ip link set ens33 txqueuelen 

ip link set ens33 mtu 1500

ip add show

ip addr add ipaddr/prefix dev ens33

ip addr del ipaddr/prefis dev ens33

ip route show

ip route add 192.168.10.0/24 via 192.168.10.254 dev ens33

ip route add default via net_skip_addr //添加默认路由

ip route del 192.168.10.0/24 dev ens33 //删除路由

ip route del 192.168.10.0/24 //删除网关

## 网络命名空间

所谓命名空间可以理解未更为抽象的作用域，他将不同的区域隔离开来，两个区域中相互之间互不影响，再不同的网络命名空间中有独立的协议栈、网络设备、防火墙等。

ip netns add netnamespace_name  //添加一个命名空间

ip netns set netnamespce_name netnid //未命名空间设置id

ip netns del netnamespace_nam //删除

ip netns -all del //删除所有

ip netns exec netnamespace_name command //再网络命名空间中执行命令

ip netns -all exec command //再所有的命名空间中执行命令

ip netns list //列出所哟䣌命名空间

ip netns identifu pid //某一个进程的netns

ip netns monitor //监控对netns的操作

在网络命名空间中虚拟网卡是成对出现的，一个存在命名空间内，一个存在于全局命名空间内，两者将网络命名空间与外部命名空间连接了起来。

ip link add veth0 type veth peer name veth1 //创建一对虚拟网卡

ip link set veth1 netns ns1 //将veth1移动到ns1命名空间中去

ip netns exec ns1 ip addr add 192.168.1.1/24 dev veth1 //为veth1配置ip

ip netns exec ns1 ip link set veth1 up //开启veth1

ip netns exec ns1 ip link set lo ip //开启环回网卡,此时可以ping 通自己

ip addr add 192.168.1.2/24  dev veth0//配置veth0的ip

ip link set veth0 up //开启veth0

ip netns exec ns1 ip route add default via 192.168.1.1 //配置默认路由 //此时可以和本地主机通信，但不能和其他主机通信,还需要配置ip转发

cat /proc/sus/net/ipv4/ip_forward //查看是否开启了ip转发，值为1表示开启，值为0表示关闭

echo 1 > /proc/sys/net/ipv4/ip_forward //配置转发使能

iptables -F FORWARD

iptables -t nat -F //刷新forward规则

iptables -t nat -L -n //刷新nat规则

iptables -t nat -A POSTROUTING -s 192.168.1.0/255.255.255.0 -o ens33 -j MASQUERADE //使能ip伪装

iptables -A FORWARD -i ens33 -o veth0 -j ACCEPT

iptables -A FORWARD -i veth0 -o ens33 -j ACCEPT

![](Untitled.png)

/etc/sysconfig/network //配置本机的主机名 ，HOSTNAME=armandhe

/etc/hostname //配置主机名，armandhe

# 软件包管理

**yum配置文件**

[id]

name=自定义名称

baseurl=仓库路径

             file:///mnt/cdrom //本地仓库

enabled=是否可用，0，1

gpgcheck=是否开启校验 0，1

一个yum仓库中必须要有一个repodata 文件，其中定义了所有rpm包的信息

yum list //列出仓库中所有的包

yum info 包名 //显示包信息

yum groupinstall 包组

yum repolist 列出仓库列表

yum install 包名

yum update package_name

yum remove package_name

yum deplist package_name //查看包的依赖关系

yum reinstall package_name //重新安装一个包

yum groupremove 包组名 //删除包组

yum search string //根据指定字符串搜索包

yum -y groupinstall "Development Tools" //安装常用开发工具

**源码安装**

在源码目录执行 ./configure —prefix=/usr/local/software_name [//prefix](//prefix) 指定安装路径。执行该命令会生成makefile文件，该文件中包含编译顺序等信息。configure会检查当前环境，是否有cc gcc等。cc是unix的已收费，gcc更加强大，linux中的cc是gcc的符号连接。

make //编译源码

make install //安装软件

/usr/lib/systemd/system/httpd.service [//systemctl](//systemcel) 执行配置文件

# 防火墙

## 防火墙分类

主机防火墙

网络防火墙

软甲防火墙

硬件防火墙

4层防火墙 //基于端口，ip等

7层防火墙 //应用层防火墙，基于7层协议，waf

linux的防火墙，是通过底层的netfilter来过滤数据的，iptables与firewalld是用来配置i过滤规则的。

# iptables

## 四表五链

**四表**

raw //数据追踪

mangle //拆解报文，重新封装

nat  

filter

**五链**

input //入站规则

forward //转发链

output //出站规则

prerouting //路由之前对数据进行改变，对目标地址做转换

postrouting //路由之后对数据进行改变，对源ip地址做转换

**数据过链顺序**

流入：prerouting —> input 

流出：ouput —> postrouting

转发：prerouting —> forward —> postrouting

**FILTER表**

```bash
iptables -t filter -nvL
iptables -t filter | FILTER  2 -s 0.0.0.0/0 -d 0.0.0.0/0 -j DROP -p tcp
iptables -D FORWARD 2 #删除forward链第二条
iptables -F FORWARD #删除forward链中所有规
iptables -P FORWARD DROP|ACCEPT #设置默认策略
iptables -save > /tmp/a.txt #导出规则
iptables -restore < /tmp/a.txt #导入规则
service iptables save #保存当前规则为默认规则

target: accept|drop|reject|log #大写 放行|丢弃|拒绝|记录日志
	-I : insert #插入到表的最上方
	-A : append #插入到表的最下方
	#可加入数字表示添加到第几条
	-n : #以数字形式显示
	-L ： #列出所有规则
	-v ： #详细信息
	--dport
	--sport
	—line-numbers #显示规则序号
	-i : #指定入口
	-o : #指定出口
	-m mutiport --dports 22,80,443 #多端口匹配
	--dports #指定多个目标端口
iptables -t filter -A input -s ens33 --dport 22 -I -j reject -p tcp
iptables -P input ACCEPT
	--sports #指定多个源端口
	-j #允许还是拒绝
	-N #新建一个链
	-s #源地址
	-d #目标地址
	-vv #显示更详细的信息
	-F # 清空所有规则
	-m #后接模块名 ,使用扩展iptables
	-m iprange --src-range 172.16.11.13-171.16.11.100
	-m iprange --dist-range #匹配ip地址范围
	-m string --algo mb --string "gxa" #匹配字符串
	-m connlimit-upto
	-m connlimit-above 
	-m state --stat NEW|ESTABLISHED #状态检测

```

**NAT表**

四链

```bash
postrouting
prerouting
output
input
```

iptables -t nat -A POSTROUTING -p tcp -o eth0 -s 192.168.10.23/24 -j SNAT —to-source 12.34.54.45/24

-j SNAT|DNAT //端口复用与端口映射

# firewall-cmd

firewall-cmd —version

firewall-cmd —state

firewall-cmd —zone=public —list-ports //查看已打开的端口

firewall-cmd —zone=public —add-port=80/tcp —permanent //开放tcp80端口并永久生效

firewall-cmd —reload //开放了端口后，重新加载配置

firewall-cmd —zone=puublic —remove—port=80/tcp —permanent //关闭80端口

firewall-cmd —get-zones //获取所有的可用区域

也可以直接修改配置文件

/etc/firewall/zones/public.xml

# 正则表达式

通配符：匹配文件名

正则表达式：匹配文件内容

**grep**

标准正则

逐行匹配，匹配的显示整行

-i 忽略大小写

-o 仅显示匹配字符

-v 反向显示

-A  3    after //显示匹配项及之后几行

-B 4     before //显示匹配项前面的几行

-C 4    context //显示前后几行

\? //0次或者1次

\+

\{\}

\> //词尾

\< //词首

扩展正则

grep -E

不需要转义，可加 | 等

sort -t: -k3 -r -n a.txt
-t 指定分隔符

-k 指定字段

-r 指定为逆序

-n 指定按数字排序

# 进程管理

进程类型

守护进程：开机后启动并一直运行再后台得进程

瞬时进程：命令执行完就结束进程

用户进程

进程优先级

1-99 实时优先级

100-139 静态优先级 //值越大优先级越高

进程的状态

running 运行态 R

ready 就绪

sleep 睡眠态：S可中断进程，d不可中断进程

stopped 停止态

zombie 僵死态 父进程挂掉了，子进程的状态

session leader

+ 前台进程

l 多线程进程

ps -aux

ps -ef

pstree

-a

-u

-x

pgrep -u 0 //根据用户显示进程

pidof httpd //与命令相关的所有进程号

pkill pid //杀进程

uptime

vmstat

procs

kill -singal

singalup 1 //重读配置文件

singalnt 2 //变比进程

sig'kill 9 //强杀

sigterm 15 //正常结束

sigcont 18 //继续执行

sigstop 19 //暂停执行

killall process_name //杀死进程

nohup //脱离当前中断

& //调用到后台执行

定时任务

一次执行

at option

at -l //查看任务

at -f /path/to/file

atrm 1 //删除定时任务

at 4am tomorrow

周期执行

crontab

/etc/crontab

crontab -e //编辑设置定时任务

crontab -l //列出任务

crontab -r  //移除所有任务

crontab -u //指定用户

`/var/spool/cron/username` //定时任务都在这儿

***** 分钟-小时-日-月-星期

![](Untitled%201.png)

![](Untitled%202.png)

![](Untitled%203.png)