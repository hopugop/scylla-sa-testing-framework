resource "aws_instance" "scylladb_seed" {
  count           = 1
  ami             = "ami-0d5a0ef6e53048c88" # 2024.1.2 us-east-1 #var.ami_id # Replace with your desired AMI
  instance_type   = var.scylla_instance_type
  key_name        = var.aws_key_pair_name     # Replace with your EC2 key pair name

  subnet_id       = element(aws_subnet.public_subnet.*.id, count.index)  # Assign to a subnet within the VPC
  security_groups = [aws_security_group.sg.id]  # Replace with your VPC security group ID

  tags = {
    Name = "${var.custom_name}-ScyllaDBInstance-${count.index}"
    "Project"   = "${var.custom_name}"
    "Type" =  "Scylla"
  }

  user_data = <<EOF
{
    "scylla_yaml": {
        "cluster_name": "${var.custom_name}",
        },
    "start_scylla_on_first_boot": true
}
EOF
}

resource "aws_instance" "scylladb_nonseeds" {
  count           = var.scylla_node_count - 1
  ami             = "ami-0d5a0ef6e53048c88" # 2024.1.2 us-east-1 #var.ami_id # Replace with your desired AMI
  instance_type   = var.scylla_instance_type
  key_name        = var.aws_key_pair_name     # Replace with your EC2 key pair name

  subnet_id       = element(aws_subnet.public_subnet.*.id, count.index)  # Assign to a subnet within the VPC
  security_groups = [aws_security_group.sg.id]  # Replace with your VPC security group ID

  tags = {
    Name = "${var.custom_name}-ScyllaDBInstance-${count.index}"
    "Project"   = "${var.custom_name}"
    "Type" =  "Scylla"
  }
  user_data = <<EOF
{
    "scylla_yaml": {
        "cluster_name": "${var.custom_name}",
         "seed_provider": [{"class_name": "org.apache.cassandra.locator.SimpleSeedProvider",
                            "parameters": [{"seeds": "${aws_instance.scylladb_seed[0].private_ip}"}]}],
        },
    "start_scylla_on_first_boot": true
}
EOF
  depends_on = [aws_instance.scylladb_seed]
}

output "scylla_ips" {
  value = join(",", [join(",",aws_instance.scylladb_seed.*.private_ip), join(",",aws_instance.scylladb_nonseeds.*.private_ip)])
}

output "scylla_public_ips" {
  value = join(",", [join(",",aws_instance.scylladb_seed.*.public_ip), join(",",aws_instance.scylladb_nonseeds.*.public_ip)])
}