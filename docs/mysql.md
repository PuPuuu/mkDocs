<h3 id="BRt4X">基础</h3>
<h4 id="FHkAz">执行流程</h4>
**连接器**校验身份建立连接，**解析器**解析SQL（词法分析-识别关键字、语法分析、构建语法树），执行SQL（预处理阶段-预处理器检查SQL查询语句中的表或字段是否存在，将select * 中的*扩展为表上的所有列、优化阶段-确定SQL查询语句执行方案、执行阶段-执行器执行语句）

+ 执行一条SQL查询语句，期间发生了什么
    - 连接器：建立连接、管理链接、校验身份
    - 解析器：词法分析、语法分析、构建语法树
    - 预处理器：检查表/字段是否存在，将select * 中的*扩展为表上的所有列
    - 优化器：基于查询成本的考虑，选择查询成本最小的执行计划
    - 执行器调用API接口，从存储引擎读取数据，返回客户端
+ 如何查看MySQL服务被多少个客户端连接
    - show processlist;
+ 空连接会一直被占用吗
    - 定义了最大空闲时长，通过wait_timeout参数控制，默认8小时
    - 通过kill connection +id手动断开
+ 最大连接数由<font style="color:rgb(44, 62, 80);">max_connections控制</font>
+ <font style="color:rgb(44, 62, 80);">怎样解决长连接内存占用问题</font>
    - <font style="color:rgb(44, 62, 80);">定期断开长连接</font>
    - <font style="color:rgb(44, 62, 80);">客户端主动重置连接。mysql_reset_connection 函数，客户端调用可以重置连接释放内存，不需要重连和重新做权限验证</font>
+ <font style="color:rgb(44, 62, 80);">全表扫描过程：执行器第一次查询，调用read_first_record函数指针指向的函数（全扫描的接口），读取第一条记录；执行期判断读到的记录是否满足条件，满足则返回，否则跳过（全扫描是一条一条返回，只不过是等所有都返回了才会显示），执行器查询的过程是一个while循环，所以还会查，调用read_record函数指针指向的函数--全扫描接口，继续读下一条记录，存储引擎把记录取出，返回Server层，执行器继续判断条件，重复上面的过程直至查询完毕。</font>
+ <font style="color:rgb(44, 62, 80);">索引下推：</font>执行过程：
    1. <font style="color:rgb(44, 62, 80);">存储引擎使用索引找到可能满足条件的索引记录。</font>
    2. <font style="color:rgb(44, 62, 80);">在存储引擎层（InnoDB / MyISAM 等），先用下推的条件过滤。</font>
    3. <font style="color:rgb(44, 62, 80);">只有通过过滤的行，才会真正回表取数据，再交给 Server 层。</font>
    - <font style="color:rgb(44, 62, 80);">这样能大幅减少回表次数，性能更好。</font>
    - **适用场景**：
        * <font style="color:rgb(44, 62, 80);">查询条件中 </font>**部分列可以通过索引过滤**<font style="color:rgb(44, 62, 80);">，剩余条件需要回表判断。</font>
        * <font style="color:rgb(44, 62, 80);">尤其适用于 </font>**联合索引**<font style="color:rgb(44, 62, 80);">，前缀条件过滤后，其余条件也能在索引中被下推判断。</font>
    - **限制**<font style="color:rgb(44, 62, 80);">：		</font>
        * <font style="color:rgb(44, 62, 80);">仅对二级索引有效（主键索引一般没必要回表）。</font>
        * <font style="color:rgb(44, 62, 80);">并非所有条件都能下推，比如涉及存储引擎不支持的函数/表达式时，仍需回表再判断。</font>
+ <font style="color:rgb(44, 62, 80);">InnoDB的数据按页为单位来读写，默认每个页大小为16KB；在表中数据量大的时候，为某个索引分配空间的时候就不再按照页为单位分配了，而是按照区为单位分配，每个区大小为1MB，对于16KB的页来说，连续的64个页会被划为一个区，这样就使得链表中相邻的页的物理位置也相邻，就能使用顺序I/O了。</font>
+ <font style="color:rgb(44, 62, 80);">InnoDB行格式</font>
    - <font style="color:rgb(44, 62, 80);">Redundant，5.0版本之前用的</font>
    - <font style="color:rgb(44, 62, 80);">Compact，5.0之后默认</font>
    - <font style="color:rgb(44, 62, 80);">Dynamic，5.7之后默认</font>![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756304539517-b1f9a39d-3008-406f-afe5-14bc42806f97.png)
        * 变长字段长度列表信息逆序存放：使得靠前的记录的真实数据和数据对应的长度信息可以同时在一个CPU Cache Line中，提高CPU Cache命中率（指向下一个记录的指针指向的是「记录头信息」和「真实数据」之间的位置）
            + 当数据表没有变长字段的时候，表里的行格式就不会有「变长字段长度列表」
        * NULL值列表的每一位对应一列，为1时表示值为NULL，同样是逆序存放
        * 记录头信息：
            + delete_mask：标识此条记录是否被删除
            + next_record：下一条记录的位置
            + record_type：标识当前记录的类型，0普通记录，1B+树非叶子结点记录，2最小记录，3最大记录
        * trx_id：标识数据由哪个事务生成的，占6字节
        * roll_pointer：<font style="color:rgb(44, 62, 80);">记录上一个版本的指针，占7字节</font>
    - <font style="color:rgb(44, 62, 80);">Compressed</font>
+ <font style="color:rgb(44, 62, 80);">MySQL规定除了TEXT、BLOBs其他所有的列占用的字节长度都不能超过65535字节，要算varchar(n)最大能存储的字节书要看数据库表的字符集，字符集代表着1个字符要占用多少字节</font>
    - <font style="color:rgb(44, 62, 80);">latin1 1字符1字节，只存英文/西欧语言</font>
    - <font style="color:rgb(44, 62, 80);">utf8 1字符最多占3字节，不能存储4字节的Unicode字符（emoji表情、生僻字）</font>
    - <font style="color:rgb(44, 62, 80);">utf8mb4 最多4字节，可以存储emoji、所有Unicode字符</font>
    - <font style="color:rgb(44, 62, 80);">gbk/gb2312 最多2字节，存储中文时比utf8节省空间，只适合中文</font>

> 校对规则：utf8mb4_general_ci（不区分大小写，排序一般）、utf8mb4_unicode_ci（排序更准确但性能稍慢）、utf8mb4_bin（区分大小写，按二进制比较）
>

+ 发生行溢出时，多余的数据会存放到另外的溢出页![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756306899168-4f26f035-e9d6-47b9-ad28-f1722d6c73bc.png)

<h3 id="l0pjQ"><font style="color:rgb(31, 35, 40);">索引</font></h3>
索引是<font style="color:rgb(44, 62, 80);">帮助存储引擎快速获取数据的一种数据结构，</font>就是数据的目录

<h4 id="gYVbc">索引分类</h4>
<h5 id="Lp5jP">按数据结构分类</h5>
B+Tree索引、Hash索引、Full-Text索引

![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1747407536142-807c2520-c472-413c-bfbe-ad2e3caac911.png)

建表时，InnoDB会根据不同场景选择不同的列作为聚簇索引：

1. 有主键，默认使用主键作为聚簇索引的索引键
2. 没有主键，选择第一个不含NULL且唯一的列作为聚簇索引的索引键
3. 都没有的情况下，自动生成自增id列作为聚簇索引的索引键
+ 为什么MySQL InnoDB选择**B+Tree**作为索引的数据结构？
    - B树非叶子节点也要存储数据，B+Tree单节点数据量更小，相同的磁盘I/O次数下，能查询更多节点，且叶子节点使用双链表，适合常见的基于范围的顺序查找
    - 相对二叉树来说分支更多，树的高度更小，磁盘的I/O次数更少
    - Hash适合等值查询，不适合范围查询

<h5 id="mAGSo">按物理存储分类</h5>
分为聚簇索引和二级索引

<h5 id="JwSuW">按字段特性分类</h5>
主键索引、唯一索引、普通索引、前缀索引（对字符类型字段的前几个字符创建的索引，减少索引空间占用，提升查询效率）

<h5 id="H6ANX">按字段个数分类</h5>
单列索引、联合索引（最左匹配原则）

> 联合索引的最左匹配原则会一直向右匹配到范围查询为止，>和>=略有不同，等号成立则会使得下一个联合索引字段也用到索引。如：between and like "x%"
>
> 建立联合索引要把**区分度大**的字段放前面
>
> 在需要排序的场景时，对查询条件和排序条件使用联合索引进行排序可以提高查询效率，避免在文件排序
>

+ 什么时候需要索引
    - 字段有唯一性限制
    - 经常用于where查询条件
    - 经常用于group by和order by
+ 什么时候不需要索引
    - where、group by、order by用不到的字段
    - 字段中存在大量重复数据
    - 表数据太少
    - 经常更新的字段（索引也会随之更新，维护麻烦）
+ 有什么优化索引的方法
    - 前缀索引优化（减少索引字段大小-适合大字符串的字段作为索引时使用）
    - 覆盖索引优化（避免回表）
    - 主键索引最好是递增的（插入时都是追加操作，不会移动数据；否则容易导致页分裂，产生内存碎片）
    - 防止索引失效（查询时左/左右模糊、对索引列做计算、函数、类型转换操作；联合索引没遵循最左匹配；WHERE字句OR前的条件列是索引列OR后的条件列不是索引列）
    - 索引最好设置为NOT NULL（存在NULL时，优化器在做索引选择会更加复杂，NULL值没有意义但是占用空间）

> 主键字段长度越小，二级索引的叶子节点就越小，二级索引占用的空间就越小
>

+ explain参数：
    - possible_keys 可能用到的索引
    - key 实际用到的索引
    - key_len 索引的长度
    - rows 扫描的数据行数
    - type 扫描类型
    - extra
        * Using filesort 当查询语句中包含group by操作且无法利用索引完成排序操作时，不得不选择排序算法进行，可能会通过文件排序
        * Using temporary 使用临时表保存中间结果
        * Using index 使用覆盖索引
+ 数据扫描类型
    - All 全表扫描
    - index 全索引扫描
    - range 索引范围扫描
    - ref 非唯一索引扫描
    - eq_ref 唯一索引扫描
    - const 结果只有一条的主键或唯一索引扫描
+ InnoDB数据页七个部分![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756311939074-552dce94-ea86-4a48-a0b7-e0d1e7e4e6e8.png)
    - 数据页中的记录按照主键顺序组成单向链表（插入删除方便，检索效率不高），数据页中有页目录，起到索引的作用
    - 页目录由多个槽组成，槽相当于分组记录的索引。通过槽查找记录时可以使用二分法快速定位，然后在槽内遍历。
    - InnoDB每个节点都是一个数据页，
+ 单表长度受主键影响，还受行大小影响![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756389263410-d91a37d1-9c2c-4fac-b385-6281e07ec6c0.png)
+ InnoDB和MyISAM都支持B+树，但是他们数据的存储结构实现方式不同，InnoDB的B+树索引的叶子结点存储数据本身，MyISAM存储数据的物理地址
+ 索引失效
    - 左/左右模糊匹配（索引B+树按照索引值有序排列存储，只能根据前缀进行匹配）
    - 对索引使用函数（索引保存的是索引字段原始值，不是经过计算后的值）
    - 对索引进行表达式计算（原因同上）
    - 对索引进行隐式类型转换（MySQL在遇到字符串和数字比较的时候会自动把字符串转为数字然后比较，所以定位int 条件str时可以走索引，相反则不行）
    - 联合索引非最左匹配
    - where子句 or前为索引列 or后非索引列
+ 性能比较：count(*)=count(1)>count(主键)>count(字段)
    - count(1):InnoDB循环遍历聚簇索引，将读到的记录返回server层，不会读取记录中的任何字段
    - count(主键)则会读取字段，判断是否为NULL
    - count(*)相当于count(0)
        * 如何优化count(*)：explain 获取rows的近似值；额外表保存计数值
    - 有二级索引优先使用二级索引，二级索引树更小IO成本更低，有多个二级索引时优先使用key_len最小的二级索引
+ 为什么InnoDB要通过遍历来计数
    - MyISAM有meta信息存储row_count值，而InnoDB存储引擎支持事物，由于MVCC的原因，InnoDB表返回多少行是不确定的
+ mysql分页问题
    - 会随着offset变大越来越慢（先扫描生成offset+size行结果集返回server层，然后丢弃前offset行）
    - 优化：
        * 避免直接使用offset，改为使用子查询走主键索引定位起始位置
        * 覆盖索引+join回表
        * 缓存热点页
+ 深度分页
    - 本质痛点是limit offsize, size需要扫描并丢弃，IO随着offset线性增长
        * 用上次最后一条的排序键为锚点继续查
        * 把上页末行的排序键编码成cursor返回客户端，下次查询带回cursor
        * 固定窗口/时间片分页
        * 业务层限深+缓存

<h3 id="O9CAX">事务</h3>
+ 事务四大特性：原子性（要么全成功要么全失败 redo log）、一致性（结果一致 undo log）、隔离性（多个事务互相隔离 mvcc）、持久性（修改永久有效）
+ 并发事务可能出现的问题：脏读（读到修改未提交的数据）、不可重复度（两次读的同一行数据结果不同）、幻读（相同条件查询结果集数量不同）。
+ 事务隔离级别：读未提交（读最新）、读已提交（每个语句执行前重新生成read view）、可重复度（启动事务时生成read view）、串行化（读写锁）
+ ![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756393863721-53f47ad1-2aab-4ecf-b4c5-c1332a7d6402.png)
+ ![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756394221253-60350831-ff91-484c-88e9-63d35a09247f.png)
+ MySQL可重复度隔离级别很大程度上避免了幻读
    - 针对快照读（普通select）通过MVCC方式解决幻读
    - 针对当前读（select for update）通过next-key lock方式解决幻读
    - 没有避免的例子：![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756395010000-63332a26-06ed-4bb6-a8a1-e84b6c4dd60a.png)

![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756395020164-2ec510f7-3578-475f-97f8-1fe0fbd4fd06.png)

<h3 id="bNBfy">锁</h3>
+ 全局锁：用于全库逻辑备份，容易造成业务停滞（如果数据库的引擎支持的事务支持可重复读的隔离级别，那么在备份数据库之前开启事务，由于MVCC支持，备份期间依然可以对数据进行操作）
+ 表级锁
    - 表锁
    - 元数据锁MDL，不需要显式使用，当我们对数据库表进行操作时，会自动加上MDL（事务提交后释放）
        * CRUD时加MDL读锁
        * 变更表结构加MDL写锁
        * 申请MDL锁的操作会形成一个队列，写锁获取优先级高于读锁
    - 意向锁：不会和行级锁发生冲突，意向锁之间也不会发生冲突，只会和共享表锁、独占表锁发生冲突（快速判断表里是否有记录被加锁）
    - AUTO INC锁：执行完插入语句后立即释放。
        * <font style="color:rgb(44, 62, 80);">innodb_autoinc_lock_mode=0，采用AUTO INC锁，语句执行结束后释放锁</font>
        * <font style="color:rgb(44, 62, 80);">innodb_autoinc_lock_mode=2，采用轻量锁，申请自增主键后就释放锁，不需要等待语句执行后才释放（搭配binlog的日志格式为statement一起使用会在主从复置场景中发生数据不一致的问题，需要设置成row）</font>
        * <font style="color:rgb(44, 62, 80);">innodb_autoinc_lock_mode=1</font>
            + <font style="color:rgb(44, 62, 80);">普通insert语句，申请后马上释放</font>
            + <font style="color:rgb(44, 62, 80);">insert select 批量插入，语句结束后释放</font>
+ <font style="color:rgb(44, 62, 80);">行级锁（select lock in share mode/select for update）</font>
    - <font style="color:rgb(44, 62, 80);">record lock</font>
    - <font style="color:rgb(44, 62, 80);">gap lock 间隙锁之间是兼容的，两个事务可以同时持有包含共同范围的间隙锁，加锁的目的本就是防止插入幻影记录（间隙锁会和插入意向锁冲突，插入意向锁是行级锁）</font>
    - <font style="color:rgb(44, 62, 80);">next-key lock</font>
    - <font style="color:rgb(44, 62, 80);">插入意向锁（特殊的间隙锁）</font>
+ <font style="color:rgb(44, 62, 80);">MySQL怎么加锁（select * from performance_schema.data_locks\G;查看加了什么锁）</font>
    - <font style="color:rgb(44, 62, 80);">唯一索引等值查询：存在-记录锁（主键唯一且存在，不能再插入，对唯一索引加了记录锁所以不能删除这条记录，因此避免了幻读）；不存在-间隙锁（右边界开区间，右边的记录可以被修改）</font>
    - <font style="color:rgb(44, 62, 80);">唯一索引范围查询</font>
        * <font style="color:rgb(44, 62, 80);">大于等于 next-key+记录锁</font>
        * <font style="color:rgb(44, 62, 80);">小于/小于等于</font>
            + <font style="color:rgb(44, 62, 80);">条件值不在表中：next-key+间隙锁</font>
            + <font style="color:rgb(44, 62, 80);">在表中</font>
                - <font style="color:rgb(44, 62, 80);">小于：next-key+间隙锁</font>
                - <font style="color:rgb(44, 62, 80);">小于等于：全是next-key</font>

> 如果锁定读查询语句没走索引，就会全表扫描，每条记录都会加next-key锁，相当于锁全表
>
> sql_safe_updates设置为1时，必须满足以下条件之一才能执行成功：
>
> + 使用where，where条件中必须有索引列
> + 使用limit
> + 同时使用where和limit，where条件可以没有索引列
>
> delete语句必须满足以下条件才能执行成功：
>
> + 同时使用where和limit，where条件可以没有索引列
>

+ insert加锁逻辑
    - 插入前
        * 根据主键和唯一索引检查是否有冲突
        * 定位插入位置时看目标间隙是否被其他事务间隙锁/next-key占着
        * 申请插入意向锁
    - 插入成功后
        * 给插入记录加上行级X锁，事务提交前其他事务不能修改/删除这一行，事务提交后释放锁
+ 如何避免死锁（互斥、占有等待、不可强占、循环等待）
    - 设置事务等待锁的超时时间
    - 开启主动死锁检测 innodb_deadlock_detect

<h3 id="VlKFl">日志</h3>
+ 三种日志
    - undo log 回滚日志 实现原子性，用于事务回滚和MVCC（通过readview和undo log实现）（存储引擎层生成的日志）--记录执行事务前的数据
    - redo log 实现持久性，用于掉电等故障恢复（存储引擎层生成的日志）记录了某个数据页做了什么修改
    - binlog 用于数据备份和主从复制（server层生成的日志）
+ delete操作是将对象打上delete tag标记删除，最终由purge线程完成删除
+ update
    - 如果不是主键列，在undo log中直接反向记录是如何update的
    - 如果是主键列，update分两步执行，先删除再插入
+ WAL技术：写操作并不是立刻写盘而是先写日志，在合适的时间再写盘（随机写变成了顺序写）
+ 内存修改Undo页面也需要记录对应的redo log，因为undo log也要实现持久性的保护
+ 写入redo log的方式是追加操作，是顺序写；写入磁盘是随机写
+ 为什么需要redo log
    - 随机写变顺序写
    - 实现事务的持久性，让MySQL有crash-safe的能力
+ redo log刷盘时机
    - MySQL正常关闭时
    - redo log buffer写入量大于redo log buffer内存空间一半时
    - InnoDB的后台线程每隔一秒刷盘
    - 事务提交（可由innodb_flush_log_at_trx_commit参数控制）
        * innodb_flush_log_at_trx_commit=0:事务提交时只写redo log buffer，不刷盘，不写redo log文件（每隔一秒调用write()写到redo log文件,再使用fsync()刷盘）
        * innodb_flush_log_at_trx_commit=1:每次事务提交都会刷盘，且写入redo log文件
        * innodb_flush_log_at_trx_commit=2:每次事务提交会把redo log只写到redo log文件但不刷盘
+ redo log循环写，write pos追上checkpoint会阻塞，将buffer pool中的脏页刷盘，然后标记redo log哪些可以擦除，接着对旧记录进行擦除，腾出空间，checkout往后移动
+ binlog文件记录了所有数据库表结构变更和表数据修改
+ redo log和binlog区别
    - 适用对象不同
        * binlog时server层实现的日志，所有存储引擎都可以用
        * redo log是InnoDB存储引擎实现的日志
    - 文件格式不同
        * binlog有三种格式：statement（记录执行的语句）、row（记录行数据最终被修改成什么样）、mixed（包含前面两种）
        * redo log是物理日志，记录的是在某个数据页做了什么修改
    - 写入方式不同
        * binlog是追加写，保存的是全量日志
        * redo log是循环写
    - 用途不同
        * binlog用于备份恢复、主从复制
        * redo log用于掉电等事故
+ 主从复制3个阶段
    - 写入binlog：主库写binlog，提交事务，更新本地存储数据
    - 同步binlog：把binlog复制到所有从库，每个从库把binlog写到暂存日志中
    - 回放binlog：回放binlog，更新存储引擎中的数据
+ 主从复制过程
    - 主库收到提交事务的请求后，先写入binlog，再提交事务，更新存储引擎中的数据，事务提交完成后返回给客户端操作成功的响应
    - 从库会创建一个专门的IO线程，连接主库的log dump线程，接收主库的binlog日志，再把binlog写入relay log的中继日志，再返回给主库复制成功的响应
    - 从库会创建一个用于回放binlog的线程去读relay log中继日志，然后回放binlog更新存储引擎中的数据，最终实现主从的数据一致性
+ 从库是不是越多越好
    - 主库数量增加，从库连接上来的IO线程就会增多，主库要创建同样多的log dump线程来处理复制的请求，对主库资源消耗比较高，同时还受限于主库的网络带宽
+ 主从复制模型
    - 同步复制：主库提交事务的线程要等待所有从库的复制成功响应才返回客户端。性能差、可用性差
    - 异步复制（默认）
    - 半同步复制：等待一部分复制成功响应回来就行，兼顾了异步复制和同步复制的优点，及时出现主库宕机，至少还有一个从库有最新的数据，不存在数据丢失的风险
+ ![](https://cdn.nlark.com/yuque/0/2025/png/45083345/1756536745298-5f05752a-ba96-4340-819c-204c12319de3.png)
+ write指的是把日志写入binlog文件，但是没有持久化到磁盘，write写入速度快，不涉及IO
+ fsync把数据持久化到磁盘，涉及IO，通过sync_binlog参数控制刷盘频率
    - sync_binlog=0:每次提交事务都只write不fsync
    - sync_binlog=1:每次事务提交都会write和fsync
    - sync_binlog=N，每次提交事务都write，累计N个事务才fsync
+ update执行流程
1. 执行期调用存储引擎接口，通过索引获取记录
    1. 如果数据页在buffer pool，直接返回给执行器更新
    2. 如果不在buffer pool就从磁盘读入，然后返回给执行器
2. 执行期得到记录后，观察更新前和更新后记录是否一样
    1. 一样的话就不进行更新
    2. 不一样的话就把更新前记录和更新后记录返回给InnoDB
3. 开启事务，InnoDB更新记录前要先记录对应的undo log，undo log写入buffer pool中的undo页面，修改undo页面后，记录对应的redo log
4. InnoDB开始更新记录，先更新内存，然后将记录写到redo log。为了减少磁盘IO，不会立即将脏页写入磁盘，后续由后台线程选择一个合适的时机将脏页写入磁盘（WAL技术）。
5. 在一条更新语句执行完成后开始记录对应的binlog，此时binlog会被保存到binlog cache，在事务提交时才会将binlog刷盘
6. 事务提交，两阶段提交
+ 两阶段提交
    - 如果在redo log刷盘后，MySQL宕机，binlog没来得及写入：MySQl重启后通过redo log能恢复到新值，但是binlog没有记录，在主从架构中，binlog会被复制到从库，所以从库无法更新到新值
    - 如果binlog刷盘后，MySQL宕机，redo log没来得及写入：主库无新值，从库有新值
    - 两阶段提交把事务提交拆分成了2个阶段：准备阶段和提交阶段
        * prepare阶段：将XID（内部事务ID）写入redo log，同时将redo log对应的事务状态设置为prepare，然后将redo log刷盘
        * commit阶段：把XID写入到binlog，然后将binlog刷盘，调用提交事务的接口，将redo log的状态设置为commit
    - binlog中没有XID，说明redo log刷盘但是binlog没有刷盘，回滚事务
    - binlog有事XID说明redo log和binlog都刷盘，提交事务
    - 两阶段提交是以binlog写成功为事务提交成功的标识
    - 两阶段提交问题：
        * 磁盘IO次数高
        * 锁竞争激烈
+ 组提交
    - binlog组提交机制：当有多个事务提交的时候，会将多个binlog刷盘操作合并成一个，从而减少IO的次数
        * 引入组提交后，commit阶段拆分为三个过程（每个阶段都有一个队列，锁的粒度小了，多阶段可以并发执行）
            + flush阶段：多个事务按进入的顺序将binlog从cache写入文件
            + sync阶段：对binlog文件做fsync操作
            + commit阶段：多个事务按照顺序做InnoDB commit操作
+ MySQl磁盘IO高，有什么优化方法
    - 设置组提交参数binlog_group_commit_sync_delay和binlog_group_commit_sync_no_delay_count，延迟刷盘时机
    - sync_binlog设置为大于1的数
    - innodb_flush_log_at_trx_commit设置为2

<h3 id="YNSdx">内存</h3>
+ 如何管理空闲页
    - free链表
+ 如何管理脏页
    - flush链表
+ 如何提高缓存命中率
    - LRU 最近最少使用
        * 预读失败问题
            + 让预读的页停留在buffer pool里的时间尽可能短，真正被访问的页才移动到LRU链表头部--odl+young区域：预读页放入old头部，真正被访问时才插入young头部
        * buffer pool污染
            + 停留在old区域的时间判断
                - 如果后续访问时间与第一次访问的时间在某个时间间隔内，该缓存也不会被放入young头部
                - 否则，放入young头部
+ 脏页刷新时机
    - redo log 满了
    - buffer pool不足，需要将一部分数据页淘汰
    - MySQL认为空闲时，后台线程会定期将适量的脏页刷盘
    - MySQl正常关闭时

