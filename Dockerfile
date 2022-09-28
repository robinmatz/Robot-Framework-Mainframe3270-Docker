# MIT License

# Copyright (c) 2022 Robin Matz

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

###############################################################################
# BUILD STAGE                                                                 #
###############################################################################
FROM python:3.10-slim as build

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN mkdir -p /opt && \
	# Install required packages according to https://x3270.miraheze.org/wiki/Build/Linux
	apt-get update && apt-get install -y \
	wget \
	gcc \
	libssl-dev \
	libreadline-dev \
	libxaw7-dev \
	xfonts-100dpi \
	libncurses5-dev \
	tcl-dev \
	m4 && \
	# Download and extract suite3270
	wget -c http://x3270.bgp.nu/download/04.02/suite3270-4.2ga6-src.tgz -O - | tar -xzf - -C /opt && \
	# Build x3270 and s3270
	cd /opt/suite3270-4.2 && \
	./configure --enable-x3270 --enable-s3270 && \
	make x3270 && make s3270

###############################################################################
# RUNTIME STAGE                                                               #
###############################################################################
FROM python:3.10-slim AS runtime

RUN apt-get update && apt-get install -y xvfb && rm -rf /var/lib/apt/lists/* && \
	python -m pip install robotframework-mainframe3270

COPY --from=build /opt/suite3270-4.2/obj/x86_64-pc-linux-gnu/x3270 \
	/opt/suite3270-4.2/obj/x86_64-pc-linux-gnu/s3270 \
	/opt/

ENV PATH="/opt/x3270:/opt/s3270:$PATH"

ENTRYPOINT [ "xvfb-run" ]
