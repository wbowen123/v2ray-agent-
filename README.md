# v2ray-agent

Xray-core/sing-box 一键脚本快速安装

- [复刻并感谢 mack-a 的提供](https://github.com/mack-a/v2ray-agent)
- \[联系 TELE:@wbowen ]

## 功能

- **多核心支持:** 支持 Xray-core 和 sing-box.
- **多协议支持:** 支持 VLESS, VMess, Trojan, Hysteria2, Tuic, NaiveProxy 等多种协议.
- **自动TLS:** 自动申请和续订 SSL 证书.
- **易于管理:** 提供简单的菜单来管理用户、端口和配置.
- **订阅支持:** 生成和管理订阅链接.
- **分流管理:** 提供wireguard、IPv6、Socks5、DNS、VMess(ws)、SNI反向代理，可用于解锁流媒体、规避IP验证等作用.
- **目标域名管理:** 提供域名黑名单管理，可用于禁止访问指定网站.
- **BT下载管理:** 可用于禁止下载P2P相关内容.

## 快速开始

### 脚本安装

```
wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
```

```
curl -L -o /root/install.sh "https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
```

### 卸载脚本

```
wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && printf '20\ny\n' | /root/install.sh
```

```
curl -L -o /root/install.sh "https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && printf '20\ny\n' | /root/install.sh
```

### 使用

安装后，运行以下命令可再次打开管理菜单:

```
va
```

### Docker安装

```
wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/docker_v2ray_agent.sh" && chmod 700 /root/docker_v2ray_agent.sh && /root/docker_v2ray_agent.sh
```

```
curl -L -o /root/docker_v2ray_agent.sh "https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/docker_v2ray_agent.sh" && chmod 700 /root/docker_v2ray_agent.sh && /root/docker_v2ray_agent.sh
```

### 卸载Docker八合一

```
wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/docker_v2ray_agent.sh" && chmod 700 /root/docker_v2ray_agent.sh && printf '20\ny\n' | /root/docker_v2ray_agent.sh
```

```
curl -L -o /root/docker_v2ray_agent.sh "https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/docker_v2ray_agent.sh" && chmod 700 /root/docker_v2ray_agent.sh && printf '20\ny\n' | /root/docker_v2ray_agent.sh
```

### 使用

安装后，运行以下命令可再次打开管理菜单:

```
vad
```

20260530更新

docker_v2ray_agent更新

从工程和代码结构的角度来看，这份代码是完全正确的。它成功地将我们所有推导出的最佳实践都融合到了一起：

✅ 流程骨架： menu() 函数的调用逻辑完美整合了 install.sh 的所有用户引导。
✅ 状态管理： 全局的 PORT_REGISTRY 实现了原子化的端口管理，是脚本稳定性的基石。
✅ 模块化设计： Hysteria2 模块的所有逻辑（端口检查、配置生成、服务应用）都封装在了独立的、可复用的函数中。
⚠️ 最后的“待办”检查点 (TODO List)
代码结构和逻辑上已经达到 100% 目标复刻，但它目前仍然是**“蓝图/伪代码”**，因为它依赖了三个无法通过纯 Bash 脚本完美模拟的外部系统调用。

20260523更新

修改默认范围，并加了重叠校验

- install.sh ：默认改为 Tuic 50000-54999 ，Hysteria2 55000-59999 ，且如果检测到另一协议已有范围且重叠，会直接提示冲突并拒绝设置
  - 入口在 addPortHopping
- docker_v2ray_agent.sh ：默认改为 Tuic 50000:54999 ，Hysteria2 55000:59999 ，并在“添加/修改端口跳跃”时做重叠校验
  - 默认值在 loadState
  - 菜单逻辑在 portHoppingMenu
    
20260515更新

申请证书添加本地搜索导入

<img width="438" height="143" alt="申请证书添加本地搜索导入" src="https://github.com/user-attachments/assets/61f2b1a8-f66a-411e-9e27-7543e199d845" />

配置Hysteria2默认上下行1000M

请输入本地带宽峰值的下行速度（默认：1000，单位：Mbps）
下行速度:

\---> 下行速度: 1000

请输入本地带宽峰值的上行速度（默认：1000，单位：Mbps）
上行速度:

\---> 上行速度: 1000

新增伪装域名检测

<img width="841" height="638" alt="伪装域名检测" src="https://github.com/user-attachments/assets/f4637ebe-0fe6-40a8-bec3-d8dcf5925900" />

节点输出自动生成二维码，并添加检测订阅，如无则自动配置

<img width="1052" height="772" alt="节点输出自动生成二维码，并添加检测订阅，如无则自动配置" src="https://github.com/user-attachments/assets/b3bdc7bc-9ca1-4192-bffc-9b6afc891478" />

订阅输出二维码

<img width="635" height="435" alt="订阅输出二维码" src="https://github.com/user-attachments/assets/6a604264-2807-4137-b8ff-f3a81f1157cb" />

本项根据 [AGPL-3.0 许可证](LICENSE) 授权.
