docker run ^
--name mysql ^
-p 3306:3306 ^
-v C:/docker/mysql5.7/conf:/etc/mysql/conf.d ^
-v C:/docker/mysql5.7/my.cnf:/etc/mysql/my.cnf ^
-v C:/docker/mysql5.7/logs:/logs ^
-v C:/docker/mysql5.7/data:/var/lib/mysql ^
-e MYSQL_ROOT_PASSWORD=123456 ^
-d mysql:5.7
