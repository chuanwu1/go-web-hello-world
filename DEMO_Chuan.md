This is a demo project required by SRE role. 

The candidate should be able to complete the project independently in two days and well document the procedure in a practical and well understanding way.

It is not guaranteed that all tasks can be achieved as expected, in which circumstance, the candidate should trouble shoot the issue, conclude based on findings and document which/why/how.

### Task 0: Install a ubuntu 16.04 server 64-bit

either in a physical machine or a virtual machine

http://releases.ubuntu.com/16.04/<br>
http://releases.ubuntu.com/16.04/ubuntu-16.04.6-server-amd64.iso<br>
https://www.virtualbox.org/

for VM, use NAT network and forward required ports to host machine
- 22->2222 for ssh
- 80->8080 for gitlab
- 8081/8082->8081/8082 for go app
- 31080/31081->31080/31081 for go app in k8s


step:{
    
    1.Use win10 hyper-v to install virtual machine at private laptop.

    2.Download ubuntu 16.04.6 server 64-bit and install it at virtual machine.

    3.Do some basic configuration during ubuntu installation. Such as network configuration with win10 os.

    4.Configure port NAT:
        1) Edit /etc/sysctl.conf, remove "#" which located at the beginning of "net.ipv4.ip_forward=1".
        2) Configure below commands for port NAT:
            sudo iptables -t nat -A PREROUTING -p tcp -i eth0 -d 192.168.31.60 --dport 2222 -j DNAT --to 192.168.31.60:22
            sudo iptables -t nat -A PREROUTING -p tcp -i eth0 -d 192.168.31.60 --dport 8080 -j DNAT --to 192.168.31.60:80

    NOTICE:
        For the vm I use is created by Hyper-V at private laptop, there is no GUI at the default ubuntu server version.
        Based on that, I access it by its IP address 192.168.31.60, instead of its loopback IP address 127.0.0.1.
}


### Task 1: Update system

ssh to guest machine from host machine ($ ssh user@localhost -p 2222) and update the system to the latest

https://help.ubuntu.com/16.04/serverguide/apt.html

upgrade the kernel to the 16.04 latest


step:{
    
    1.Login to host vm from guest vm:
        ssh echuawu@192.168.31.60 -p 2222

    2.Update ubuntu to latest version:
        1) sudo apt-get update
        2) sudo apt-get upgrade
        3) sudo do-release-upgrade
}


### Task 2: install gitlab-ce version in the host
https://about.gitlab.com/install/#ubuntu?version=ce

Expect output: Gitlab is up and running at http://127.0.0.1 (no tls or FQDN required)

Access it from host machine http://127.0.0.1:8080


step:{
    
    1.Install and configure necessary dependencies:
        1) Execute command:
            sudo apt-get install -y curl openssh-server ca-certificates tzdata perl

        2) Install Postfix to send notification emails:
            sudo apt-get install -y postfix
        
        3) Add the GitLab package repository:
            curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

        4) Change URL and install the GitLab package:
            sudo EXTERNAL_URL="http://127.0.0.1" apt-get install gitlab-ce

        5) Restart gitlab process:
            sudo gitlab-ctl restart

    2.Login to Gitlab at private laptop for "http://192.168.31.60:8080".
        Please notice that, "http://127.0.0.1" is not accessable from outside of host vm.
        Instead, using host vm ip address 192.168.31.60 could relay http request to its localhost 127.0.0.1.

    3.Set initial password for root user.
}


### Task 3: create a demo group/project in gitlab

named demo/go-web-hello-world (demo is group name, go-web-hello-world is project name).

Use golang to build a hello world web app (listen to 8081 port) and check-in the code to mainline.

https://golang.org/<br>
https://gowebexamples.com/hello-world/

Expect source code at http://127.0.0.1:8080/demo/go-web-hello-world


step:{
    
    1.Create new project:
        1) Create a group called "demo"
        1) Click "New project" button, then click "Create blank project" button
        2) Configure project name as go-web-hello-world
        3) Add some description
        4) Set Visibility Level as Public
        
        Please notice that the source code would be at http://192.168.31.60:8080/demo/go-web-hello-world

    2.Use golang to build a hello world web app (listen to 8081 port) and check-in the code to mainline.

        1) Install golang at vm:
            sudo apt install golang

        2) Git global setup:
            git config --global user.name "echuawu"
            git config --global user.email "chuan.wu@ericsson.com"

        3) Clone demo/go-web-hello-world code repo:
            git clone http://127.0.0.1/demo/go-web-hello-world.git
            cd go-web-hello-world

        4) Create a hello world source code file, helloWorld.go, and copy source code into it:

                package main

                import (
                    "fmt"
                    "log"
                    "net/http"
                )

                func main(){
                    http.HandleFunc("/", handler)
                    log.Fatal(http.ListenAndServe(":8081", nil))
                }

                func handler(w http.ResponseWriter,r *http.Request){
                    fmt.Fprintf(w, "Go Web Hello World!")
                }


        5) Run source code:
            go run helloWorld.go

        6) Access http://127.0.0.1:8081/ by curl command:
            "Go Web Hello World!"

        7) Push helloWorld.go into code repo:
            git add helloWorld.go
            git commit -m "go-web-hello-world.go"
            git push -u origin master

        8) Check helloWorld.go file be updated at gitlab:
            http://192.168.31.60:8080/demo/go-web-hello-world/-/blob/master/helloWorld.go

}


### Task 4: build the app and expose ($ go run) the service to 8081 port

Expect output: 
```
curl http://127.0.0.1:8081
Go Web Hello World!
```


step:{
    
    1.Build helloWorld.go:
        go build -o helloWorld

    2.Run binary helloWorld:
        ./hellWorld

    3.Access http://127.0.0.1:8081/ by curl command:
        "Go Web Hello World!"

}


### Task 5: install docker
https://docs.docker.com/install/linux/docker-ce/ubuntu/


step:{
    
    1.Remove old version docker:
        sudo apt-get remove docker docker-engine docker.io containerd runc

    2.Install using the repository:

        1) Update the apt package index and install packages to allow apt to use a repository over HTTPS:
            sudo apt-get update

            sudo apt-get install \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg-agent \
                software-properties-common

        2) Add Dockers official GPG key:
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

        3) Use the following command to set up the stable repository:
            sudo add-apt-repository \
               "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
               $(lsb_release -cs) \
               stable"

    3.Install Docker Engine:

        1) Update the apt package index, and install the latest version of Docker Engine and containerd:
            sudo apt-get update
            sudo apt-get install docker-ce docker-ce-cli containerd.io

        2) Verify that Docker Engine is installed correctly by running the hello-world image:

            "sudo docker run hello-world"

                Hello from Docker!
                This message shows that your installation appears to be working correctly.

                To generate this message, Docker took the following steps:
                 1. The Docker client contacted the Docker daemon.
                 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
                    (amd64)
                 3. The Docker daemon created a new container from that image which runs the
                    executable that produces the output you are currently reading.
                 4. The Docker daemon streamed that output to the Docker client, which sent it
                    to your terminal.

                To try something more ambitious, you can run an Ubuntu container with:
                 $ docker run -it ubuntu bash

                Share images, automate workflows, and more with a free Docker ID:
                 https://hub.docker.com/

                For more examples and ideas, visit:
                 https://docs.docker.com/get-started/

}


### Task 6: run the app in container

build a docker image ($ docker build) for the web app and run that in a container ($ docker run), expose the service to 8082 (-p)

https://docs.docker.com/engine/reference/commandline/build/

Check in the Dockerfile into gitlab

Expect output:
```
curl http://127.0.0.1:8082
Go Web Hello World!
```


step:{
    
    1.Execute go build for helloWorld.go:
         go build -o helloWorld

    2.Create a directory called docker, and copy helloWorld.go and its binary file to docker directory:
        mv helloWorld ../docker/
        cp -rf helloWorld.go ../docker/

    3.Create Dockerfile:
        For 8082 is used by default, then try to use 8083 instead.
        cat Dockerfile
            FROM golang
            WORKDIR /
            ADD helloWorld /
            EXPOSE 8083
            ENTRYPOINT ["./helloWorld"]

    4.Build docker image:
        sudo docker build -t helloworld .
        
            Sending build context to Docker daemon  7.651MB
            Step 1/5 : FROM golang
            latest: Pulling from library/golang
            0ecb575e629c: Pull complete
            7467d1831b69: Pull complete
            feab2c490a3c: Pull complete
            f15a0f46f8c3: Pull complete
            1517911a35d7: Pull complete
            7b77ca9fcbe3: Pull complete
            e49d84fb0a44: Pull complete
            Digest: sha256:9fdb74150f8d8b07ee4b65a4f00ca007e5ede5481fa06e9fd33710890a624331
            Status: Downloaded newer image for golang:latest
             ---> 05499cedca62
            Step 2/5 : WORKDIR /
             ---> Running in b6696c89dcd5
            Removing intermediate container b6696c89dcd5
             ---> fbfe843cbbcd
            Step 3/5 : ADD helloWorld /
             ---> bf0cc8d15f9c
            Step 4/5 : EXPOSE 8083
             ---> Running in 204ab2db9abe
            Removing intermediate container 204ab2db9abe
             ---> 8d566dac7b94
            Step 5/5 : ENTRYPOINT ["./helloWorld"]
             ---> Running in 765b1f7530e9
            Removing intermediate container 765b1f7530e9
             ---> 6c8c27f7794e
            Successfully built 6c8c27f7794e
            Successfully tagged helloworld:latest

    5.Run Docker command:
         sudo docker run --rm -it -d -p 8083:8081 helloworld

    6.Check Docker instance status:
        sudo docker ps
            CONTAINER ID   IMAGE        COMMAND          CREATED         STATUS         PORTS     NAMES
            5bdb44aa9a84   helloworld   "./helloWorld"   5 seconds ago   Up 4 seconds             hopeful_hodgkin

    7.Check http connectivity:
        curl http://127.0.0.1:8083
            Go Web Hello World!

    8.Push Dockerfile into gitlab:
        Push Dockerfile into demo/go-web-hello-world repo

}


### Task 7: push image to dockerhub

tag the docker image using your_dockerhub_id/go-web-hello-world:v0.1 and push it to docker hub (https://hub.docker.com/)

Expect output: https://hub.docker.com/repository/docker/your_dockerhub_id/go-web-hello-world


step:{
    
    1.Apply a docker hub account

    2.Create repository go-web-hello-world at docker hub, config it as public one

    3.Login docker account at vm, then add tag to helloworld image:
        sudo docker login
            ---> Dockerhub username
            ---> Dockerhub password

        sudo docker tag helloworld echuawu/go-web-hello-world:v0.1

    4.Push taged docker image to docker hub:
        sudo docker push echuawu/go-web-hello-world:v0.1

            The push refers to repository [docker.io/echuawu/go-web-hello-world]
            8f1453850308: Pushed
            ac4df8406e51: Mounted from library/golang
            e4f90c26294b: Mounted from library/golang
            041459108fb0: Mounted from library/golang
            da654bc8bc80: Mounted from library/golang
            4ef81dc52d99: Mounted from library/golang
            909e93c71745: Mounted from library/golang
            7f03bfe4d6dc: Mounted from library/golang
            v0.1: digest: sha256:ce334835fbe65b4308885cdacd0e2c5c90f4997b9403283cd0fbf28f50bdb18f size: 2006

    5.Pushed result could be verified at webpage:
        https://hub.docker.com/repository/docker/echuawu/go-web-hello-world

}


### Task 8: document the procedure in a MarkDown file

create a README.md file in the gitlab repo and add the technical procedure above (0-7) in this file


step:{
    
    1.Update all the procedures in one md file, called 'DEMO_Chuan.md'

}


-----------------------------------

### Task 9: install a single node Kubernetes cluster using kubeadm
https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/

Check in the admin.conf file into the gitlab repo


step:{
    
    1.Add new source for downloading kubeadm(for my VM could not access google resource):
        sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
        sudo apt-get update && sudo apt-get install -y apt-transport-https curl
        sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
        sudo tee /etc/apt/sources.list.d/kubernetes.list <<-'EOF'
        deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
        EOF
        sudo apt-get update

    2.Install kubelet kubeadm and kubectl:
        sudo apt-get install -y kubelet kubeadm kubectl
        sudo apt-mark hold kubelet kubeadm kubectl

    3.Disable swap:
        sudo swapoff -a

    4.Initialize kubeadm:
        Because of local laptop could not access google resource directly, I use aliyun resources instead here.
            sudo kubeadm init --kubernetes-version=v1.20.2 --image-repository registry.aliyuncs.com/google_containers --apiserver-advertise-address 192.168.31.60

    5.Do some basic configuration:
        mkdir -p $HOME/.kube  
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

    6.Check in the /etc/kubernetes/admin.conf into the gitlab repo

        sudo cat admin.conf

            apiVersion: v1
            clusters:
            - cluster:
                certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1ESXhOakExTkRVMU5Wb1hEVE14TURJeE5EQTFORFUxTlZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTG92CjFvU3BPdWFzYjlZQjhJbCtJRndNOXZuL2hTTkphM3JFMDZzdWkyWmpRVDVUUC9qK1h6QkNKQk9lSjRCWWxycWkKTm1sY0JvQS81dUpETDBmSDg4WkF5VWc3WitFeVYweFpHOXBiQS9HOGpuRVBLYUYyTTFoOWZpQWNSR1hBSHRQTwpvWlVRL0FobW43WEg4c0RuNW05a2lwYlYxZHlXWGZ5dmlqN0tHYWJjeVVLRE0za2d5UWoyeXJya0JlWHNSRzkzCmZhbU93YUNKNldwMkt2WSsxNTFSYW1IUnNsZ1Y2Y01rWmdhUGM5R3VZTWtUSGpBMmYySVBaQkdyRlpxRG5ycWUKeWtXMGthL2REd2RYWnpmRXdYNzV3U2pvdWxpUjI2MUhuSmpXYzRDTW1Ya0c2RFdyVERza0tQWUJqdlhNeUtqcgpwQm9ZaUQrSFlFSjBQSVFjR2ZFQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZJU2QyOXVFb2NhMGFGeG9xaERnZjdmS20xaU1NQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFCSFV0MWY5Nm1mVmVoZUNNNFZ5NFFJaHh2SnY4dmJLUU5ya05GZ3BNb20yTFVUTmluMwpGZ0hYTGEvbDBsSzFHdUpSTjFvNFAvWnZkd0YrRHd3ZEgrK2QzMGFPM3EyaG5RbUhSc0lMODlUVVdEUllyMFdmCkJFTzh4WmxYUm15RWZDdVJudEluWnllZjBmS1MrTWE3V2hyR05Jc1JURTBvRFRCcnNxODdWYlZmdExxazlHdnQKN0RYSzRIdmZ4eG5uZTI0L3czVXB4Y2N6QVh2UmE3QmZseU5iNUJjTWFuRmgyUkx0eWZkMStzNGxDQUNpdjFFcQo0MkZrNXoyUDRud2NDdXRFMmJETElFaytiMDIyL2d0MG8wdkFEOWtpMWhLckgxYUJXcUhYMmR3MlVnK1ovcTRICjdIUmN3akJTR1lPbUd5MmxyT0RVMExKdTBFYmQ1Vkc2SUpMOAotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
                server: https://192.168.31.60:6443
              name: kubernetes
            contexts:
            - context:
                cluster: kubernetes
                user: kubernetes-admin
              name: kubernetes-admin@kubernetes
            current-context: kubernetes-admin@kubernetes
            kind: Config
            preferences: {}
            users:
            - name: kubernetes-admin
              user:
                client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURFekNDQWZ1Z0F3SUJBZ0lJV2V0Ylk5ZFRDdm93RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TVRBeU1UWXdOVFExTlRWYUZ3MHlNakF5TVRZd05UUTFOVFphTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXcxMGdqQ0NXTFFzVjR0MlUKL2lrTjhqWEhxd1kvQkY5M0Q0OEd0cXNSVTFRUHRGbG11d2kwcFZibkdjR1pOMzhpZlFYNE1TcnJRS3h0UTl6VwpIellBNm4wczl0TWUxcmVueUxJdzRMVWNsY3JWUFR3ZmZlZjJ3L0JsSnA0NDZna0ZZLzhOcDFHVmJwblAva2V5CmJ6NUw4UExjVE8vU1BKamhjNE9ycXRQSGo1ZDNkZmpBTUloaXNPVXN0cFZoQ3QxSVBHdVRMM2g5UkNldzFkYjIKL0NhczcydFR0N25qcTNqU0FZUFNPdFNiQVRmclNNdTIvNU1jY0dMT01nMEZSdnVJNW9TZ2lSVmtFNTlvU042dApLZVpsSkxvTzRORWt3SlBXajQ0Z0R1K1ZDbldwcElzQllpZmJGVlZ2aXk1OGxoYk9SVFZ2QUgwWGE0bnZubGdxCldFMVNDd0lEQVFBQm8wZ3dSakFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0h3WURWUjBqQkJnd0ZvQVVoSjNiMjRTaHhyUm9YR2lxRU9CL3Q4cWJXSXd3RFFZSktvWklodmNOQVFFTApCUUFEZ2dFQkFBSlk2NW12anFURmpzQko4dm00dWlYQnpBU3hodnJHSkR5OXVmd0tCbHpZaURXR0tobkl2dE5LCmNDMUJSazlNNG5kNlNlU0U4blA0VWcrNkczcUdCNW8vNWZXMGVHazg2KzUwMFhQQUFRSXc1eDdEcXpEZWhlSFEKZ3FiOFUrVHNYelFKY3d5cUtqMHordmJwQWNlSW45L1BPS0h1TlpReFNVZ2pLM2dEZHY1bEowbERLczNxaDZ5dwo5Q3lFSkZVNlJ1bWoyUkM2aXRlUHBlMVZvN0FUQXphR0Eyc21YSU1xL2RCRHdlSkVxL1RGa3puY29tVlpKb0wyCmEySVJmV3lacGYvWDdybUJQNHhsTWNpSUJSczl5V3kwQnkyeEM0bHAvOGNYc3V1aW04dkFRYnlSc1dUQ0JvUlgKd1BjeFRnQzh6Uk1MVUIwMHZsUGE0UHA1bGcrcVJ0VT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
                client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBdzEwZ2pDQ1dMUXNWNHQyVS9pa044alhIcXdZL0JGOTNENDhHdHFzUlUxUVB0RmxtCnV3aTBwVmJuR2NHWk4zOGlmUVg0TVNyclFLeHRROXpXSHpZQTZuMHM5dE1lMXJlbnlMSXc0TFVjbGNyVlBUd2YKZmVmMncvQmxKcDQ0NmdrRlkvOE5wMUdWYnBuUC9rZXliejVMOFBMY1RPL1NQSmpoYzRPcnF0UEhqNWQzZGZqQQpNSWhpc09Vc3RwVmhDdDFJUEd1VEwzaDlSQ2V3MWRiMi9DYXM3MnRUdDduanEzalNBWVBTT3RTYkFUZnJTTXUyCi81TWNjR0xPTWcwRlJ2dUk1b1NnaVJWa0U1OW9TTjZ0S2VabEpMb080TkVrd0pQV2o0NGdEdStWQ25XcHBJc0IKWWlmYkZWVnZpeTU4bGhiT1JUVnZBSDBYYTRudm5sZ3FXRTFTQ3dJREFRQUJBb0lCQUdkZU92NXByNHdkdFhMWQpNeUZYcjUxY2YwMHFmT1ZmYmF1NXpaK1JYQlZ2QVBBMzdYZEEzL1FyeXhPQnNBUUJMTXBpQWpSaHRSLy9HOEV3CmM4c0gwK3crVnpBeC9MczNhWHR6YlJFNFF1dXU2cXoveHRuamhsbWVOS2IrU0xic0Z3SVZ6YStlSnliaUUzOUQKaUZINzhFcUk5YTl2cFJtUytwY1lNQml1L1lRbmZ6bGNPb01QTzl1bW4xZ1gzVnFMREE0QTk0UUNMakZRL3dUdgpTSFhvTjlJa2FGUklmQy9aQzFVblloQ21lTmp4TStYdlBVL3AyelIrWEtJOFlZRVBKUFdleUM5aW11U0xhR3VJCnRqbzBnUjlpMlc3bVg3SDd0alZQb2NhaDA5aTZicnVNbjEwLzFLaThka1MvMHNuUUo2blpwVllrYlgwTEpGMXkKSmRKN1BLRUNnWUVBOEExQnpxeStNTCtEd3NTbGZvVW1wbFAyQmpISnlqVjJTdFd2ZFpPRzdBc0NyaytvdDJHSQppVWJmNFI1ai85eHUrOXg5K21lVGVjbmpMdGttbElwN2VxZzlUZVFkNThYSDI5N0dWVkVzS1EvSTljVDRFNlBrClUxaFAxVENtUHRXMnF1U2hzeUdxdERBZlNqKzM4aEZaY2J6UllKM0FNdHlraWhMQWtEalZBdTBDZ1lFQTBGZlQKeENHMHc1RHFZajlBOXdjN05JeCtYb0N5WDkrb0p5VTZScysxeFQ3TXk1MG9MSDQ2WWRmaWxQSTFEN3dHYVZ4awpvTjd2MzJDV2xyL2RsVWpURFE1dzZ3RitxTkFWaHFKZk5CQklvc0tjWmdYWlgxMkNhd1hUUUVlWVh5S0oyQnZ1CjVSd0dUcHdWNzJ3VUxhbWFBS1lIb2JjSTBZZVk3b2h4ZzFtcXNkY0NnWUVBNkJpWlNQL0NRQlhiaW9SaFVxdmcKeTY2Z1VDcnhaUDQ5Nm1zaTQzYUpYRTNsQUs1cWZTdmpQSDkzVlF6eU9OOWp1MGJiMHpFejZPd25LUk94OXFyUwphcXloNFY2dS8zbytHN3NRWGt0R2ZFa1R6M1RyT3VvYWgrNzUrVEc1ZTBWZEFXeGZYM2dzdVYxUjA1TTZBZVYrCmFyYmFaaVVBUU8wT2RhVmQ0OVBmT0owQ2dZQXpkdzZUcTNQWXYycDJuSU55d2pHSTJJKzZ6blhCb3lFSmtuT2oKM0ZsZGdSYmIwVldFTUNaQjF5OWNkYnhQeDdXWnZ6NElVeW5UOXlzYjBBZHZnZzdJY2VISTI1U3JKTU84ZjAyZgpNY3FQa2gxS1FuV2d6aHVTVGwwUnl0M0QybWRNb0JIU1BLcitMaVpvL3p5NHp1V0E5WUo3R3hpdGtaNWdoZ25zClZYRUovd0tCZ0Z1WHZmN0ZFNk9ZaDFyR0lkZ0RURzZHMGQ4ZzQzUUpGUUJoeEhKOGsxMkRSNlltcHdqYW9xTDUKKzFuK1d6bTZkRFBJZGdvaDNzM0ZGVDBDWDJiS29DcTl2QVdUQm9kWWEzeHZGUUdoN1lNNm9mUGZ6djNXa0wrVAp0QU1UMkN3c1Yydm9oQ0dMek5RZXZmNTBJTC9FT0N5aVFZQTl6RFRqTDZJTGF2T0dTR1JCCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==

}


### Task 10: deploy the hello world container

in the kubernetes above and expose the service to nodePort 31080

Expect output:
```
curl http://127.0.0.1:31080
Go Web Hello World!
```

Check in the deployment yaml file or the command line into the gitlab repo


step:{
    
    1.Update bb.yaml to gitlab repo
    
}


------------------------------------

### Task 11: install kubernetes dashboard

and expose the service to nodeport 31081

https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

Expect output: https://127.0.0.1:31081 (asking for token)


step:{
    
    1.Deploy dashboard:
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.1.0/aio/deploy/recommended.yaml

        Notice:
            In order to make above command executes successfully, there should be some configurations:
                1) Search the real IP address of "raw.githubusercontent.com", here is 185.199.108.133;
                2) Add IP address and web address to /etc/hosts:
                    185.199.108.133 raw.githubusercontent.com

    2.Check kubernetes dashboard service:
        kubectl get service -n kubernetes-dashboard
            NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
            dashboard-metrics-scraper   ClusterIP   10.108.176.25    <none>        8000/TCP   74m
            kubernetes-dashboard        ClusterIP   10.106.231.250   <none>        443/TCP    74m

    3.Use "kubectl proxy" command to expose port to 31081:
         kubectl proxy --port 31081

    4.Use "curl http://127.0.0.1:31081" to test the access result
}


### Task 12: generate token for dashboard login in task 11

figure out how to generate token to login to the dashboard and publish the procedure to the gitlab.


step:{
    
    1.Create a service account manifest file in which I will define the administrative user for kube-admin:
        vi admin-sa.yml

            apiVersion: v1
            kind: ServiceAccount
            metadata:
              name: kube-admin
              namespace: kube-system

    2.Apply the specific setting:
        sudo kubectl apply -f admin-sa.yml

    3.Bind the cluster-admin role to kube-admin:
        vi admin-rbac.yml

            apiVersion: rbac.authorization.k8s.io/v1
            kind: ClusterRoleBinding
            metadata:
              name: kube-admin
            roleRef:
              apiGroup: rbac.authorization.k8s.io
              kind: ClusterRole
              name: cluster-admin
            subjects:
              - kind: ServiceAccount
                name: kube-admin
                namespace: kube-system

    4.Apply the specific setting again:
        sudo kubectl apply -f admin-rbac.yml

    5.Store the specific name:
        SA_NAME="kube-admin"

    6.Generate a token for the account:
        kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep ${SA_NAME} | awk '{print $1}')
            
            Name:         kube-admin-token-m5psk
            Namespace:    kube-system
            Labels:       <none>
            Annotations:  kubernetes.io/service-account.name: kube-admin
                          kubernetes.io/service-account.uid: 0d832f01-0bef-4f9f-9c81-d96caaa78e6a

            Type:  kubernetes.io/service-account-token

            Data
            ====
            ca.crt:     1066 bytes
            namespace:  11 bytes
            token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IjNfTHV0LUdJUkFRYUExRHpSM014S1pjTzg5NzZBS3MtdXEydnNsZEFxQWcifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJrdWJlLWFkbWluLXRva2VuLW01cHNrIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6Imt1YmUtYWRtaW4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIwZDgzMmYwMS0wYmVmLTRmOWYtOWM4MS1kOTZjYWFhNzhlNmEiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06a3ViZS1hZG1pbiJ9.gcCilL02pxS1vXIFPc1sgfLdXuGOLLQZX4YVqEeox83dcHuXHhn4tRdva97ZQgGh7NQJo-XQIWYcfxM58QcE2MAzEhlkQVaIrff9ZDmgOn0AT83eb1_Zs1IzoHE5KmZSiKtNLQw044COb8tNUhydiz1N6MGHnUGU9rqJ2d3HZE0YyOAx1ZTJo9Q0EJTGdPEg3zI-XYnjNzqZsm4s2OSI8qcypjLsGJTiyPa66k1fLF6BmnKod92vA4ZYdGzqB3oO1qwFXLdapnClegrLqJLi7tmiqcLr98BCKv2c7dTNWnt80L8rKT5Dd7B-tK5LMp94uiW1LqwdRjssRaXk-ed0kg

    7.Keep the token as secure as possible. After creating the token, then finally access the dashboard control panel.  

}


--------------------------------------

### Task 13: publish your work

push all files/procedures in your local gitlab repo to remote github repo (e.g. https://github.com/your_github_id/go-web-hello-world)


step:{
    
    1.Update all the procedures in one md file, called 'DEMO_Chuan.md'

}


if this is for an interview session, please send it to bo.cui@ericsson.com, no later than two calendar days after the interview.
