#!/bin/sh

# SRT
socat UDP-LISTEN:10000,fork,reuseaddr UDP:host.docker.internal:10000 |
socat UDP-LISTEN:10001,fork,reuseaddr UDP:host.docker.internal:10001 | 
socat UDP-LISTEN:10002,fork,reuseaddr UDP:host.docker.internal:10002 |
socat UDP-LISTEN:10003,fork,reuseaddr UDP:host.docker.internal:10003 | 
socat UDP-LISTEN:10004,fork,reuseaddr UDP:host.docker.internal:10004 | 
socat UDP-LISTEN:10005,fork,reuseaddr UDP:host.docker.internal:10005 |
socat UDP-LISTEN:10006,fork,reuseaddr UDP:host.docker.internal:10006 |
socat TCP-LISTEN:9001,fork,reuseaddr TCP:host.docker.internal:9001
