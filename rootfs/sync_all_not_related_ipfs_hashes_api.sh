#!/bin/bash

# from https://github.com/ravenlandpush/ravencoin-ipfs-bootstrap-tools

finish() {
killall sync_all_not_related_ipfs_hashes_api.sh
}
trap finish EXIT

add-pkg curl ca-certificates wget

curl -L http://bootstrap.ravenland.org/ravencoin_chain_only_$(date +%Y-%m-%d).txt > /tmp/allipfs
# create folder if nt exist, go to folder, remove existing hash if available
mkdir -p /storage/sync;
cd /storage/sync;
while read -r hash; do

#validate hash isnt present already before downloading
is_valid=$(curl -v --silent http://$IPFS_ADDRESS:5001/api/v0/pin/ls?arg=recursive 2>&1 | grep $hash);
echo "checking if $hash already present.."
if [ -z "$is_valid" ]
then
# could use just curl -L and pipe to | ipfs add stdin
wget -c -t 1 -T 60 -q --show-progress --progress=bar:force:noscroll "https://gateway.ravenland.org/ipfs/$hash"
curl -F file=$hash http://$IPFS_ADDRESS:5001/api/v0/add
else
echo "We have this file already pinned. Skipping..."
#deletes file  on disk if already pinned, runs each start so eventually will empty
# could be its own service ('clean ipfs sync dir when pinned found $is_valid')
rm "$hash"
fi

done < /tmp/allipfs