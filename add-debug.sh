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
    gsed  -i "$lineno a \ \ \ \ klog.Infof(\"############## $func\")" $fn;
done

for i in  $all_filenames ; do
    echo $i
    c=$(grep klog $i | wc -l | awk '{print $1}')
    if [ $c -eq 0 ]; then
        continue
    fi
    s="\"k8s.io/klog\""
    grep $s $i > /dev/null 2>&1
    if [ $? -eq 1 ]; then 
        iln=$(grep -n ^package $i | cut -f 1 -d:)
        gsed  -i "$iln a \ " $i
        gsed  -i "$iln a import $s" $i
    fi
done
