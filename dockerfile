FROM amazon/aws-for-fluent-bit:latest

# Add your Fluent Bit configuration files
ADD fluent-bit.conf /fluent-bit/etc/
ADD parsers.conf /fluent-bit/etc/

# Expose ports (optional based on your application's requirements)
EXPOSE 2020
EXPOSE 80

# Define volumes for logs and other data
VOLUME /var/log

# Set the command to run when the container starts
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
