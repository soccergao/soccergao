docker run -p 6379:6379 --name redis -v C:/docker/redis/redis.conf:/etc/redis/redis.conf -v C:/docker/redis/data:/data -d redis redis-server /etc/redis/redis.conf 
