#!/bin/bash

repos="\
	platform/vendor/qcom-opensource/wlan/prima \
	platform/vendor/qcom-opensource/wlan/qcacld-3.0 \
	platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn \
	kernel/msm-5.4 \
	"
function checkout_or_update() {
    repo=$1
    
    if [ -d cve-checker/$repo ]
    then
	cd cve-checker/$repo
	git fetch --all
	cd -
    else
        mkdir -p cve-checker/$repo
	git clone "https://source.codeaurora.org/quic/la/"$repo cve-checker/$repo
    fi
}

function find_cr_in_branches() {
    repo=$1
    asb_file=$2
    asb_out_file=$3
    
    cd cve-checker/$repo

    # cleanup old stuff
    rm -Rf  *
    git checkout -f

    # check branches
    for branch in `git branch -a --sort=-committerdate`; do
	git checkout $branch
	while IFS='' read -r QCFIXID || [ -n "${QCFIXID}" ]; do
	    git log | grep -B 20 "${QCFIXID}" >> $asb_file.out
	done < $asb_out_file
    done
    cd -
}

function download_asb() {
    asb=$1
    asb_file=$2
    curl "https://source.android.com/security/bulletin/${asb}" 2>/dev/null | \
	 grep "QC-CR#"| \
         grep -v href | \
	 awk '{print substr($1,7);}'\
	     > $asb_file
}

asb=$1
asb_file=asb_${asb}_crid.txt
asb_out_file=$asb_file.out

touch $asb_file
asb_file=`realpath ${asb_file}`

download_asb $asb $asb_file

for repo in $repos; do
    checkout_or_update $repo
    find_cr_in_branches $repo $asb_file $asb_out_file
done
