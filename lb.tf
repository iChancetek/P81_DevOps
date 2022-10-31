resource "aws_lb_target_group" "test" {
  health_check {
    interval          = 10
    path              = "/"
    protocol          = "HTTP"
    timeout           = 5
    healthy_threshold = 2
  }

  name        = "test"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "vpc-0a5add024768034af"
}

resource "aws_lb" "test" {
  name               = "NatiDevops"
  internal           = false
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
  security_groups    = ["sg-0412bc8848429c0fa"]
  subnets            = ["subnet-02da3240c87eafad5", "subnet-009fbbe5b410b351b"]

  tags = {
    Name = "Nati application"
  }

}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.test.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = "i-01a6356f9af7ebc7a"
}

resource "aws_lb_target_group_attachment" "test1" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = "i-0aa0130efcc15c728"
}