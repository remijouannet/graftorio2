
![](https://mods-data.factorio.com/assets/ad36f974db944b1540ce50a0aea46221f26f7c36.thumb.png)
[![Github All Releases](https://img.shields.io/github/downloads/remijouannet/graftorio2/total.svg)]()

# [graftorio2](https://mods.factorio.com/mod/graftorio2)

**源自 [graftorio](https://github.com/afex/graftorio)**

[English document](./README.md)

使用 grafana 仪表盘把异星工厂中的数据可视化展示

![](https://mods-data.factorio.com/assets/89653f5de75cdb227b5140805d632faf41459eee.png)

## 这是什么？

[grafana](https://grafana.com/) 是一个可视化监控，也就是仪表盘的开源项目。通过使用 graftorio，我们可以创建一个带有各种图表的仪表盘来监控工厂的生产数据。 不需要进入游戏，使用浏览器即可查看仪表盘。要是有两台显示器的话，一个玩游戏，一个看图表那就非常爽了！

为了使用本项目，我们需要在本地运行上面说的 Grafana 和另一个名为 [prometheus](https://prometheus.io/) 的数据库。 本项目使用了 docker 来自动化此过程，当然也可以手动设置这些过程。

## 安装

1. 下载最新的[版本](https://github.com/remijouannet/graftorio2/release)，并将其解压到要存放本地数据库的位置
2. [安装 docker](https://docs.docker.com/install/)
   - 如果使用 Windows，则至少需要是 Windows 10 专业版
3. 请在编辑器中打开解压出的 `docker-compose.yml`，并将对应的注释（`#`井号）去掉，或者直接输入自己安装的位置
4. 使用控制台或者终端, 在解压的目录运行 `docker-compose up` 命令
5. 在浏览器中打开 `localhost:3000`，不需要登录，prometheus 就已经是默认的数据源了
6. 打开异星工厂
7. 在模组菜单中安装 `graftorio2`
8. 进入游戏，即可在 grafana 中创建、编辑监控数据了

## 调试方法

### 模组

要想知道游戏是否正在生成统计数据，请在已配置的挂载目录中是否存在`game.prom`文件。
如果打开的话，应该是像这个样子：

```
# HELP factorio_item_production_input items produced
# TYPE factorio_item_production_input gauge
factorio_item_production_input{force="player",name="burner-mining-drill"} 3
factorio_item_production_input{force="player",name="iron-chest"} 1
```

### prometheus

要想知道 prometheus 是否正在抓取数据，在浏览器中打开 `localhost:9090/targets` ，确认状态是不是为 "UP"

### grafana

要想知道 grafana 能不能正确读取数据源，创建一个新的 dashboard，使用 `factorio_item_production_input` 这个 query 来添加一个新的图表。 这个图表应该显示游戏中产生的每个物品的总数。