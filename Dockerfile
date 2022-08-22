FROM ubuntu:18.04
WORKDIR /home
RUN apt update -y --fix-missing && apt install wget -y
RUN wget https://raw.githubusercontent.com/hypnguyen1209/always-run/main/autorun -P /app
COPY install.sh /
RUN chmod a+x /app/autorun
RUN chmod a+x /install.sh
RUN /install.sh
CMD ["/app/autorun"]