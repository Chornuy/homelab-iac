storage:
  dbPath: /var/lib/mongodb
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
  logRotate: reopen

net:
  port: 27017
  bindIp: 0.0.0.0
replication:
  replSetName: "${repl_set_name}"
security:
  authorization: "enabled"
  keyFile: /var/lib/mongodb/pve-cluster-keyfile
