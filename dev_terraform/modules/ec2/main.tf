resource "aws_instance" "star_command" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "star_command"
  }
}

resource "aws_instance" "spock_inference" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "c8g.1xlarge"

  tags = {
    Name = "example-spock_inference"
  }
}

resource "aws_instance" "kirk_event_manager" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.small"

  tags = {
    Name = "kirk_event_manager"
  }
}
