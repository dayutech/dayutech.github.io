---
title: Java HashMap 实现方法
tags:
  - Java
  - HashMap
categories:
  - Java
top: 220
abbrlink: 31bfcb8f
date: 2025-05-16 10:19:27
---
# 成员变量含义
| 变量名 | 默认值     | 含义                                                                                    |
|-----|---------|---------------------------------------------------------------------------------------|
|   DEFAULT_INITIAL_CAPACITY  | 16      | 默认初始化容量                                                                               |
|MAXIMUM_CAPACITY| 1 << 30 | 最大容量                                                                                  |
|DEFAULT_LOAD_FACTOR| 0.75    | 默认加载因子，当数组中元素数量超过总长度的0.75的时候会进行自动扩容                                                   |
|TREEIFY_THRESHOLD| 8       | 当链表长度超过8的时候会将链表转换为红黑树                                                                 |
|UNTREEIFY_THRESHOLD| 6       | 当链表元素少于6的时候会将红黑树转换为链表                                                                 |
|MIN_TREEIFY_CAPACITY| 64      | 只有当数组长度大于64的时候才会执行链表的树化，因为链表树化会增加空间复杂度，如果只要某一个链表长度超过8就进行树化得到的查询时间优化与增加的空间消耗两相比较是得不偿失的 |
# 对象创建
包含三个重载方法，可提供对初始化容量以及加载因子的指定。不过一般使用无参构造方法就行
#  put方法
```java
public V put(K key, V value) {
    // 首先调用hash方法计算key的hash值
        return putVal(hash(key), key, value, false, true);
    }
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
    // tab 通过key的hash索引的数组  p Node类型 表示链表的一个节点
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        // 通过无参构造方法创建时 table 为被指定大小，则调用resize方法被设置为初始化大小 16
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length;
        // 如果hash对应的索引未知为空 则直接创建一个新的链表节点放到该未知
        if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);
        else {
            Node<K,V> e; K k;
            // 如果hash对应索引位置不为空且已存在节点与当前待添加元素key值相等则对值进行覆盖
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p;
            // 如果当前节点是红黑树节点 则调用putTreeVal方法进行搜索添加
            else if (p instanceof TreeNode)
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            else {
                // 遍历链表节点
                for (int binCount = 0; ; ++binCount) {
                    if ((e = p.next) == null) {
                        // 如果遍历到了链表的最后一个节点则直接将当前待添加元素添加到链表末尾
                        p.next = newNode(hash, key, value, null);
                        // 如果添加后链表长度超过了树化阈值 则对该链表进行树化
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                            treeifyBin(tab, hash);
                        break;
                    }
                    // 如果链表中的某一个节点的key值与当前待添加元素的key值相等则对值进行覆盖
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    // 进行值覆盖
                    e.value = value;
                afterNodeAccess(e);
                return oldValue;
            }
        }
        // 标记hashmap结构修改次数
        ++modCount;
        // 如果当前hashmap的数组长度超过了加载因子规定的阈值将对数组长度进行扩容
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict);
        return null;
    }
```
# 树化
```java
final void treeifyBin(Node<K,V>[] tab, int hash) {
        int n, index; Node<K,V> e;
        // 如果数组长度小于最小树化尺寸则只进行扩容而不进行树化
        if (tab == null || (n = tab.length) < MIN_TREEIFY_CAPACITY)
            resize();
        // 取得当前链表的头节点
        else if ((e = tab[index = (n - 1) & hash]) != null) {
            TreeNode<K,V> hd = null, tl = null;
            // 将每一个链表节点都替换为红黑树节点TreeNode
            do {
                // TreeNode是一个双向链条节点
                TreeNode<K,V> p = replacementTreeNode(e, null);
                if (tl == null)
                    hd = p;
                else {
                    p.prev = tl;
                    tl.next = p;
                }
                tl = p;
            } while ((e = e.next) != null);
            if ((tab[index] = hd) != null)
                // 构建红黑树
                hd.treeify(tab);
        }
    }
```
```java
final void treeify(Node<K,V>[] tab) {
            TreeNode<K,V> root = null;
            for (TreeNode<K,V> x = this, next; x != null; x = next) {
                // 获取双向链表的下一个节点
                next = (TreeNode<K,V>)x.next;
                // 当前节点的左叶与右叶均初始化为空
                x.left = x.right = null;
                // 当为第一个节点的时候 root为null
                if (root == null) {
                    // 根节点是没有父节点的
                    x.parent = null;
                    // 根节点是黑色
                    x.red = false;
                    // 此时获得了红黑树的根节点
                    root = x;
                }
                // 当根节点不为空的时候  也就是进行第二次或者以上次数的循环，非双向链表第一个节点的时候
        // 现在我们假设正在进行第二轮循环
                else {
                    // 第二个节点的key
                    K k = x.key;
                    // 第二个节点的hash
                    int h = x.hash;
                    Class<?> kc = null;
                    // 
                    for (TreeNode<K,V> p = root;;) {
                        int dir, ph;
                        // 根几点的key
                        K pk = p.key;
                        // 根节点的hash
                        // 如果根节点的hash大于当前节点的hash则 dir为-1
                        // 红黑树某个节点的左子叶的所有节点都要小于等于该节点的值，所有的右子叶的值都要大于等于该节点的值
                        // 所以这个dir因该是用来调整当前节点的插入位置 
                        // dir决定了谁前谁后
                        if ((ph = p.hash) > h)
                            dir = -1;
                        else if (ph < h)
                            dir = 1;
                        // 当两者hash相等时
                        // 同一个类型的对象 compareComparables 返回 0 然后调用tieBreakOrder进一步比较
                        // 不同类型的对向直接比较大小返回-1或1
                        else if ((kc == null &&
                                  (kc = comparableClassFor(k)) == null) ||
                                 (dir = compareComparables(kc, k, pk)) == 0)
                            // 类型相同但是k 和 pk 时不同的两个对象他们的 identityHashCode 是不同的
                            dir = tieBreakOrder(k, pk);

                        TreeNode<K,V> xp = p;
                        // 如果dir 小于0 则证明前一节点比当前节点的hash值要大 当前节点就需要挂到前一节点的左叶上
                        if ((p = (dir <= 0) ? p.left : p.right) == null) {
                            x.parent = xp;
                            if (dir <= 0)
                                xp.left = x;
                            // 否则挂到右叶
                            else
                                xp.right = x;
                            // 树的自平衡
                            root = balanceInsertion(root, x);
                            break;
                        }
                    }
                }
            }
            // 将root移动到tab的第一个元素
            moveRootToFront(tab, root);
        }
```
## 平衡红黑树
```java
static <K,V> TreeNode<K,V> balanceInsertion(TreeNode<K,V> root,
                                                    TreeNode<K,V> x) {
            // 假设需要插入的节点是红色
            // 所有新插入节点均为红色
            x.red = true;
            //  xp x parent 
            //  xpp  x parent parent
            // xppl xppr  left right
            for (TreeNode<K,V> xp, xpp, xppl, xppr;;) {
                // 首先我们直到要调用到balanceInsertion 方法  x肯定不是树化的起始节点
                // 那么正常条件下x 的父节点为空的情况是不可能出现的
                // 所以这个判断的意义是什么呢？ 
                //  左旋右旋平衡的时候 会依次向上寻找  如果碰到变色旋转后 父节点为空则证明当前节点时根节点了 将当前节点的颜色变为黑色退出。
                if ((xp = x.parent) == null) {
                    x.red = false;
                    return x;
                }
                // 如果x的父节点不是红色即父节点为黑色 或者父节点的父节点为null 即x是从根节点向下第二层
                // 此时根节点不变 直接返回
                // 只有两层就没有平衡的必要了
                else if (!xp.red || (xpp = xp.parent) == null)
                    // 
                    return root;
                // 当存在三层的时候
                // 如果x的父节点为其祖父节点的左叶
                if (xp == (xppl = xpp.left)) {
                    // 如果祖父节点的右叶不为空  且 右叶的颜色为红色   那么其父节点必定为黑色  父节点的左叶可红可黑
                    // 此时因为上一个else if 的原因 其父节点肯定是红色
                    // 祖父节点是黑色  父节点是红色  叔叔节点是红色 不满足红黑树规则不能出现两个连续的红色 
                    // 所以进行变色  父节点以及叔叔节点变成黑色 祖父节点变成红色
                    if ((xppr = xpp.right) != null && xppr.red) {
                        xppr.red = false; // 右叶设为黑色
                        xp.red = false; // 左叶设为黑色
                        xpp.red = true; // 祖父节点变成红色
                        // 将祖父节点设为 当前节点  继续循环 循环时获取祖父节点的父节点以及祖父节点 重复 
                        // 直到满足退出条件   其一 当前节点的父节点为空
                        x = xpp;
                    }
                    // 祖父节点的右子叶为空
                    else {
                        // 当前节点时父节点的右子叶
                        // 当前节点 红色  父节点红色  祖父节点为黑色
                        //  不满足不能出现两个连续的红色的规则   但是其叔叔节点又为空(黑色)  故不需要变色 直接进行左旋
                        // 这种情况分两步完成 先要进行左旋  左旋完成后  当前节点是变成新的父节点  原本的父节点变成新的父节点的左子叶
                        // 此时仍然存在两个连续的红色节点  但是此时新的做下层子节点变成父节点的左叶了  可以进行右旋了
                        if (x == xp.right) {
                            // 先进行左旋
                            root = rotateLeft(root, x = xp);
                            xpp = (xp = x.parent) == null ? null : xp.parent;
                        }
                        // 如果是当前节点是父节点的坐子叶  直接进行右旋
                        if (xp != null) {
                            xp.red = false; // 父节点变黑
                            if (xpp != null) {
                                xpp.red = true; // 爷爷节点变红
                                // 右旋
                                root = rotateRight(root, xpp);
                            }
                        }
                    }
                }
                // x的父节点为其祖父节点的右叶
                else {
                    // 叔叔节点不为空且为红色
                    // 叔叔节点与父节点均为红色  子节点也为红色  祖父节点为黑色
                    // 先变色  父节点与叔叔变黑   祖父节点变红
                    if (xppl != null && xppl.red) {
                        xppl.red = false; // 叔叔变黑
                        xp.red = false; // 父亲边黑
                        xpp.red = true; // 祖父变红
                        // 开启新一轮的循环
                        x = xpp;
                    }
                    // 叔叔节点不存在
                    else {
                        // 如果当前节点是父节点的左子叶  先进行右旋再左旋
                        if (x == xp.left) {
                            // 右旋
                            root = rotateRight(root, x = xp);
                            xpp = (xp = x.parent) == null ? null : xp.parent;
                        }
                        // 左旋  因为存在连个连续的红色 先进行变色
                        if (xp != null) {
                            xp.red = false; // 父节点变黑
                            if (xpp != null) {
                                xpp.red = true; // 祖父节点变红
                                root = rotateLeft(root, xpp);
                            }
                        }
                    }
                }
            }
        }
```
### 左旋
```java
static <K,V> TreeNode<K,V> rotateLeft(TreeNode<K,V> root,
                                              TreeNode<K,V> p) {
            TreeNode<K,V> r, pp, rl;
            // 以当前节点的父节点为轴进行旋转 即p
            // 将p的右节点取出来 赋值给r
            if (p != null && (r = p.right) != null) {
                // 将r的左节点赋值给p的右节点  p是肯定小于r的子节点的  所以是将r的子节点赋值给p的右节点
                if ((rl = p.right = r.left) != null)
                    // r的左节点指向新的父节点 p
                    rl.parent = p;
                // 因为r的位置会被提升 此时p变成r的子节点所以 p的父节点变成r的父节点
                if ((pp = r.parent = p.parent) == null)
                    // 如果p没有父节点 p本身就是根节点了  p必须为黑色
                    (root = r).red = false;
                // 如果p有父节点  且p是其父节点的坐子叶
                else if (pp.left == p)
                    // 直接设置 pp的左子叶为r
                    pp.left = r;
                else
                    // 如果是右子叶  则设置r为右子叶
                    pp.right = r;
                // 左旋嘛  设置p为r的左子叶
                r.left = p;
                // p的父节点为r
                p.parent = r;
            }
            // 完成
            return root;
        }
```
### 右旋
右旋和左旋差不多
```java
static <K,V> TreeNode<K,V> rotateRight(TreeNode<K,V> root,
                                               TreeNode<K,V> p) {
            TreeNode<K,V> l, pp, lr;
            if (p != null && (l = p.left) != null) {
                if ((lr = p.left = l.right) != null)
                    lr.parent = p;
                if ((pp = l.parent = p.parent) == null)
                    (root = l).red = false;
                else if (pp.right == p)
                    pp.right = l;
                else
                    pp.left = l;
                l.right = p;
                p.parent = l;
            }
            return root;
        }
```
# 扩容
```java
final Node<K,V>[] resize() {
        Node<K,V>[] oldTab = table;
        // 原表为空  new完后就是空的 
        int oldCap = (oldTab == null) ? 0 : oldTab.length;
        int oldThr = threshold;
        // 新表容量以及扩容阈值
        int newCap, newThr = 0;
        // 原表长度大于0
        if (oldCap > 0) {
            // 原表已经是最大值了  不扩容  直接返回
            if (oldCap >= MAXIMUM_CAPACITY) {
                threshold = Integer.MAX_VALUE;
                return oldTab;
            }
            // 原表容量扩大一倍 如果小于最大容量且原表容量大于等于默认容量
            // 新表阈值同比扩大一倍
            else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                     oldCap >= DEFAULT_INITIAL_CAPACITY)
                newThr = oldThr << 1; // double threshold
        }
        // 如果原表容量小于等于0 且原表的阈值大于0
        // 新的容量为原表的阈值
        else if (oldThr > 0) // initial capacity was placed in threshold
            newCap = oldThr;
        // 原表的容量等于0
        else {               // zero initial threshold signifies using defaults
            newCap = DEFAULT_INITIAL_CAPACITY;
            newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
        }
        // 新表阈值等于零 通过公式计算新的阈值
        if (newThr == 0) {
            float ft = (float)newCap * loadFactor;
            newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                      (int)ft : Integer.MAX_VALUE);
        }
        threshold = newThr;
        @SuppressWarnings({"rawtypes","unchecked"})
        Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
        table = newTab;
        if (oldTab != null) {
            // 遍历原表
            for (int j = 0; j < oldCap; ++j) {
                Node<K,V> e;
                if ((e = oldTab[j]) != null) {
                    oldTab[j] = null;
                    // 如果原表的某一个位置只有一个节点 则直接将这个节点重新计算索引放到新表中
                    if (e.next == null)
                        newTab[e.hash & (newCap - 1)] = e;
                    // 如果是红黑树 则进行单独处理
                    else if (e instanceof TreeNode)
                        ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                    else { // preserve order
                        Node<K,V> loHead = null, loTail = null;
                        Node<K,V> hiHead = null, hiTail = null;
                        Node<K,V> next;
                        do {
                            next = e.next;
                            // 区分hash位于新表的高位还是低位
                            // 因为 新表的容量总是原表的2次幂，所以原表某一索引位置的链表中的节点再新表中
                            // 要么位于 原来的位置  要么位于原来的位置加原表的容量 得到的新的位置
                            // 这些结果位于原表同一索引位置
                            if ((e.hash & oldCap) == 0) {
                                if (loTail == null)
                                    loHead = e;
                                else
                                    loTail.next = e;
                                loTail = e;
                            }
                            // 位于原表索引+原表容量的位置
                            else {
                                if (hiTail == null)
                                    hiHead = e;
                                else
                                    hiTail.next = e;
                                hiTail = e;
                            }
                        } while ((e = next) != null);
                        if (loTail != null) {
                            loTail.next = null;
                            newTab[j] = loHead;
                        }
                        if (hiTail != null) {
                            hiTail.next = null;
                            newTab[j + oldCap] = hiHead;
                        }
                    }
                }
            }
        }
        return newTab;
    }
```
# Node与TreeNode
Node对象表示一个链表节点，其包含4个关键成员变量分别为 
```java
final int hash; // key的hash值
final K key; // key
V value; // value
Node<K,V> next; // 下一个节点
```