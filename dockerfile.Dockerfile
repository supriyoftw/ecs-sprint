FROM amazon/aws-for-fluent-bit:latest
ADD fluent-bit.conf /fluent-bit/etc/
ADD parsers.conf /fluent-bit/etc/
EXPOSE 24224
EXPOSE 80
