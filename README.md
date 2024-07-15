# Setup neo4j on AWS Instance (EC2)
The terraform script will help the user to setup and configure the `Neo4j CE` on an `t2.large` AWS Instance (EC2)

## Pre-requisites
EC2 shh key

## Created resources
The terraform script will following resources
- VPC (one public one private subnet with IG in one AZ)
- EC2 Security group
- EC2 instance with `Neo4j` installed and running.

## Post configuration

### Network binding
```sh
sudo  /etc/neo4j/neo4j.conf
```

Uncomment `# dbms.default_listen_address=0.0.0.0`

### Credential setup
In your browser reach the Neo4j browser using url `http://<public-dns-of-ec2>:7474/browser/`. Now login using default credentials `neo4j/neo4j`.
This will ask to reset the password. Provide a strong password.

At this point the Neo4j is ready to be consumed.
