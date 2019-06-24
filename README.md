# frp


## Usage 
start frps
```
docker run  --network host -d -v /etc/frp/frps.ini:/etc/frp/frps.ini --name frps snowdreamtech/frps
```

start frpc
```
docker run  --network host -d -v /etc/frp/frpc.ini:/etc/frp/frpc.ini --name frpc snowdreamtech/frpc
```
