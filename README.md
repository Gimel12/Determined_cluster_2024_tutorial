<aside>
💡 Determined is a software that allow to connect Workstations/servers as a cluster. It has a Master and then agents/workers can join so you can see all your resources in one place and allow you to run Jupyter notebooks with Pytorch or tensorflow in a simple way and will allocate the hardware accross machines automatically using a queue system.

</aside>

---

---

# Configuration for this test:

We will use two machines, one acting as a master and an agent and a second machine as an agent. 

Machine 1 - Master & Agent 

64 cores CPU 

2x A6000 GPUs 

IP - 192.168.1.111 

Machine 2 - Agent

64 cores CPU 

2x A6000 GPUs 

IP - 192.168.1.41 

# Setting up the master

<aside>
💡 We will use docker containers to install determined.

</aside>

## Installing determined CLI

```bash
pip install determined 
pip3 install determined 
```

## Downloading the containers

```jsx
docker pull postgres:10
docker pull determinedai/determined-master:0.32.1
docker pull determinedai/determined-agent:0.32.1 
```

## Start the PostgreSQL container on the master node

`Make sure to change the <DB_PASSWORD> for a real password`

```jsx
docker run \
    --name determined-db \
    -p 5432:5432 \
    -v determined_db:/var/lib/postgresql/data \
    -e POSTGRES_DB=determined \
    -e POSTGRES_PASSWORD=<DB_PASSWORD> \
    postgres:10
```

## Create a determined folder and configuring files

<aside>
💡 On this folder we will include all the configuration files for the master and agent on this machine.

</aside>

```bash
mkdir determined 
cd determined 
sudo vim master.yaml 
```

`Copy paste the code below into the master.yaml`

```bash
db:
  host: 127.0.0.1
  port: 5432
  user: postgres
  password: root
  name: determined
port: 8080
resource_pools:
  - pool_name: A6000_ADA
    max_zero_slot_containers_per_agent: 5
    max_cpu_containers_per_agent: 5
    max_gpu_containers_per_agent: 2
checkpoint_storage:
  type: shared_fs
  host_path: /home/bizon/determined/checkpoints
```

<aside>
💡 You Can change parameters like the **db password**, the **pool name and checkpoint storage**. This file was configured in the testing machine and yours will be similar but need to be configured according to your needs.

</aside>

## Running the DB container and the Master

```bash
# Running the DB container
docker run -d --restart unless-stopped \
    --name determined-db \
    -p 5432:5432 \
    -v determined_db:/var/lib/postgresql/data \
    -e POSTGRES_DB=determined \
    -e POSTGRES_PASSWORD=root \
    postgres:10
    
## Running the Master node 
docker run -d --restart unless-stopped \
    -v "$PWD"/master.yaml:/etc/determined/master.yaml \
    --network host
    determinedai/determined-master:0.32.1
```

## Checking the containers are running:

```bash
# Check the postgress container and the master are running 
sudo docker ps 

# Example 
(base) bizon@dl:~/determined$ sudo docker ps
CONTAINER ID   IMAGE                                   COMMAND                  CREATED      STATUS          PORTS                                       NAMES
9f04f2805059   determinedai/determined-master:0.32.1   "/usr/bin/determined…"   3 days ago   Up 52 minutes                                               sleepy_goldwasser
7092158c8018   postgres:10                             "docker-entrypoint.s…"   3 days ago   Up 52 minutes   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   determined-db

```

`Make sure your determined-master version is the same 0.32.1 or higher` 

## Launching the agent

`In the same folder on determined create an agent.yaml file`

```bash
cd determined 
sudo vim agent.yaml 

# Copy paste the following into the agent.yaml 
master_host: 192.168.1.111 
master_port: 8080
agent_id: agent1
resource_pool: A6000_ADA

# You can change the master_host for your master IP and resource_pool for the name of the pool you created

```

```bash
# Launching the agent 
docker run -d --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD"/agent.yaml:/etc/determined/agent.yaml \
    --gpus all \
    --network host \
    determinedai/determined-agent:0.32.1
```

`Check the agent is online`

```bash
sudo docker ps 

# Example output 
(base) bizon@dl:~/determined$ sudo docker ps
CONTAINER ID   IMAGE                                   COMMAND                  CREATED      STATUS             PORTS                                       NAMES
898cc8f4fd2d   determinedai/determined-agent:0.32.1    "/run/determined/wor…"   3 days ago   Up 59 minutes                                                  compassionate_spence
9f04f2805059   determinedai/determined-master:0.32.1   "/usr/bin/determined…"   3 days ago   Up About an hour                                               sleepy_goldwasser
7092158c8018   postgres:10                             "docker-entrypoint.s…"   3 days ago   Up About an hour   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   determined-db
```

# Checking the setup is working via webUI

<aside>
💡 At this point we should have already in one machine, machine #1 the master running with the configuration files and the database and an agent running and we should be able to login to the webUI and see the GPUs on that machine.

</aside>

## Accessing the webUI

- Navigate to the master node’s IP address and port 8080 in your web browser (e.g., **`http://192.168.1.111:8080`**).
- You should see the Determined UI and both agents listed under the resource pools.

For more details, you can refer to the [Determined AI documentation](https://docs.determined.ai/latest/setup-cluster/on-prem/options/docker.html).

![Screenshot 2024-05-28 at 10.18.40 AM.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/8fcbfa09-4339-4c8b-ae49-c6a16830f99e/282f9da7-c9df-4ce2-b7df-0b6f6dc7e528/Screenshot_2024-05-28_at_10.18.40_AM.png)

<aside>
💡 Default user and password for the webUI - Please login and change the admin password or add more users as you need.

</aside>

```bash
Admin user
username - admin 
password - empty 

Determined user
username - determined 
password - empty
```

`Once login you should see this dashboard`

![Screenshot 2024-05-28 at 10.20.41 AM.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/8fcbfa09-4339-4c8b-ae49-c6a16830f99e/0441d111-148f-4c8a-90b7-ac4610546294/Screenshot_2024-05-28_at_10.20.41_AM.png)

# Adding a second agent - Machine 2

```bash
# Install determined CLI 
pip install determined 
pip3 install determined 
```

## Creating an agent.yaml file

```bash
# Create the determined folder 
mkdir determined 
cd determined 
sudo vim agent.yaml 

# Copy paste the code below 
master_host: 192.168.1.111
master_port: 8080
agent_id: agent2
resource_pool: A6000_ADA
```

## Launching the agent 2

```bash
docker run -d --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD"/agent.yaml:/etc/determined/agent.yaml \
    --gpus all \
    --network host \
    determinedai/determined-agent:0.32.1
```

`Checking the container is running`

```bash
sudo docker ps 

## Example output 
(base) bizon@dl:~/determined$ sudo docker ps
[sudo] password for bizon:
CONTAINER ID   IMAGE                                  COMMAND                  CREATED      STATUS       PORTS     NAMES
ea3063fb8371   determinedai/determined-agent:0.32.1   "/run/determined/wor…"   3 days ago   Up 2 hours             crazy_noether
(base) bizon@dl:~/determined$
```

<aside>
💡 You can check now on the webUI and will see the 2 agents added and you should be able to see all the GPUs, in my case there is 4GPUs in total because 2x per machine.

</aside>

# WebUI and launching the Jupyter notebook

https://www.loom.com/share/b85c4a3858b0435a8ad03e701e548ab9?sid=7f49543a-0ffd-476f-9397-be0f99999a25

#
