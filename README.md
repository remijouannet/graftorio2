
![](https://mods-data.factorio.com/assets/ad36f974db944b1540ce50a0aea46221f26f7c36.thumb.png)
[![Github All Releases](https://img.shields.io/github/downloads/remijouannet/graftorio2/total.svg)]()

# [graftorio2](https://mods.factorio.com/mod/graftorio2)

**Fork of [graftorio](https://github.com/afex/graftorio)**

[中文文档](./README_cn.md)

visualize metrics from your Factorio game in Grafana

![](https://mods-data.factorio.com/assets/89653f5de75cdb227b5140805d632faf41459eee.png)

## What is this?

[Grafana](https://grafana.com/) is an open-source project for rendering time-series metrics.  
by using [graftorio2](https://mods.factorio.com/mod/graftorio2), you can create a dashboard with various charts monitoring aspects of your Factorio factory.  
this dashboard is viewed using a web browser outside of the game client. (works great in a 2nd monitor!)  

in order to use graftorio2, you need to run the Grafana software and a database called [Prometheus](https://prometheus.io/) locally.  
graftorio2 automates this process using docker, or you can set these up by hand.

## Installation

1. download the latest [release](https://github.com/remijouannet/graftorio2/releases), and extract it into the location you want to host the local database
2. [install docker](https://docs.docker.com/install/)
   - if using windows, you will need to be running Windows 10 Pro
3. if using macOS or Linux, open the extracted `docker-compose.yml` in a text editor and uncomment the correct path to your Factorio install
   - for Linux update the permissions in the data dir (since the containers need those rights):
   - `chown -R 472 config/grafana`
   - `chown -R 65534 config/prometheus`
   - `chown -R 472 data/grafana`
   - `chown -R 65534 data/prometheus`
4. using a terminal, run `docker-compose up` inside the extracted directory
5. load `localhost:3000` in a browser, **you should login once and set a secure password!**
   - there is no need to configure anything:
   - Prometheus is already configured as default datasource
   - but you may want to add the Grafana integrated dashboards to monitor your propmetheus backend or Grafana itself
   - for that you just need to uncomment the nessesary lines from `config/Prometheus/Prometheus.yml`
6. launch factorio
7. install the "graftorio2" mod via the mods menu
8. load up your game, and see your statistics in the Grafana dashboards

## Hosting

whenever you want to publish your dashboard to the public you can do this by placing this upon a server and opening up the ports for your game.  
preferable all runs on the same server, but separating the game and the Grafana dahsboard is possible.  
in the following example we'll explain on how to set it up all on 1 server.  

### Part 1: The Website

when ever you are hosting this on a server it's prefered to run this as the docker instance.  
we placed an [nginx](https://nginx.org/) as reverse proxy in front of it to forward the http(s) requests to the Grafana server.  

```nginx
server {
	listen 80;
	listen [::]:80;
	server_name domain.name;
	return 301 https://domain.name$request_uri;
}

server {
	location / {
		proxy_pass http://127.0.0.1:3000/;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}

    ssl on;
    listen [::]:443 ssl;
    listen 443 ssl;
    # Here we used a letsencrypt cert (stripped out the actual files)
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
```

### Part 2: The Grafana settings

change the `environment:` variable in `docker-compose.yml`.  
for example the domain name and the root URL you're going to use for the public.  
this way dashboards can be made visible to the public.  
for more details consult the [Grafana docker documentation](https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/).  

for example:
```yaml
    environment:
      - GF_SERVER_DOMAIN=domain.name
      - GF_SERVER_ROOT_URL=https://%(domain)s/graftorio
      - GF_SERVER_SERVE_FROM_SUB_PATH=true # the `/graftorio` part of URL
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_AUTH_BASIC_ENABLED=false
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer
      - GF_AUTH_ANONYMOUS_HIDE_VERSION=true
```

### Part 3: The Prometheus settings

like for Grafana you may want to set some custom propperties for your Prometheus backend.
but for Prometheus you need to set them as `command:` inside the `docker-compose.yml`.
for more details consult the [Prometheus docker documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

for example:
```yaml
    command:
      - '--storage.tsdb.retention.time=14d'
```

### Part 4: The exporter

the exporter needs to have access to your game.prom file, so change the path in the `docker-compose.yml` to where `script-output/graftorio` is found.  

**Separate servers**

whenever you want to run the game on a different server you would have to change a few things.

1. the exporter needs to run on the same server/computer as your Factorio server/instance.
2. the Factorio server/instance doesn't need the Prometheus and Grafana dockers. so remove those 2 entries from the `docker-compose.yml`
3. the exporter needs to be accesible from the web, so that the Prometheus db can access it to load in the required data. more information for the exporter is found here https://github.com/Prometheus/node_exporter
4. change over the `data/Prometheus.yml` to let the targets point to your exporters ip:port

However when you want to separate this all, keep in mind that most of the default settings in this readme/repo are not correct.  
so these have to be changed to your needs.

### Finally

open your http://domain.name and see the login for Grafana.
keep in mind that this short guide doesn't explain on how to properly secure everything. this is up to you to fix yourself.

## Debugging

### mod

to see if Factorio is generating stats, confirm a `game.prom` file exists at the configured exporter volume directory.  when opened, it should look something like this:

```
# HELP factorio_item_production_input items produced
# TYPE factorio_item_production_input gauge
factorio_item_production_input{force="player",name="burner-mining-drill"} 3
factorio_item_production_input{force="player",name="iron-chest"} 1
```

### Prometheus

to see if Prometheus is scraping the data, load `localhost:9090/targets` in a browser and confirm that the status is "UP".  
you should the the targets from `config/Prometheus/Prometheus.yml`.  

### Grafana

to see if the Grafana data source can read correctly, there is already a included `graftorio2` dashboard.  
this should show a linear growing `Factorio Tick` panel.  
alternatively start a new dashboard and add a graph with the query `factorio_item_production_input`.  
the graph should render the total of every item produced in your game.  

