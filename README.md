# swergio.jl

Julia package for swergio (https://github.com/swergio/swergio) client which enables and simplifies communication between independent ML components via WebSocket.

Full documentation for the swergio project can be found at https://swergio.github.io.

## How to install

The julia package ca be installed from the github repository with:

```
pkg> add https://github.com/swergio/swergio.jl.git 
```

## How to use

To communicate between different clients we need the swergio websocket server, which is available in the python package (https://github.com/swergio/swergio). We therefore need to install the python swergio package and run the server.

We can then add a swergio client to julia code and connect to server.

```
COMPONENT_NAME = "julia"
SERVER = ip"127.0.1.1"
PORT = 8080
HEADER_LENGTH = 10

client = swergio.ClientModule.Client(COMPONENT_NAME,SERVER,PORT; header_length = HEADER_LENGTH)
```

A fill code example for using the julia package can be found in trebuchet example (https://github.com/swergio/Examples).