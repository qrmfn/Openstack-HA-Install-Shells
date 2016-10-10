#!/bin/sh

declare -A controller_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" );

controller_name=(${!controller_map[@]});
controller_list_space=${!controller_map[@]};

virtual_ip=192.168.2.201

sh_name=haproxy_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/
source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.base


####scp其他脚本执行操作
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
	name=${controller_name[$i]};
	ip=${controller_map[$name]};
	echo "-------------$name------------"
	ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name
        scp $source_cfg root@$ip:/etc/haproxy/haproxy.cfg
  done;

### [controller01]在pacemaker集群增加haproxy资源
pcs resource create haproxy systemd:haproxy --clone
pcs constraint order start vip then haproxy-clone kind=Optional
pcs constraint colocation add haproxy-clone with vip
ping -c 3 $virtual_ip

