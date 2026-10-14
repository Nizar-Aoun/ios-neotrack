# Flutter copies this file to build/web/Dockerfile during `flutter build web`.
# EasyPanel builds with context = build/web, so paths are relative to THIS directory.
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html/
RUN rm -f /usr/share/nginx/html/nginx.conf \
         /usr/share/nginx/html/Dockerfile \
         /usr/share/nginx/html/.dockerignore

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
