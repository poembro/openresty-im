# ************************************************************
# Sequel Pro SQL dump
# Version 4541
#
# http://www.sequelpro.com/
# https://github.com/sequelpro/sequelpro
#
# Host: 127.0.0.1 (MySQL 5.7.25)
# Database: handan
# Generation Time: 2020-03-28 14:59:11 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table mg_group
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mg_group`;

CREATE TABLE `mg_group` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '群组id',
  `group_id` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '群组id',
  `name` varchar(20) COLLATE utf8mb4_bin NOT NULL COMMENT '组名',
  `dateline` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='群组';

LOCK TABLES `mg_group` WRITE;
/*!40000 ALTER TABLE `mg_group` DISABLE KEYS */;

INSERT INTO `mg_group` (`id`, `group_id`, `name`, `dateline`)
VALUES
	(1,222,X'706870E68A80E69CAFE4BAA4E6B581E7BEA4',0);

/*!40000 ALTER TABLE `mg_group` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table mg_group_user
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mg_group_user`;

CREATE TABLE `mg_group_user` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `group_id` bigint(20) unsigned NOT NULL COMMENT '组id',
  `user_id` bigint(20) unsigned NOT NULL COMMENT '用户id',
  `label` varchar(20) COLLATE utf8mb4_bin NOT NULL COMMENT '用户在群组的昵称',
  `dateline` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_user` (`group_id`,`user_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='群组成员关系';

LOCK TABLES `mg_group_user` WRITE;
/*!40000 ALTER TABLE `mg_group_user` DISABLE KEYS */;

INSERT INTO `mg_group_user` (`id`, `group_id`, `user_id`, `label`, `dateline`)
VALUES
	(1,222,663291537152950273,X'',0),
	(2,222,663319127301439489,X'',0);

/*!40000 ALTER TABLE `mg_group_user` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table mg_user
# ------------------------------------------------------------

DROP TABLE IF EXISTS `mg_user`;

CREATE TABLE `mg_user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '用户UID',
  `nickname` varchar(30) NOT NULL DEFAULT '' COMMENT '昵称',
  `mobile` varchar(15) NOT NULL DEFAULT '' COMMENT '手机号码',
  `password` varchar(256) NOT NULL COMMENT '密码',
  `user_id` bigint(11) NOT NULL COMMENT 'user_id',
  `regtime` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '注册时间',
  `regip` varchar(20) NOT NULL DEFAULT '0' COMMENT '注册IP',
  `logintime` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '注册时间',
  `loginip` bigint(20) NOT NULL DEFAULT '0' COMMENT '注册IP',
  `face` varchar(200) NOT NULL DEFAULT '/static/wap/img/portrait.jpg' COMMENT '头像',
  `sex` tinyint(1) NOT NULL DEFAULT '1' COMMENT '性别 1-男 0-女',
  `visible` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态 1-显示 0-删除',
  `remark` varchar(255) NOT NULL DEFAULT '',
  `realname` varchar(30) NOT NULL DEFAULT '' COMMENT '真实姓名',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `mobile` (`mobile`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='用户表';

LOCK TABLES `mg_user` WRITE;
/*!40000 ALTER TABLE `mg_user` DISABLE KEYS */;

INSERT INTO `mg_user` (`id`, `nickname`, `mobile`, `password`, `user_id`, `regtime`, `regip`, `logintime`, `loginip`, `face`, `sex`, `visible`, `remark`, `realname`)
VALUES
	(1,'张三','13260645735','dd22f4e1173abc4cda3f92035b1e5772',663291537152950273,1577261025,'192.168.3.1',0,0,'/static/avatar/1580102496.39.png',1,1,'0','helloddf'),
	(2,'李四','13000000000','0562b321b4f5171e596129921a71cd4f',663319127301439489,1577267603,'192.168.3.1',0,0,'/static/wap/img/portrait.jpg',1,1,'','log的日志服务。'),
	(3,' 老杨','13100000000','c494cdbf59a26569cc9942b9b277a9cb',677038995582369793,1580538675,'192.168.3.1',0,0,'/static/wap/img/portrait.jpg',1,1,'','');

/*!40000 ALTER TABLE `mg_user` ENABLE KEYS */;
UNLOCK TABLES;



/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
