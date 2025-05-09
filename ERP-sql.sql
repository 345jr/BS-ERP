/* ————————————————————
 * Enterprise DB - full DDL with detailed comments
 * ———————————————————— */
DROP DATABASE IF EXISTS enterprise_db;
CREATE DATABASE enterprise_db
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE enterprise_db;

/* ————————————————————
 * 1. 部门表
 * ———————————————————— */
CREATE TABLE department (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  name VARCHAR(64) UNIQUE NOT NULL COMMENT '部门名称',
  leader_id BIGINT NULL COMMENT '部门负责人用户 ID',
  intro TEXT COMMENT '部门简介',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门表';

/* ————————————————————
 * 2. 用户表（去掉 create_by / update_by，自带时间戳）
 * ———————————————————— */
CREATE TABLE `user` (
  `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  `user_name` VARCHAR(64) NOT NULL COMMENT '用户名(登录名)',
  `nick_name` VARCHAR(64) NOT NULL COMMENT '昵称(显示名)',
  `password` CHAR(64) NOT NULL COMMENT '密码哈希 (SHA2-256)'，
  `status` CHAR(1) DEFAULT '0' COMMENT '账号状态 0=正常 1=停用'，
  `email` VARCHAR(64) DEFAULT NULL COMMENT '邮箱',
  `phonenumber` VARCHAR(32) DEFAULT NULL COMMENT '手机号',
  `sex` CHAR(1) DEFAULT '2' COMMENT '性别 0=男 1=女 2=未知'，
  `avatar` VARCHAR(128) DEFAULT NULL COMMENT '头像 URL',
  `user_type` CHAR(1) NOT NULL DEFAULT '1' COMMENT '用户类型 0=管理员 1=普通员工'，
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT DEFAULT 0 COMMENT '删除标志 0=未删除 1=已删除',
  UNIQUE KEY uk_user_name (`user_name`),
  INDEX idx_user_status (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

/* ————————————————————
 * 3. 部门–用户 关联表 (多对多 / 历史关系)
 * ———————————————————— */
CREATE TABLE department_user (
  dept_id BIGINT NOT NULL COMMENT '部门 ID',
  user_id BIGINT NOT NULL COMMENT '用户 ID',
  PRIMARY KEY (dept_id, user_id),
  FOREIGN KEY (dept_id) REFERENCES department(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES `user`(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门与用户关联表';

/* 给部门负责人添加外键 */
ALTER TABLE department
  ADD CONSTRAINT fk_dept_leader FOREIGN KEY (leader_id) REFERENCES `user`(id);

/* ————————————————————
 * 4. 公告 & 公告评论
 * ———————————————————— */
CREATE TABLE announcement (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  title   VARCHAR(128) NOT NULL COMMENT '公告标题',
  content TEXT NOT NULL COMMENT '公告内容',
  author_id BIGINT NOT NULL COMMENT '作者用户 ID',
  dept_id BIGINT NULL COMMENT '定向部门 ID，NULL 表示全员',
  view_cnt  INT DEFAULT 0 COMMENT '浏览次数',
  reply_cnt INT DEFAULT 0 COMMENT '评论数量',
  published_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  FOREIGN KEY (author_id) REFERENCES `user`(id),
  FOREIGN KEY (dept_id)   REFERENCES department(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='公告表';

CREATE FULLTEXT INDEX ft_ann_title_content ON announcement(title, content);
CREATE INDEX idx_ann_dept_published ON announcement(dept_id, published_at);

CREATE TABLE announcement_cmt (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  ann_id BIGINT NOT NULL COMMENT '所属公告 ID',
  user_id BIGINT NOT NULL COMMENT '评论者用户 ID',
  parent_id BIGINT NULL COMMENT '父评论 ID，NULL 表示顶级',
  content TEXT NOT NULL COMMENT '评论内容',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '评论时间',
  FOREIGN KEY (ann_id)  REFERENCES announcement(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES `user`(id),
  FOREIGN KEY (parent_id) REFERENCES announcement_cmt(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='公告评论表';

CREATE INDEX idx_cmt_ann ON announcement_cmt(ann_id, created_at);

/* ————————————————————
 * 5. 私信 & 私信评论
 * ———————————————————— */
CREATE TABLE message (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  sender_id   BIGINT NOT NULL COMMENT '发送者用户 ID',
  receiver_id BIGINT NOT NULL COMMENT '接收者用户 ID',
  title   VARCHAR(128) COMMENT '私信标题',
  content TEXT NOT NULL COMMENT '私信内容',
  is_read TINYINT DEFAULT 0 COMMENT '是否已读 0=未读 1=已读',
  reply_cnt INT DEFAULT 0 COMMENT '回复数量',
  sent_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  FOREIGN KEY (sender_id)   REFERENCES `user`(id),
  FOREIGN KEY (receiver_id) REFERENCES `user`(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='私信表';

CREATE INDEX idx_msg_sender_receiver ON message(sender_id, receiver_id, sent_at);

CREATE TABLE message_cmt (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键',
  msg_id   BIGINT NOT NULL COMMENT '所属私信 ID',
  user_id  BIGINT NOT NULL COMMENT '回复者用户 ID',
  parent_id BIGINT NULL COMMENT '父回复 ID',
  content TEXT NOT NULL COMMENT '回复内容',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '回复时间',
  FOREIGN KEY (msg_id)   REFERENCES message(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)  REFERENCES `user`(id),
  FOREIGN KEY (parent_id) REFERENCES message_cmt(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='私信回复表';

/* ————————————————————
 * 6. 模拟数据
 * ———————————————————— */

/* ————————————————————
 * Enterprise DB - Seed Data (INSERT ONLY)
 * ———————————————————— */
USE enterprise_db;

/* ———————————— 部门数据 ———————————— */
INSERT INTO department (name, intro) VALUES
  ('人力资源部',  '负责招聘与培训'),
  ('信息技术部',  '负责企业 IT 基础设施'),
  ('销售部',    '负责销售与客户关系');

/* ———————————— 用户数据 ———————————— */
INSERT INTO `user` (user_name, nick_name, `password`, email, user_type) VALUES
  ('admin', '管理员', SHA2('Admin@123',256), 'admin@example.com', '0'),
  ('alice', 'Alice', SHA2('Alice@123',256), 'alice@example.com', '1'),
  ('bob',   'Bob',   SHA2('Bob@123',256),  'bob@example.com',   '1'),
  ('carol', 'Carol', SHA2('Carol@123',256), 'carol@example.com', '1');

/* ———————————— 部门-用户关联 ———————————— */
INSERT INTO department_user (dept_id, user_id) VALUES
  (1, (SELECT id FROM `user` WHERE user_name = 'alice')),
  (2, (SELECT id FROM `user` WHERE user_name = 'bob')),
  (3, (SELECT id FROM `user` WHERE user_name = 'carol'));

/* ———————————— 设置部门负责人 ———————————— */
UPDATE department SET leader_id = (SELECT id FROM `user` WHERE user_name = 'alice') WHERE id = 1;
UPDATE department SET leader_id = (SELECT id FROM `user` WHERE user_name = 'bob')   WHERE id = 2;
UPDATE department SET leader_id = (SELECT id FROM `user` WHERE user_name = 'carol') WHERE id = 3;

/* ———————————— 公告示例 ———————————— */
INSERT INTO announcement (title, content, author_id, dept_id, published_at) VALUES
  ('五一放假通知',
   '全员：5 月 1 日至 5 月 5 日放假调休，请合理安排工作。',
   (SELECT id FROM `user` WHERE user_name = 'admin'), NULL, '2025-04-20 09:00:00'),
  ('IT 系统维护窗口',
   '信息技术部将于 4 月 30 日 22:00-24:00 进行服务器维护，期间业务将短暂中断。',
   (SELECT id FROM `user` WHERE user_name = 'bob'), 2, '2025-04-25 14:00:00');

/* ———————————— 公告评论示例 ———————————— */
INSERT INTO announcement_cmt (ann_id, user_id, content, created_at) VALUES
  (1, (SELECT id FROM `user` WHERE user_name = 'alice'), '收到~',       '2025-04-20 10:15:00'),
  (1, (SELECT id FROM `user` WHERE user_name = 'bob'),   '假期快乐！', '2025-04-20 10:20:00'),
  (2, (SELECT id FROM `user` WHERE user_name = 'alice'), '维护辛苦了', '2025-04-25 14:30:00');

/* ———————————— 私信示例 ———————————— */
INSERT INTO message (sender_id, receiver_id, title, content, sent_at) VALUES
  ((SELECT id FROM `user` WHERE user_name = 'alice'),
   (SELECT id FROM `user` WHERE user_name = 'bob'),
   '关于报销流程',
   'Bob，你能帮我确认下最新的报销表单吗？谢谢！',
   '2025-04-26 09:00:00'),
  ((SELECT id FROM `user` WHERE user_name = 'bob'),
   (SELECT id FROM `user` WHERE user_name = 'alice'),
   'Re: 关于报销流程',
   '表单已更新到共享盘：/HR/Forms/Reimbursement2025.xlsx',
   '2025-04-26 09:30:00');

/* ———————————— 私信评论示例 ———————————— */
INSERT INTO message_cmt (msg_id, user_id, content, created_at) VALUES
  (1, (SELECT id FROM `user` WHERE user_name = 'bob'),   '好的，我来处理。', '2025-04-26 09:05:00'),
  (2, (SELECT id FROM `user` WHERE user_name = 'alice'), '已收到，感谢！',   '2025-04-26 09:35:00');
