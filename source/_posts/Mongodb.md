---
title: Mongodb
tags:
  - Mongodb
  - 数据库
categories:
  - - 安全技术
  - - 数据库
description: 本文介绍了 数据库 的相关知识点
abbrlink: '20475214'
date: 2025-04-10 20:56:11
---
# Mongodb

# 数据库安装

安装完成后需要手动创建数据目录，但这个目录不会自动创建，需要手动创建，数据目录默认存储在dn目录下，最好创建在根目录下

cd d\

md "\data\db"

添加环境变量：将mongodb的安装目录下的bin目录添加到环境变量

mongod —dbpath d:\data\db //指定数据目录

创建日志目录

cd d:\

mkdir d:\data\log

配置数据目录与日志目录

在mongodb的安装目录中创建mogod.cfg文件，向里面写入一下内容：

```
systemLog:
    destination: file
    path: d:\data\log\mongod.log
storage:
    dbPath: d:\data\db
```

# 安装mongodb服务

mongod —config "d:\EXE\mongodb\mongodb.cfg" —install

# 基本操作

**启动服务**

net start mongodb

**停止服务**

net stop mongodb

**启动数据库**

mongod

**登录默认用户**

mongo

**账号用户名登录**

mongo —port 27017 -u admin -p yourpassword

**连接数据库**

连接一台服务器

mongodb://username:password@hostname:port/[databasename][?options]

mongodb://host1,host2,host3/?safe=true;w=2;wtimeoutMS=2000

//连接到三台服务器，并至少等待两台复制服务器写入成功，超时时间2s

mongodb://host1,host2,host3/?connect=direct,slaveOK=true

//直连到第一台服务器，不区分第一台服务器是主服务器还是从服务器

# 数据库操作

**创建数据库**

use databasename //使用数据库，如果数据库不存在则创建数据可

**查看当前数据库**

db

**查看所有数据库**

show dbs

**删除数据库**

db.dropDatabase()

**创建集合**

db.createCollection(name,option)

option: capped=true 创建固定集合，有固定的大小，当达到最大值的时候自动覆盖最早的文档

size ,指定固定集合的最大值，字节

max,固定集合中包含文档的数量

集合不是必须创建的，执行

db.collectionname.insert()

当执行上述命令的时候，将自动创建集合

手动创建的集合必须在插入数据之后才会真正 生效。

**查看当前数据库中的集合**

show collections

show tables

**删除集合**

db.collectionname.drop()

**插入文档**

db.collectionname.insert({

"name":"hjx",

"age":"25"

})

db.collectionname.insertOne({})

db.collectionname.insertMany([{}，{}],{

writeConcern:1 //写入策略，1为要求确认写操作

ordered:true //是否按顺序插入

})

**插入多个文档**

db.collectionname.save({}) //如果指定了_id字段，则更新文档

**更新文档**

db.collection.update({条件}，{目标}，{

upsert:true //如果不存在记录，是否插入

mutil: true //是否更新所有匹配记录

writeConcern: //抛出异常的级别

})

**删除文档**

db.collection.remove(

{条件},

{

justone: true //是否只删除第一条匹配记录

writeConcern:

}

)

db.collectionanme.remove({}) //删除所有文档

**查询文档**

db.collcetionname.find({条件}).pretty()

db.collectionname.findOne()

比较运算符

$lt

$gt

$lte

$gte

$ne

逻辑运算符

$or

`db.collectionname.find({"name":"何纪雄","age":{$lt:30},$or:[{"gender":"man"},{"gender":""female}]}) [//and](//and) or`

通过类型查询

db.collectionname.find({"name":{$type:"string"}})

db.collectionname.find().limit(1)

db.collectionname.find().skip(1)

db.collectionname.find().sort({"key":1}) [//1](//1) 升序 -1 降序

db.collectionname.createIndex({"keys":1}) [//1升序](//1升序) -1 降序

**聚合**
```shell
db.collectionname.aggregate([{$group:{_id:"$name",别名:{$sum:"$字段"}}}])

$sum

$avg

$min

$max

$push //将结果文档插入到一个数组中

$addToSet //将结果文档插入到一个数组中，但不创建数组

$first //获取结果文档按序排列的第一个文档

$last //获取结构文档按序排列的最后一个文档
```

**管道**

$project

$match

$limit

$skip

$unwind

$group

$sort

$geoNear

db.collcetionname.aggregate([{管道1}，{管道2}])

# MongoDB复制

MongoDB复制是将数据同步在多个服务器的过程。

复制提供了数据的冗余备份，并在多个服务器上存储数据副本，提高了数据的可用性， 并可以保证数据的安全性。

复制还允许您从硬件故障和服务中断中恢复数据。

## 复制原理

mongodb的复制至少需要两个节点。其中一个是主节点，负责处理客户端请求，其余的都是从节点，负责复制主节点上的数据。

mongodb各个节点常见的搭配方式为：一主一从、一主多从。

主节点记录在其上的所有操作oplog，从节点定期轮询主节点获取这些操作，然后对自己的数据副本执行这些操作，从而保证从节点的数据与主节点一致。

## 副本集设置

**以副本集的方式启动mongodb**

mongod —port 27017 —dbpath "dbfile_path" —replSet "副本集"//副本集自行命名

**登录mongodb**

mongo -u admin -p password

**启动一个新的副本集**

rs.initiate()

**查看副本集的配置**

rs.conf()

**查看副本集的状态**

rs.status()

**向副本集中添加成员**

rs.add(172.14.12.34:27017)

**判断当前是否为主节点**

db.isMaster()

MongoDB的副本集与我们常见的主从有所不同，主从在主机宕机后所有服务将停止，而副本集在主机宕机后，副本会接管主节点成为主节点，不会出现宕机的情况。

# 备份数据

mongodump -h dbhost -d dbname -o backupdirectory

# 恢复数据

mongorestore -h hostname:port -d dbname backup_data_path

查看mongodb运行状态

在命令行输入mongostat

查看mongodb集合的读写耗时

在命令行输入mongotop

# MongoDB关系

ongoDB 的关系表示多个文档之间在逻辑上的相互联系。

文档间可以通过嵌入和引用来建立联系。

MongoDB 中的关系可以是：

- 1:1 (1对1)
- 1: N (1对多)
- N: 1 (多对1)
- N: N (多对多)

接下来我们来考虑下用户与用户地址的关系。

一个用户可以有多个地址，所以是一对多的关系。

嵌入式关系

将数据直接嵌入到一个域中

```json
{
   "_id":ObjectId("52ffc33cd85242f436000001"),
   "contact": "987654321",
   "dob": "01-01-1991",
   "name": "Tom Benzamin",
   "address": [
      {
         "building": "22 A, Indiana Apt",
         "pincode": 123456,
         "city": "Los Angeles",
         "state": "California"
      },
      {
         "building": "170 A, Acropolis Apt",
         "pincode": 456789,
         "city": "Chicago",
         "state": "Illinois"
      }]
}
```

查询方法：db.users.findOne({"name":"Tom Benzamin"},{"address":1})

应用式关系

将文档的objectid浅入到域中

```json
{
   "_id":ObjectId("52ffc33cd85242f436000001"),
   "contact": "987654321",
   "dob": "01-01-1991",
   "name": "Tom Benzamin",
   "address_ids": [
      ObjectId("52ffc4a5d85242602e000000"),
      ObjectId("52ffc4a5d85242602e000001")
   ]
}
```

这种方法需要两次查询

```json
>var result = db.users.findOne({"name":"Tom Benzamin"},{"address_ids":1})
>var addresses = db.address.find({"_id":{"$in":result["address_ids"]}})
```