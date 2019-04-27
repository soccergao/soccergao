索引:
1.普通索引2.唯一索引3.主键索引4.组合索引5.全文索引
---
事务隔离级别:
Read Uncommitted（读取未提交内容）
Read Committed（读取提交内容）
Repeatable Read（可重读）mysql默认 mvcc优化
Serializable（可串行化） 
---
创建表字段:
ALTER TABLE people ADD COLUMN name VARCHAR(100) DEFAULT NULL COMMENT '姓名'
---
创建索引:
ALTER TABLE table_name ADD INDEX index_name (column_list)
ALTER TABLE table_name ADD UNIQUE (column_list)
ALTER TABLE table_name ADD PRIMARY KEY (column_list)

CREATE INDEX index_name ON table_name (column_list)
CREATE UNIQUE INDEX index_name ON table_name (column_list)
