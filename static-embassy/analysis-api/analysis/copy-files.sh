#!/bin/bash

kubectl cp ./tb_tree.txt $2/$1:/config/tb_tree.txt
kubectl cp ./NC_000962.3.fasta $2/$1:/config/NC_000962.3.fasta
kubectl cp ./NC_000962.3.gb $2/$1:/config/NC_000962.3.gb