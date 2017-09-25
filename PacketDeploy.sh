PROJECT_ID=$TF_VAR_packet_project_id
API_KEY=$TF_VAR_packet_auth_token
SERVER_TYPE=1

for j in `seq 1 7`
do
i=$(printf "%02d" $j)
echo
echo Starting up $i

curl --silent					\
	-X POST					\
	-H "X-Auth-Token: $API_KEY"		\
	-H "Content-Type: application/json"	\
	-d '		
            {
              "hostname": "ams-t'$SERVER_TYPE'-'$i'",
              "plan": "baremetal_'$SERVER_TYPE'",
              "billing_cycle": "hourly",
              "facility": "ams1",
              "operating_system": "centos_7",
              "locked": false,
              "tags": [""],
              "public_ipv4_subnet_size": 29,
              "userdata": "#cloud-config\n---\nruncmd:\n  - [ wget, \"https://raw.githubusercontent.com/OpenStackSanDiego/SecurityServiceChains/master/setup.sh\", -O, /tmp/setup.sh ] \n  - [ chmod, 744, /tmp/setup.sh ] \n  - [ sh, -xc, /tmp/setup.sh ]"
            }
' "https://api.packet.net/projects/$PROJECT_ID/devices"

echo

done

