#!/bin/bash
if [ ! -d ~/.pip ];then
      mkdir ~/.pip
fi
cat>~/.pip/pip.conf<<EOF
[global]
trusted-host = pypi.tuna.tsinghua.edu.cn
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
EOF
