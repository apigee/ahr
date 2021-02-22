output aws_vpc_id {
  value = data.aws_vpc.aws_vpc.id
}

output aws_private_subnet_1_id {
  value = aws_subnet.aws_private_subnet_1.id
}


output aws_private_subnet_2_id {
  value = aws_subnet.aws_private_subnet_2.id
}

output aws_private_subnet_3_id {
  value = aws_subnet.aws_private_subnet_3.id
}

