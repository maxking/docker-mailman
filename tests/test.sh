#!/bin/bash
set -e

# Check to see if the core is up.
curl -u restadmin:restpass http://172.19.199.2:8001/3.1/system

# Check to see if postorius is working.
curl -L http://172.19.199.3:8000/postorius/lists | grep "Mailing List"

# Check to see if hyperkitty is working.
curl -L http://172.19.199.3:8000/hyperkitty/ | grep "Available lists"
