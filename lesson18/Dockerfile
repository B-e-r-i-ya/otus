FROM  alpine:3.7

#MAINTAINER Khramov Alexandr <Cnbktn@gmail.com>

RUN apk update && apk add nginx && adduser -D -g 'www' www && mkdir /www && chown -R www:www /var/lib/nginx && chown -R www:www /www && chown -R www:www /www
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /www

EXPOSE 80 443
CMD ["nginx"]
#ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]

