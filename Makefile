all: binary

binary:
	pp \
	-o check_netscaler \
	-M LWP \
	-M JSON \
	-M URI::Escape \
	-M MIME::Base64 \
	-M Data::Dumper \
	-M Monitoring::Plugin \
	-M Time::Piece \
	check_netscaler.pl

clean:
	rm check_netscaler || true
