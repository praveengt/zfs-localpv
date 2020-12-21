#!/bin/bash
all_filenames=$(find pkg -name "*.go"  | grep -v -e _test.go -e "/mocks/")
for fn in $all_filenames; do
    grep ^func "$fn" -n | while read -r line; do 
        ln=$(echo $line | cut -f1 -d:);  
        ln=$(($ln + $(tail +$ln $fn | grep -n \{ | head -1 | cut -f 1 -d:) - 1))
        func=$(echo $line | awk '{print $2}' | cut -f1 -d\(); 
        if [ "$func" == "" ]; then  
            func=$(echo $line | awk -F \( '{print $2}' | awk '{print $NF}'); 
        fi; 
        echo $fn $ln $func;
    done
done > /tmp/list.gt

tail -r /tmp/list.gt | while read -r line; do 
    fn=$(echo $line | awk '{print $1}'); 
    lineno=$(echo $line | awk '{print $2}'); 
    func=$(echo $line | awk '{print $3}'); 
    lineno=$(($lineno+1)); 
    c=$(head  -$lineno $fn | tail -1);
    chk=".*klog.Infof"
    if [[ "$c" =~ $chk ]]; then
        gsed -i "${lineno}d" $fn;
    else
        echo "No debug statement @$fn:$lineno $func";
    fi
done

for i in $all_filenames ; do
    s="\"k8s.io/klog\""
    iln=$(grep -n ^"import $s" $i | cut -f 1 -d: | head -1)
    if [ "$iln" == "" ]; then
        continue
    fi
    c=$(head -$iln $i | tail -1);
    chk="^import $s"
    if [[ "$c" =~ $chk ]]; then
        gsed -i "${iln}d" $i;
        gsed -i "${iln}d" $i;
    else
        echo "No import statement $i";
    fi
done

